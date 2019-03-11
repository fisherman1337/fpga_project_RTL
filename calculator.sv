module calculator 
#(
    parameter AMOUNT_CLASS      = 4,
    parameter INIT_MEM_FILE     = " ",
    parameter NUMBER            = 0,
    parameter WIDTH_FIFO_RX     = 8,
    parameter KIND_MEM          = "other", 
    parameter WIDTH_LOG_W       = 16,
    parameter WIDTH_LOG_D       = 16,
    parameter WIDTH_LOG_V       = 16,
    parameter WIDTH_LOG_N       = 16 // пока будет равно WIDTH_FIFO_RX
)
(
    input logic rst,
    input logic clk,
    
    //из контроллера
    input logic                             finish, 
    input logic                             enable,
    input logic [WIDTH_LOG_N-1:0]           amount_word,
    input logic [WIDTH_LOG_D-1:0]           log_D,
    input logic [WIDTH_LOG_V-1:0]           log_V,
 
    //из fifo
    input logic [WIDTH_FIFO_RX-1:0]         data_in,

    output logic [127:0]                    data_out, // сколько битов нужно ?
    output logic [$clog2(AMOUNT_CLASS):0]   number
);
localparam WIDTH_NMULLOGV = (WIDTH_LOG_N > WIDTH_LOG_V) ? 2*WIDTH_LOG_N : 2*WIDTH_LOG_V;

logic finish_t1;
logic finish_fall;

logic re_memRO;
logic re_memRO_t1;
logic [WIDTH_FIFO_RX-1:0] addr_memRO;
logic [WIDTH_LOG_W-1:0] data_memRO;

logic [WIDTH_NMULLOGV-1:0] nMULlogV;
logic [127:0] sum_log_W;  //  сколько битов нужно ?

assign number = NUMBER;

always_ff @(negedge rst,posedge clk)
    if(~rst)
        finish_t1 <= 0;
    else 
        finish_t1 <= finish;

assign finish_fall = (~finish && finish_t1) ? 1 : 0;

generate 
    if(KIND_MEM == "other")begin 
        memRO 
            #(
                .INIT_MEM_FILE      (INIT_MEM_FILE),
                .WIDTH_DATA         (WIDTH_LOG_W),
                .WIDTH_ADDR         (WIDTH_FIFO_RX)
            ) 
        ramRO 
            (
                .clk                (clk),
                
                .re                 (re_memRO),
                .addr               (addr_memRO),
                .data               (data_memRO)
            );
    end
    else if(KIND_MEM == "xilinx")begin 

    end
    else if(KIND_MEM == "altera")begin 

    end
endgenerate 

assign addr_memRO = data_in;
assign re_memRO = enable;

always_ff @(negedge rst,posedge clk)
    if(~rst) 
        re_memRO_t1 <= 0;

    else 
        re_memRO_t1 <= re_memRO;    

always_ff @(negedge rst,posedge clk)
    if(~rst)
        sum_log_W <= 0;
    
    else if(re_memRO_t1)
        sum_log_W <= sum_log_W + data_memRO;
    
    else if(finish_fall)
        sum_log_W <= 0; 

assign nMULlogV = log_V * amount_word;
assign data_out = nMULlogV - log_D - sum_log_W;

endmodule 
