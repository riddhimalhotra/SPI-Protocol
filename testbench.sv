module tb;
reg clk = 0 , newd = 0;
reg [7:0] din = 0;
wire [7:0] dout;

daisy_c dut(clk, newd, din, dout);

always #5 clk = ~clk;

initial begin
repeat(5) @(posedge clk);
newd = 1;
din = $urandom;
@(posedge dut.master.sclk);
newd = 0;
@(posedge dut.master.cs);
$stop;

end
  initial begin 
  $dumpfile("ab.vcd");
  $dumpvars;
end  



endmodule