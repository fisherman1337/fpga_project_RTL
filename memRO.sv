module memRO
#(
    parameter INIT_MEM_FILE     = " ",
    parameter WIDTH_DATA        = 32,
    parameter WIDTH_ADDR        = 16 // 2**mem_size слов в памяти
)
(
    input logic clk,

    input logic re,
    input logic [WIDTH_ADDR-1:0] addr,
    output logic [WIDTH_DATA-1:0] data

);
logic [WIDTH_DATA-1:0] ram[2**WIDTH_ADDR-1:0];

initial begin 
    $readmemh(INIT_MEM_FILE,ram);                                            
end


always_ff @(posedge clk)
    if(re) 
        data <= ram[addr];
    
    else 
        data <= 0;

endmodule 
