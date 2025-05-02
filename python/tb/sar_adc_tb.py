from pathlib import Path
import numpy as np
from scipy.fft import fft, fftfreq
from scipy.signal.windows import chebwin
from scipy.signal import iirfilter, lfilter, firwin
from matplotlib import pyplot as plt

import vunit_common

# NOTE: This assumes the location of the directories relative to where this is run from
FIGURES = Path(__file__).parent / ".." / "figures"
WORKSPACE = Path(__file__).parent / ".." / "workspace" / "modelsim"
LIB_ROOT = Path(__file__).parent / ".." / ".." / "lib"
SYN_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "syn"
SIM_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "sim"

def create_coeff_file(path: Path,
                      order: int,
                      cutoff: float,
                      sample_rate: float,
                      coeff_bit_depth: int):
    """
    Generate a systemverilog file containing FIR coefficients. Uses a window method with a Hamming window.

    Parameters
    ----------
    path : Path
        The path to the coefficient file to be generated
    order : int
        The order of the filter to generate (number of taps is order + 1)
    cutoff : float
        The cutoff frequency of the filter in Hz
    sample_rate : float
        The sample rate the filter will operate at
    coeff_bit_depth : int
        The fixed point bit depth of the filter coefficients
    """
    raw_coeffs = firwin(order+1, cutoff, window='hamming', fs=sample_rate)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f'package adc_fir_coeffs;\n')
        f.write(f'localparam TAPS = {len(raw_coeffs)};\n')
        f.write(f'localparam COEFF_BIT_DEPTH = {coeff_bit_depth};\n')
        f.write(f'var logic signed [COEFF_BIT_DEPTH-1:0] coeffs [TAPS] = {{\n')
        for i in range(len(raw_coeffs)):
            hex_value_coeffs = hex(int(round(raw_coeffs[i]*2**(coeff_bit_depth-1))) & ((1 << (coeff_bit_depth)) - 1))
            if i == len(raw_coeffs)-1:
                f.write(f"\t{coeff_bit_depth}'h{hex_value_coeffs[2:]}\n")
            else:
                f.write(f"\t{coeff_bit_depth}'h{hex_value_coeffs[2:]},\n")
        f.write('};\n')
        f.write('endpackage')

def run_sim(adc_sample_rate: int = 48000,
            dac_osr: int = 128,
            test_freq: float = 1e3,
            test_samples: int = 4096,
            dac_order: int = 1):
    
    dac_sample_rate = adc_sample_rate * 16 * dac_osr
    coeff_bit_depth = 32
    fir_cutoff_freq = 1.3 * adc_sample_rate * 16
    fir_order = dac_osr - 2
    dac_dither = 0

    file_name_prefix = f'sar_adc_{adc_sample_rate}_{dac_osr}_dsm{dac_order}{"_dither" if dac_dither == 1 else ""}'

    input_file_name = str(file_name_prefix + "_input_data.csv")
    output_file_name = str(file_name_prefix + "_output_data.csv")
    input_file_path = WORKSPACE / "modelsim" / Path("./" + input_file_name)
    output_file_path = WORKSPACE / "modelsim" / Path("./" + output_file_name)

    coeff_file_name = str(file_name_prefix + "_coeffs.sv")
    coeff_file_path = SIM_ROOT / Path("./" + coeff_file_name)

    figure_file_name = str(file_name_prefix + "_response.eps")
    figure_file_path = FIGURES / Path("./" + figure_file_name)

    create_coeff_file(coeff_file_path, fir_order, fir_cutoff_freq, dac_sample_rate, coeff_bit_depth)

    vunit_common.generate_sine(input_file_path, test_samples, amplitude=0.35, frequency=test_freq, sample_rate=adc_sample_rate)
    
    vu, lib = vunit_common.init(WORKSPACE)

    vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/syn/axis_if/axis_if.sv")
    vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/sim/axis_bfm/axis_bfm.sv")
    vunit_common.add_source(lib, SYN_ROOT / "./fir.sv")
    vunit_common.add_source(lib, SYN_ROOT / "./dsm1.sv")
    vunit_common.add_source(lib, SYN_ROOT / "./dsm2.sv")
    vunit_common.add_source(lib, SYN_ROOT / "./sar_fsm.sv")
    vunit_common.add_source(lib, SYN_ROOT / "./sar_adc.sv")
    vunit_common.add_source(lib, SIM_ROOT / "./sar_adc_tb.sv")
    vunit_common.add_source(lib, SIM_ROOT / "./adc_fir_coeffs.sv")

    tb = lib.test_bench("sar_adc_tb")

    tb.add_config("TEST", parameters={
        "BIT_DEPTH" : 16,
        "DAC_OSR": dac_osr,
        "DAC_ORDER": dac_order,
        "DAC_DITHER": dac_dither,
        "INPUT_DATA": f'"{input_file_name}"',
        "OUTPUT_DATA": f'"{output_file_name}"'
        })

    vu._main(post_run=None)

    data = np.loadtxt(output_file_path, delimiter=',')
    vunit_common.generate_plot(data,
                               adc_sample_rate,
                               figure_file_path,
                               fft_only=True,
                               use_log_plot=True,
                               use_window=True,
                               show_plot=False,
                               save_figure=True)

if __name__ == '__main__':
    # Sample rate, OSR, DAC order
    param_array = [(48000, 128, 1),
                   (48000, 256, 1),
                   (48000, 512, 1),
                   (48000, 128, 2),
                   (48000, 256, 2),
                   (48000, 512, 2)]
    
    for parameters in param_array:
        print(parameters)
        run_sim(adc_sample_rate=parameters[0],
                dac_osr=parameters[1],
                dac_order=parameters[2],
                test_samples=16384)