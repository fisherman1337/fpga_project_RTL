module interface_UART
#(
    parameter WIDTH_FIFO_RX     = 8,
    parameter ORDER             = 0 // 1 - first received bit is low, 0  - high 
)
(
    input logic  rst,
    input logic  clk_10MGz,
    
    input  logic rx,
    output logic rts,
    output logic tx,
    input  logic cts, 
    
    input  logic empty,
    input  logic [7:0] rdata,
    output logic re,
    
    input  logic full,
    output logic [WIDTH_FIFO_RX-1:0] wdata,
    output logic we,

    output logic rx_led
);
localparam clk_divider = 521;// it is need for 9600 bod rate

logic uart_order;
logic rx_t1,rx_t2,rx_t3;
logic cts_t1,cts_t2,cts_t3;
logic tx_inside;
logic [31:0] counter_clk_rx;
logic [31:0] counter_clk_tx;
logic clk_rx_div;
logic clk_tx_div;
logic clk_rx;
logic clk_tx;
logic [5:0] counter_bit_rx;
logic [5:0] counter_bit_tx;
logic empty_t1;
logic empty_fall;
logic cts_fall; 
logic we2upsizer;
logic [7:0] data2upsizer;
logic uart_tx_inprogress;
logic uart_rx_inprogress;

logic uart_rx_inprogress_t1;

always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst)
        uart_rx_inprogress_t1 <= 0;
    else 
        uart_rx_inprogress_t1 <= uart_rx_inprogress;

always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst)
        rx_led <= 1;
        
    else if(~uart_rx_inprogress_t1 && uart_rx_inprogress)
        rx_led <= ~rx_led;

assign uart_order = ORDER;

assign rts = full;

//================== tt ==============
always_ff @(negedge rst,posedge  clk_10MGz)
    if(~rst) begin 
        rx_t1 <= 1;
        rx_t2 <= 1;
        rx_t3 <= 1;
    end
    else begin 
        rx_t1 <= rx;
        rx_t2 <= rx_t1;
        rx_t3 <= rx_t2;        
    end


//==================== rx busy ===========
always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst) 
        uart_rx_inprogress <=0;
        
    else if(clk_rx && counter_bit_rx==10)
        uart_rx_inprogress <=0;
    
    else if(~rx_t2 && rx_t3) 
        uart_rx_inprogress <=1;

//==================== clk_divider_rx ===========
always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst) begin 
        counter_clk_rx <= 0;
        clk_rx_div <= 0;
    end
    else if(~uart_rx_inprogress)begin 
        counter_clk_rx <= 0;
        clk_rx_div <= 0;
    end
    else if(counter_clk_rx == clk_divider - 1) begin 
        counter_clk_rx <= 0;
        clk_rx_div <= ~clk_rx_div;
    end
    else  counter_clk_rx <= counter_clk_rx + 1;

assign clk_rx = (~clk_rx_div && counter_clk_rx==clk_divider-1) ? 1 : 0;
//=================== counter_bit_rx ============
always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst)
        counter_bit_rx <= 0;

    else if(clk_rx && counter_bit_rx == 10)
        counter_bit_rx <= 0;

    else if(clk_rx)
        counter_bit_rx <= counter_bit_rx + 1;


//================= data_rx ================
always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst)
        data2upsizer <= 0; 

    else if(clk_rx && uart_order) 
        data2upsizer <= {rx_t3,data2upsizer[7:1]};
    
    else if(clk_rx && ~uart_order) 
        data2upsizer <= {data2upsizer[6:0],rx_t3};


always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst) 
        we2upsizer <= 0;
        
    else if(we2upsizer) 
        we2upsizer <= 0;
        
    else if(clk_rx && counter_bit_rx == 8) 
        we2upsizer <= 1;


//=====================================================
//                    begin: upsizer
//=====================================================        
generate begin: upsizer
localparam bytesINword = ((WIDTH_FIFO_RX % 8) == 0) ? 
                                  WIDTH_FIFO_RX / 8 : (WIDTH_FIFO_RX / 8) + 1;
                                
