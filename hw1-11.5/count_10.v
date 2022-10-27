module count_10(
    input wire rst,
    input wire clk,
    input wire en,
    output reg [3:0] count,
    output reg co
);
    always @ (posedge clk) begin
        if (rst) begin
            count <= 4'b0;
            co <= 1'b0;
        end
        else if (en) begin
            if (count == 4'd9) begin
                count <= 4'b0;
                co <= 1'b1;
            end
            else begin
                count <= count + 1'b1;
                co <= 1'b0;
            end
        end
    end
endmodule