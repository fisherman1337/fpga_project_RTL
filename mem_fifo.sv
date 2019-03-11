module mem_fifo
#(
    parameter WD = 32,
    parameter mem_size = 16
)
(
    input logic rst,
    input logic clk_we,
    input logic clk_re,

    input logic we,
    input logic [mem_size-1:0] we_point,
    input logic [WD-1:0] wdata,
    
    input logic re,
    input logic [mem_size-1:0] re_point,
    output logic [WD-1:0] rdata
);
logic [WD-1:0] ram[2**mem_size-1:0];


always_ff @(negedge rst,posedge clk_we)
    if(~rst) 
        for(int i=0; i<2**mem_size;i++)begin
            ram[i]<=0;
        end
    else if(we) ram[we_point][WD-1:0] <=wdata[WD-1:0];

always_ff @(negedge rst,posedge clk_re)
    if(~rst) rdata <=0;
    else if(re) rdata <=ram[re_point];

endmodule 