localparam remainder   = WIDTH_FIFO_RX % 8;


    
    if(WIDTH_FIFO_RX == 8)begin 
                
        assign wdata = data2upsizer;
        assign we = we2upsizer;
    
    end
    else begin
        logic [(bytesINword-1)*8 - 1:0]  part_wdata;
        logic [$clog2(bytesINword)+1:0]  counter_byte;

        always_ff @(negedge rst,posedge clk_10MGz)
            if(~rst) 
                counter_byte <= 0;
        
            else if(we2upsizer && counter_byte == bytesINword - 1)
                counter_byte <= 0;
            
            else if(we2upsizer)
                counter_byte <= counter_byte + 1;
            
        always_ff @(negedge rst,posedge clk_10MGz)
            if(~rst) 
                part_wdata <= 0;
                
            else if(we2upsizer)
                part_wdata <= {part_wdata[(bytesINword-1)*8 - 9:0],data2upsizer};
                
        if(remainder == 0)begin
        
            assign wdata = {part_wdata, data2upsizer};
            
        end
        else begin 
        
            assign wdata = {part_wdata, data2upsizer[remainder-1:0]};
            
        end
            
        assign we = (we2upsizer && counter_byte == bytesINword-1) ? 1 : 0;   
    end
            

end                  
endgenerate 
//=====================================================
//                    end: upsizer
//=====================================================    

        
//================= empty && cts ===============
always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst) 
        empty_t1 <= 1;
    else     
        empty_t1 <= empty;

always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst) begin
        cts_t1 <= 1;
        cts_t2 <= 1;
        cts_t3 <= 1;
    end
    else begin
        cts_t1 <= cts;
        cts_t2 <= cts_t1;
        cts_t3 <= cts_t2; 
    end

assign empty_fall = (~empty  && empty_t1) ? 1 : 0;
assign cts_fall   = (~cts_t2 &&   cts_t3) ? 1 : 0;
 
//================ clk_divider_tx ==========
always_ff @(negedge rst,posedge  clk_10MGz)
    if(~rst)
        uart_tx_inprogress <= 0;
        
    else if(clk_tx && ~cts_t2 && ~empty && counter_bit_tx == 9)
        uart_tx_inprogress <= 1;
        
    else if(clk_tx && (cts_t2 || empty) && counter_bit_tx == 9)
        uart_tx_inprogress <= 0;
     
    else if((empty_fall || cts_fall) && ~uart_tx_inprogress && ~empty && ~cts_t2)
        uart_tx_inprogress <= 1;
        
        
always_ff @(negedge rst,posedge clk_10MGz)
    if(~rst) begin 
        counter_clk_tx <= 0;
        clk_tx_div <= 0;
    end
    else if(~uart_tx_inprogress)begin 
        counter_clk_tx <= 0;
        clk_tx_div <= 0;
    end
    else if(counter_clk_tx == clk_divider-1) begin 
        counter_clk_tx <= 0;
        clk_tx_div <= ~clk_tx_div;
    end
    else  counter_clk_tx <= counter_clk_tx +1;

assign clk_tx = (~clk_tx_div && counter_clk_tx==clk_divider-1) ? 1:0;
//=============== counter_bit_tx ==============
always_ff @(negedge rst,posedge  clk_10MGz)
    if(~rst) 
        counter_bit_tx <= 0;

    else if(clk_tx && counter_bit_tx==10)
        counter_bit_tx <= 0;

    else if(clk_tx)begin 
        counter_bit_tx <= counter_bit_tx + 1;
    end


always_ff @(negedge rst,posedge  clk_10MGz)
    if(~rst)
        re <= 0;
        
    else if(re)
        re <= 0;
    
    else if(clk_tx && ~cts_t2 && ~empty && counter_bit_tx == 9)
        re <= 1;
     
    else if((empty_fall || cts_fall) && ~uart_tx_inprogress && ~empty && ~cts_t2)
        re <= 1;
        
//=============== tx =============
always_comb
    case(counter_bit_tx)
        0:  tx_inside = 1;
        1:  tx_inside = 0;
        10: tx_inside = 1;
        default: begin 
                    if(uart_order)  
                        tx_inside = rdata[counter_bit_tx - 2];
                    else 
                        tx_inside = rdata[8 - 1 - counter_bit_tx + 2];
                 end
    endcase
    
always_ff @(negedge rst,posedge  clk_10MGz)
    if(~rst)
        tx <= 1;
    else
        tx <= tx_inside;

endmodule 




