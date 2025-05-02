package adc_fir_coeffs;
localparam TAPS = 31;
localparam COEFF_BIT_DEPTH = 32;
var logic signed [COEFF_BIT_DEPTH-1:0] coeffs [TAPS] = {
	32'hffd9d2b0,
	32'hffe19d38,
	32'hffedb99f,
	32'hc621b,
	32'h4e0958,
	32'hc25517,
	32'h174dad6,
	32'h26a3286,
	32'h39decb5,
	32'h501d949,
	32'h67ed6ab,
	32'h7f71fe2,
	32'h949ce62,
	32'ha570d67,
	32'hb045acf,
	32'hb402ae1,
	32'hb045acf,
	32'ha570d67,
	32'h949ce62,
	32'h7f71fe2,
	32'h67ed6ab,
	32'h501d949,
	32'h39decb5,
	32'h26a3286,
	32'h174dad6,
	32'hc25517,
	32'h4e0958,
	32'hc621b,
	32'hffedb99f,
	32'hffe19d38,
	32'hffd9d2b0
};
endpackage