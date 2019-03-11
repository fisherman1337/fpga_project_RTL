module Bayes_class
#(
    parameter AMOUNT_CLASS                          = 4,
    parameter WIDTH_FIFO_RX                         = 8,
    parameter MEMSIZE_FIFO_RX                       = 8, 
    parameter KIND_MEM                              = "other",
    parameter string INIT_MEM_CAL [AMOUNT_CLASS-1:0] = '{
                                                        "../test/data_log_W_0.dat",
                                                        "../test/data_log_W_1.dat"
                                                        },            
    parameter WIDTH_LOG_W                           = 16,
    parameter WIDTH_LOG_D                           = 16,
    parameter WIDTH_LOG_V                           = 16
)                                                      
(
    input  logic rst,
    input  logic clk_1,
    input  logic clk_2,

    // fifoRX
    input  logic                            we_fifoRX,
    input  logic [WIDTH_FIFO_RX-1:0]        wdata_fifoRX,
    output logic                            full_fifoRX,

    // fifoTX
    input  logic                            re_fifoTX,
    output logic [7:0]                      rdata_fifoTX,
    output logic                            empty_fifoTX 
       
);
localparam WIDTH_LOG_N = WIDTH_FIFO_RX;//in future, maybe change 

logic re_fifoRX;
logic [WIDTH_FIFO_RX-1:0] rdata_fifoRX;
logic empty_fifoRX;

logic we_fifoTX;
logic full_fifoTX;
logic [7:0] wdata_fifoTX;

logic  enable;
logic  [WIDTH_LOG_N-1:0] amount_word;
logic  [WIDTH_LOG_D-1:0] log_D [AMOUNT_CLASS-1:0];
logic  [WIDTH_LOG_V-1:0] log_V [AMOUNT_CLASS-1:0];
logic  [$clog2(AMOUNT_CLASS):0] number [AMOUNT_CLASS-1:0];

logic [127:0] calcul_out[AMOUNT_CLASS-1:0]; // how many bits are needed ?

logic [$clog2(AMOUNT_CLASS):0]   class_win;
logic finish;     

fifo
    #(
        .WIDTH_DATA                 (WIDTH_FIFO_RX),
        .MEM_SIZE                   (MEMSIZE_FIFO_RX),
        .KIND_MEM                   (KIND_MEM)
    )
fifoRX_bayes                                                                             
    (
        .rst                        (rst),
        .clk_we                     (clk_1),
        .clk_re                     (clk_2),

        .we                         (we_fifoRX),
        .wdata                      (wdata_fifoRX),
        .full                       (full_fifoRX),
    
        .re                         (re_fifoRX),
        .rdata                      (rdata_fifoRX),
        .empty                      (empty_fifoRX)
    );

fifo
    #(
        .WIDTH_DATA                 (8),// note: convention is that -> 
        .MEM_SIZE                   (4),//  -> TX fifo`s width equally 8 bit
        .KIND_MEM                   (KIND_MEM)
    )
fifoTX_bayes
    (
        .rst                        (rst),
        .clk_we                     (clk_2),
        .clk_re                     (clk_1),

        .we                         (we_fifoTX),///connect
        .wdata                      (wdata_fifoTX),///
        .full                       (full_fifoTX),//
    
        .re                         (re_fifoTX),
        .rdata                      (rdata_fifoTX),
        .empty                      (empty_fifoTX)
    );

controller 
    #(
        .AMOUNT_CLASS               (AMOUNT_CLASS),
        .WIDTH_FIFO_RX              (WIDTH_FIFO_RX),
        .WIDTH_LOG_D                (WIDTH_LOG_D),
        .WIDTH_LOG_V                (WIDTH_LOG_V),
        .WIDTH_LOG_N                (WIDTH_LOG_N)
    )
controller_bayes
    (
        .rst                        (rst),
        .clk                        (clk_2),
        
        .empty                      (empty_fifoRX),
        .re                         (re_fifoRX),
        .data_in                    (rdata_fifoRX),
        
        .full                       (full_fifoTX),
        .we                         (we_fifoTX),
        .data_out                   (wdata_fifoTX),
        
        .enable                     (enable),
        .amount_word                (amount_word),
        .log_D                      (log_D),
        .log_V                      (log_V),
        
        .class_win                  (class_win),
        .finish                     (finish)
    );


generate
genvar i;

             
    for(i = 0; i < AMOUNT_CLASS; i++)begin:create_calcul
       
        calculator
            #(
                .AMOUNT_CLASS               (AMOUNT_CLASS),
                .INIT_MEM_FILE              (INIT_MEM_CAL[i]),
                .NUMBER                     (i),//core number 
                .WIDTH_FIFO_RX              (WIDTH_FIFO_RX),
                .KIND_MEM                   (KIND_MEM),
                .WIDTH_LOG_W                (WIDTH_LOG_W),
                .WIDTH_LOG_D                (WIDTH_LOG_D),
                .WIDTH_LOG_V                (WIDTH_LOG_V),
                .WIDTH_LOG_N                (WIDTH_LOG_N)        
            )
        calculator_bayes
            (
                .rst                        (rst),
                .clk                        (clk_2),
            
                .finish                     (finish),
                .enable                     (enable),
                .amount_word                (amount_word),
                .log_D                      (log_D[i]),
                .log_V                      (log_V[i]),
    
                .data_in                    (rdata_fifoRX),
            
                .data_out                   (calcul_out[i]),
                .number                     (number[i])
            );
    end
    
    
endgenerate

tree_comparator
    #(
        .WIDTH_DATA         (128),
        .AMOUNT_CLASS       (AMOUNT_CLASS)
    )
tree_comparator_bayes
    (
        .data               (calcul_out),
        .number             (number),
        
        .class_win          (class_win)
    );

endmodule
