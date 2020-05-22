module pll (refclk, rst, outclk_0);

input refclk = 0;
input rst = 0;
output outclk_0;
output locked;


pll pll (
.refclk(refclk),
.rst(rst),
.outclk_0(outclk_0),
)

pll pll (
.refclk(refclk),
.rst(rst),
.outclk_0(outclk_0),
)


