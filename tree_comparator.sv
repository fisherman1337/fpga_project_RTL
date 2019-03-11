module tree_comparator
#(
    parameter WIDTH_DATA       = 8,
    parameter AMOUNT_CLASS     = 5
)
(
    input logic [WIDTH_DATA-1:0]            data[AMOUNT_CLASS-1:0],
    input logic [$clog2(AMOUNT_CLASS):0]    number [AMOUNT_CLASS-1:0],

    output logic [$clog2(AMOUNT_CLASS):0]   class_win
);

comparator
        #(
            .AMOUNT_CLASS               (AMOUNT_CLASS),
            .WIDTH_DATA                 (WIDTH_DATA),
            .LVL_TREE                   (AMOUNT_CLASS)// самый высокий 
        )                                              // уровень равен AMOUNT_CLASS
        
comparator_root
        (
            .data                       (data),
            .number                     (number),
            
            .more                       (),
            .class_win                  (class_win)
        );



endmodule 

module comparator
#(
    parameter AMOUNT_CLASS      = 8,
    parameter WIDTH_DATA        = 8,
    parameter LVL_TREE          = 5// постпено убывает 
)
(
    input logic [WIDTH_DATA-1:0]            data[LVL_TREE-1:0],
    input logic [$clog2(AMOUNT_CLASS):0]    number[LVL_TREE-1:0],
    
    output logic [WIDTH_DATA-1:0]           more,
    output logic [$clog2(AMOUNT_CLASS):0]   class_win   
);
localparam LVL_NEXT_LEFT = LVL_TREE / 2;
localparam LVL_NEXT_RIGHT = ((LVL_TREE % 2) == 0) ? (LVL_TREE / 2) : 
                                                            ((LVL_TREE / 2) + 1); 

generate
    if(LVL_TREE == 1)begin
        
        assign more = data[0];
        assign class_win = number[0][$clog2(AMOUNT_CLASS):0];
        
    end

    else if(LVL_TREE == 2) begin 
    
        assign more = (data[0] < data[1]) ? data[0] : data[1];
        
        assign class_win = (data[0] < data[1]) ? number[0] : number[1];

    end

    else if(LVL_TREE >= 3)begin

        logic [WIDTH_DATA - 1:0] more_left, more_right;
        logic [$clog2(AMOUNT_CLASS):0] class_win_left, class_win_right;
        
        logic [WIDTH_DATA - 1:0] data_left[LVL_NEXT_LEFT - 1:0];
        logic [WIDTH_DATA - 1:0] data_right[LVL_NEXT_RIGHT - 1:0];
        
        logic [$clog2(AMOUNT_CLASS):0] number_left[LVL_NEXT_LEFT - 1:0];
        logic [$clog2(AMOUNT_CLASS):0] number_right[LVL_NEXT_RIGHT - 1:0];

        assign data_left[LVL_NEXT_LEFT - 1:0] = data[LVL_NEXT_LEFT - 1:0];
        assign data_right[LVL_NEXT_RIGHT - 1:0] = data[LVL_TREE - 1:LVL_NEXT_LEFT];
        
        assign more = (more_left < more_right) ? more_left : more_right;
        
         assign class_win = (more_left < more_right) ? class_win_left : class_win_right;       
 
        comparator
            #(
                .AMOUNT_CLASS               (AMOUNT_CLASS),
                .WIDTH_DATA                 (WIDTH_DATA),
                .LVL_TREE                   (LVL_NEXT_LEFT)
            )
        comparator_left
            (
                .data                       (data_left),
                .number                     (number_left),
                
                .more                       (more_left),
                .class_win                  (class_win_left)
            );
        
        comparator
            #(
                .AMOUNT_CLASS               (AMOUNT_CLASS),
                .WIDTH_DATA                 (WIDTH_DATA),
                .LVL_TREE                   (LVL_NEXT_RIGHT)
            )
        comparator_right
            (
                .data                       (data_right),
                .number                     (number_right),
                
                .more                       (more_right),
                .class_win                  (class_win_right)
            );
    end
endgenerate



endmodule 
