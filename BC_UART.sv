module BC_UART
#(
    parameter AMOUNT_CLASS                          = 2,
    parameter WIDTH_FIFO_RX                         = 8,
    parameter MEMSIZE_FIFO_RX                       = 8,
    parameter KIND_MEM                              = "other",
    parameter string  INIT_MEM_CAL[AMOUNT_CLASS-1:0]= '{
                                                        "../init_mem/data_log_W_0.dat",
                                                        "../init_mem/data_log_W_1.dat"
                                                        },  
    parameter WIDTH_LOG_W                           = 32,
    parameter WIDTH_LOG_D                           = 32,
    parameter WIDTH_LOG_V                           = 32,
    parameter ORDER_UART                            = 1
)
(
    input  logic rst,
//    input  logic clk_10MGz,
    input  logic clk, 
    
    input  logic rx,
    output logic rts,
    output logic tx,
    
    output logic rx_led
//    input  logic cts
     
);
logic cts;
assign cts = 0;

// fifoRX
logic                            we_fifoRX;
logic [WIDTH_FIFO_RX-1:0]        wdata_fifoRX;
logic                            full_fifoRX;

// fifoTX
logic                            re_fifoTX;
logic [7:0]                      rdata_fifoTX;
logic                            empty_fifoTX;

logic clk_10MGz;
logic clk_2;


PLL PLL_1
    (
        .inclk0                 (clk),
        .c0                     (clk_10MGz),
        .c1                     (clk_2)
    );
 
interface_UART
    #(
        .WIDTH_FIFO_RX          (WIDTH_FIFO_RX),
        .ORDER                  (ORDER_UART)
    )
interface_UART_1
    (
        .rst                    (rst),
        .clk_10MGz              (clk_10MGz),
        
        .rx                     (rx),
        .rts                    (rts),
        .tx                     (tx),
        .cts                    (cts),
        
        .empty                  (empty_fifoTX),
        .rdata                  (rdata_fifoTX),
        .re                     (re_fifoTX),
        
        .full                   (full_fifoRX),
        .wdata                  (wdata_fifoRX),
        .we                     (we_fifoRX),
        .rx_led                 (rx_led)
    );


Bayes_class
    #(
        .AMOUNT_CLASS           (AMOUNT_CLASS),
        .WIDTH_FIFO_RX          (WIDTH_FIFO_RX), 
        .MEMSIZE_FIFO_RX        (MEMSIZE_FIFO_RX),  // 2**MEMSIZE_FIFO_RX слов в fifo_rx
        .KIND_MEM               (KIND_MEM),
        .INIT_MEM_CAL           (INIT_MEM_CAL),
        .WIDTH_LOG_W            (WIDTH_LOG_W),
        .WIDTH_LOG_D            (WIDTH_LOG_D),
        .WIDTH_LOG_V            (WIDTH_LOG_V)
    )
Bayes_class_1
    (
        .rst                    (rst),
        .clk_1                  (clk_10MGz),
        .clk_2                  (clk_2),
        
        .we_fifoRX              (we_fifoRX),
        .wdata_fifoRX           (wdata_fifoRX),
        .full_fifoRX            (full_fifoRX),
        
        .re_fifoTX              (re_fifoTX),
        .rdata_fifoTX           (rdata_fifoTX),
        .empty_fifoTX           (empty_fifoTX)
    );    




endmodule     
