module fifo
#(
    parameter WIDTH_DATA = 32, 
    parameter MEM_SIZE   = 16, // 2**MEM_SIZE слов будет в памяти
    parameter KIND_MEM   = "other" 
)
(
    input logic rst,
    input logic clk_we,
    input logic clk_re,
    
    input logic                     we,
    input logic [WIDTH_DATA-1:0]    wdata,
    output logic full,

    input logic                     re,
    output logic [WIDTH_DATA-1:0]   rdata,
    output logic                    empty 
);
logic we_mem;
logic re_mem;

logic [MEM_SIZE:0] we_point;
logic [MEM_SIZE:0] re_point;
logic [MEM_SIZE:0] we_point_grey;
logic [MEM_SIZE:0] re_point_grey;
logic [MEM_SIZE:0] we_point_grey_tout;
logic [MEM_SIZE:0] re_point_grey_tout;
logic [MEM_SIZE:0] we_point_grey_t1;
logic [MEM_SIZE:0] re_point_grey_t1;
logic [MEM_SIZE:0] we_point_grey_t2;
logic [MEM_SIZE:0] re_point_grey_t2;
logic [MEM_SIZE:0] we_point_decodeGrey;
logic [MEM_SIZE:0] re_point_decodeGrey;

logic [MEM_SIZE:0] we_point_grey_plus_one;
logic [MEM_SIZE:0] re_point_grey_plus_one;

generate 
    if(KIND_MEM=="other")begin 
        mem_fifo #(WIDTH_DATA,MEM_SIZE) ram_with_2clk
            (
                .rst            (rst),
                .clk_we         (clk_we),
                .clk_re         (clk_re),
            
                .we             (we_mem),
                .we_point       (we_point[MEM_SIZE-1:0]),
                .wdata          (wdata),

                .re             (re_mem),
                .re_point       (re_point[MEM_SIZE-1:0]),
                .rdata          (rdata)
            );
    end
    else if(KIND_MEM=="xilinx")begin 

    end
    else if(KIND_MEM=="altera")begin 

    end
endgenerate 

assign we_mem = (~full) ? we : 0;
assign re_mem = (~empty) ? re : 0;

always_ff @(negedge rst,posedge clk_we)
    if(~rst) we_point<=0;
    else if(we && ~full) we_point <=we_point+1;

always_ff @(negedge rst,posedge clk_re)
    if(~rst) re_point <=0;
    else if(re && ~empty) re_point <=re_point+1;

assign we_point_grey = we_point ^ (we_point>>1);
assign we_point_grey_plus_one = (we_point+(we && ~full)) ^ ((we_point+(we && ~full))>>1);
assign re_point_grey = re_point ^ (re_point>>1);
assign re_point_grey_plus_one = (re_point+(re && ~empty)) ^ ((re_point+(re && ~empty))>>1);

always_ff @(negedge rst,posedge clk_we)
    if(~rst) we_point_grey_tout <=0;
    else we_point_grey_tout <= we_point_grey;

always_ff @(negedge rst,posedge clk_re)
    if(~rst) re_point_grey_tout <=0;
    else re_point_grey_tout <= re_point_grey;

always_ff @(negedge rst,posedge clk_re)
    if(~rst) begin 
        we_point_grey_t1 <=0;
        we_point_grey_t2 <=0;
    end
    else begin
        we_point_grey_t1 <= we_point_grey_tout;
        we_point_grey_t2 <= we_point_grey_t1;
    end

always_ff @(negedge rst,posedge clk_we)
    if(~rst) begin 
        re_point_grey_t1 <=0;
        re_point_grey_t2 <=0;
    end
    else begin 
        re_point_grey_t1 <=re_point_grey_tout;
        re_point_grey_t2 <=re_point_grey_t1;
    end

always_ff @(negedge rst,posedge clk_we)
    if(~rst) full <=0;
    else if((we_point_grey_plus_one[MEM_SIZE] != re_point_grey_t2[MEM_SIZE]) &&
            (we_point_grey_plus_one[MEM_SIZE-1] != re_point_grey_t2[MEM_SIZE-1]) &&
            (we_point_grey_plus_one[MEM_SIZE-2:0] == re_point_grey_t2[MEM_SIZE-2:0]))
            full <=1;
    else full <=0;

always_ff @(negedge rst,posedge clk_re)
    if(~rst) empty <=1;
    else if(re_point_grey_plus_one == we_point_grey_t2)
        empty <=1;
    else empty <=0;

endmodule 
