module count_60(
    input wire rst,
    input wire clk,
    input wire en,
    output wire [3:0] count,
    output wire co
);
    wire co10,co6;
    
    count_10 u_count_10(
    	.rst   (rst   ),
        .clk   (clk   ),
        .en    (en    ),
        .count (count ),
        .co    (co    )
    );
    
    count_6 u_count_6(
    	.rst   (rst   ),
        .clk   (clk   ),
        .en    (en    ),
        .count (count ),
        .co    (co    )
    );
    
endmodule