module controller
#(
    parameter AMOUNT_CLASS        = 4,
    parameter WIDTH_FIFO_RX       = 8, 
    parameter WIDTH_LOG_W         = 16,
    parameter WIDTH_LOG_D         = 16,
    parameter WIDTH_LOG_V         = 16,
    parameter WIDTH_LOG_N         = 16 // пока будет равно WIDTH_FIFO_RX
)
(
    input logic rst,
    input logic clk,

    // rx_fifo
    input  logic                      empty,
    output logic                      re,
    input  logic [WIDTH_FIFO_RX-1:0]  data_in,
    // tx_fifo
    input  logic                      full,
    output logic                      we,
    output logic  [7:0]               data_out,                   
    
    output logic                     enable,
    output logic  [WIDTH_LOG_N-1:0]  amount_word,
    output logic  [WIDTH_LOG_D-1:0]  log_D [AMOUNT_CLASS-1:0],
    output logic  [WIDTH_LOG_V-1:0]  log_V [AMOUNT_CLASS-1:0],

    input  logic [$clog2(AMOUNT_CLASS):0]   class_win,
    output logic                            finish 
);
localparam bitINclass_win = $clog2(AMOUNT_CLASS) + 1;
localparam bytesINword = 
                (bitINclass_win % 8 == 0) ? 
                    bitINclass_win / 8 : (bitINclass_win / 8) + 1;
                    
logic [1:0] count_param; //кол-во параметров, если что поправить разрядность. 
logic re_t1;
                    
logic [$clog2(bytesINword)+1:0] counter_we;
logic [7:0] data_buf[bytesINword-1:0];
logic [bytesINword*8-1:0] expansion_class_win;



initial begin 
    $readmemh("../init_mem/data_log_D.dat",log_D);
    $readmemh("../init_mem/data_log_V.dat",log_V);
end

always_ff @(negedge rst,posedge clk)
    if(~rst)
        re_t1 <= 0;
    else  
        re_t1 <= re;
        
typedef enum logic [2:0] {  wait_start_S,
                            read_param_S,
                            inprogress_S,
                            write_data_S,
                            end_S       ,       
                            ping_S      } statetype;
statetype state,nextstate;

always_ff @(negedge rst,posedge clk)
    if(~rst)
        state <= wait_start_S;

    else 
        state <= nextstate;

always_comb
    case(state)
        wait_start_S:       
                        if(&data_in) 
                            nextstate = read_param_S;
                        
                        else if( &data_in[WIDTH_FIFO_RX-1:2]  && 
                                 ~data_in[1]                  &&
                                  data_in[0]                  &&              
                                  re_t1                       )
                        
                            nextstate = ping_S; 
                        
                        else  
                            nextstate = wait_start_S;
        read_param_S:
                        if(count_param == 1)
                            nextstate = inprogress_S;
                        else 
                            nextstate = read_param_S;
        inprogress_S:
                        if(re_t1 && &data_in[WIDTH_FIFO_RX-1:1] && ~data_in[0])
                            nextstate = write_data_S;
                        else 
                            nextstate = inprogress_S;
        write_data_S:
                        if(we && counter_we == bytesINword + 2 - 1)
                            nextstate = end_S;
                        else 
                            nextstate = write_data_S;         
        end_S        :
                        if(&data_in)
                            nextstate = read_param_S;
                            
                        else if( &data_in[WIDTH_FIFO_RX-1:2]  && 
                                 ~data_in[1]                  &&
                                  data_in[0]                  &&              
                                  re_t1                       )
                        
                            nextstate = ping_S; 
                        
                        else 
                            nextstate = end_S;
        ping_S      :
                        if(~full)
                            nextstate = wait_start_S;
                        else 
                            nextstate = ping_S;
        default        :     
                        nextstate = wait_start_S;
    endcase

always_ff @(negedge rst,posedge clk)
    if(~rst)
        count_param <= 0;

    else if(state == read_param_S && re)
        count_param <= count_param + 1;

    else 
        count_param <= 0;                                                                
        
always_ff @(negedge rst,posedge clk)
    if(~rst)
        amount_word <= 0;
    
    else if(state == read_param_S && count_param == 1)
        amount_word <= data_in;
    

always_comb
    case(state)
        inprogress_S:
                        if(re_t1 && ~(&data_in[WIDTH_FIFO_RX-1:1] && ~data_in[0]))
                            enable = 1;
                        else 
                            enable = 0;
        default       :
                        enable = 0;
    endcase

always_comb
    case(state)
        wait_start_S:
                        if( &data_in[WIDTH_FIFO_RX-1:2]  && 
                            ~data_in[1]                  &&
                             data_in[0]                  &&              
                             re_t1                       )
                            
                            re = 0;
                            
                        else if(~empty && ~(&data_in))
                            re = 1;
                        else 
                            re = 0;
        read_param_S:
                        if(~empty && count_param < 1)
                            re = 1;
                        else
                            re = 0;
        inprogress_S:    
                        if(~empty && ~(&data_in[WIDTH_FIFO_RX-1:1] && ~data_in[0]))
                            re = 1;
                        else
                            re = 0;
        end_S       :  
                        if( &data_in[WIDTH_FIFO_RX-1:2]  && 
                            ~data_in[1]                  &&
                             data_in[0]                  &&              
                             re_t1                       )
                            
                            re = 0;
                            
                        else if(~empty && ~(&data_in))
                            re = 1;
                        else 
                            re = 0;
        default     :   
                        re = 0;
    endcase

assign finish = (state == end_S) ? 1 : 0;


//=====================================================
//                    begin: downsizer
//=====================================================


                    
always_ff @(negedge rst,posedge clk)
    if(~rst)
        counter_we <= 0;
    
    else if(state == write_data_S && we && counter_we == bytesINword + 2 - 1)
        counter_we <= 0;
            
    else if(state == write_data_S && we)
        counter_we <= counter_we + 1;

     
always_comb
    if(state == ping_S && ~full) 
        we = 1;
        
    else if(state == write_data_S && ~full)
        we = 1;
        
    else 
        we = 0;
        
generate

    if(bitINclass_win % 8 == 0)
        assign expansion_class_win = class_win;
    else 
        assign expansion_class_win[bitINclass_win-1:0] = class_win;
        assign expansion_class_win[bytesINword*8-1:bitINclass_win] = 0;
         
    genvar i; 
    for(i = 0; i < bytesINword; i++)begin :create_buf 
        always_ff @(negedge rst,posedge clk)
            if(~rst)
                data_buf[i] <= 0;
            
            else if(state == inprogress_S       && 
                    re_t1                       && 
                    &data_in[WIDTH_FIFO_RX-1:1] && 
                    ~data_in[0])
                    
                data_buf[i] <= expansion_class_win[bytesINword*8 - 1 - i*8 :
                                                   bytesINword*8 - 8 - i*8];
    end
             
endgenerate

   
always_comb
    if(state == ping_S)
        data_out = 8'b01010111;
        
    else if(counter_we == 0)
        data_out = ~0;
        
    else if(counter_we == bytesINword + 2 - 1)begin
        data_out[0] = 1'b0;
        data_out[7:1] = ~0;
    end
    else if(counter_we > 0)
        data_out = data_buf[counter_we - 1]; 
    else 
        data_out = 0;
//=====================================================
//                    end: downsizer
//===================================================== 
 
endmodule
