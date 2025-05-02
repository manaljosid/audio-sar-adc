from pathlib import Path
import numpy as np
from scipy.fft import fft, fftfreq
from scipy.signal.windows import chebwin
from scipy.signal import iirfilter, lfilter, firls, firwin
from matplotlib import pyplot as plt

import vunit_common

# NOTE: FIR Params
SAMPLE_RATE = 48000 * 16 * 512
CUTOFF_FREQ = 1e6 # 1.5 MHz
ORDER = 510 # Execute Order 66
COEFF_BIT_DEPTH = 16

# NOTE: Simulation Params
BIT_DEPTH = 16
TEST_FREQ = SAMPLE_RATE / 32
TEST_SAMPLES = 2**14

# NOTE: File Names
DATA_FILE_PREFIX = "fir_tb"
DATA_FILE_POSTFIX_INPUT = "_input_data.csv"
DATA_FILE_POSTFIX_OUTPUT = "_output_data.csv" 
COEFFICIENT_FILE_POSTFIX = "_coeffs.sv"
PLOT_FILE_NAME = "fir_response.eps"

# NOTE: This assumes the location of the directories relative to where this is run from
FIGURES = Path(__file__).parent / ".." / "figures"
WORKSPACE = Path(__file__).parent / ".." / "workspace" / "modelsim"
LIB_ROOT = Path(__file__).parent / ".." / ".." / "lib"
SYN_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "syn"
SIM_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "sim"

def create_coeff_file():
    bands = (0, CUTOFF_FREQ, CUTOFF_FREQ * 1.01, SAMPLE_RATE/2)
    desired = (1, 1, 0, 0)
    #raw_coeffs = firls(ORDER+1, bands, desired, fs=SAMPLE_RATE)
    raw_coeffs = firwin(ORDER+1, CUTOFF_FREQ, window='hamming', fs=SAMPLE_RATE)
    fpath = SIM_ROOT / Path(str("./" + DATA_FILE_PREFIX + COEFFICIENT_FILE_POSTFIX))
    print(f'Saving coefficients into {fpath.absolute().as_posix()}')
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(f'package {DATA_FILE_PREFIX}_coeffs;\n')
        f.write(f'localparam TAPS = {len(raw_coeffs)};\n')
        f.write(f'localparam COEFF_BIT_DEPTH = {COEFF_BIT_DEPTH};\n')
        f.write(f'var logic signed [COEFF_BIT_DEPTH-1:0] coeffs [TAPS] = {{\n')
        for i in range(len(raw_coeffs)):
            hex_value_coeffs = hex(int(round(raw_coeffs[i]*2**(COEFF_BIT_DEPTH-1))) & ((1 << (COEFF_BIT_DEPTH)) - 1))
            if i == len(raw_coeffs)-1:
                f.write(f"\t{COEFF_BIT_DEPTH}'h{hex_value_coeffs[2:]}\n")
            else:
                f.write(f"\t{COEFF_BIT_DEPTH}'h{hex_value_coeffs[2:]},\n")
        f.write('};\n')
        f.write('endpackage')

def post_func(results):
    report = results.get_report()
    path = report.output_path / "modelsim" / Path(str("./" + DATA_FILE_PREFIX + DATA_FILE_POSTFIX_OUTPUT))
    print(f'Loading data file from {path.absolute().as_posix()}')
    data = np.loadtxt(path, delimiter=',')
    vunit_common.generate_plot(data,
                               SAMPLE_RATE,
                               FIGURES / PLOT_FILE_NAME,
                               fft_only=False,
                               use_log_plot=True,
                               use_window=True,
                               show_plot=True,
                               save_figure=False)
    return True

def post_func_alt(results):
    report = results.get_report()
    path = report.output_path / "modelsim" / Path(str("./" + DATA_FILE_PREFIX + DATA_FILE_POSTFIX_OUTPUT))
    print(f'Loading data file from {path.absolute().as_posix()}')
    data = np.loadtxt(path, delimiter=',')
    N = data.size
    T = 1.0 / SAMPLE_RATE
    t = np.linspace(0, N*T, N)

    font_size = 10

    transition = N / (2 * SAMPLE_RATE)
    threshold = transition + (1.0 / 768000.0)

    plt.axvline(transition, linestyle='--', color=vunit_common.colors[0])
    plt.axvline(threshold, linestyle='--', color=vunit_common.colors[0])

    plt.plot(t, data, color='black')
    plt.grid(which='both')
    plt.xlabel('Time [$\mu$s]', fontsize=font_size)
    plt.ylabel('Amplitude [V]', fontsize=font_size)
    #plt.savefig(FIGURES / 'dsm2_step_zoom.eps', dpi=150, bbox_inches='tight')
    plt.show()
    return True

def generate_sine(frequency: float, length: int, path: str, ampl: float = 1.0, dither: float = 0.0):
    """
    Generate a sine wave csv for the testbench

    Parameters
    ----------
    frequency : float
        The frequency of the sine wave, in Hz
    length : int
        The number of samples to generate
    dither : float
        Dithering amplitude
    path : str
        The path and file name for the output csv file
    """
    np.random.seed(0)
    T = 1.0 / SAMPLE_RATE
    x = np.linspace(0.0, length * T, length, endpoint=False)
    p = 2.0 * dither * (np.random.rand(length) - 0.5)
    y = np.sin(frequency * 2.0 * np.pi * x ) + p
    y = y / np.max(np.abs(y)) # Normalize to [-1,1]
    y = y * ampl
    y = np.round(((2**15) - 1) * y)
    y.tofile(path, sep='\n',format='%d')

def generate_step(amplitude: float, length: int, path: str, bit_depth: int = 16):
    dither = -80
    x = np.zeros(length+1)
    x[length//2:] = np.ones((length//2)+1)
    np.random.seed(0)
    p = (10.0**(dither/20.0)) * 2.0 * (np.random.rand(length+1) - 0.5)
    #x = x + p
    x = x * amplitude
    x = x / np.max(np.abs(x))
    x = np.round((2**(bit_depth-1) - 1) * x)
    
    x.tofile(path, sep='\n', format='%d')

def generate_impulse(length: int, path: str, bit_depth: int = 16):
    x = np.zeros(length)
    x[0] = 2**(bit_depth-1) - 1
    x.tofile(path, sep='\n', format='%d')

def generate_dc(length: int, path: str, value: int, bit_depth: int = 16):
    x = np.ones(length) * value
    x = x * (2**(bit_depth-1) - 1)
    x.tofile(path, sep='\n', format='%d')

def pre_config(output_path):
    path = WORKSPACE / "modelsim" / Path(str("./" + DATA_FILE_PREFIX + DATA_FILE_POSTFIX_INPUT))
    print(f'Saving data file to {path.absolute().as_posix()}')
    #generate_sine(TEST_FREQ, TEST_SAMPLES, path, ampl=1, dither=0.0)
    generate_step(1.0, TEST_SAMPLES, path, BIT_DEPTH)
    #generate_impulse(TEST_SAMPLES, path, bit_depth=BIT_DEPTH)
    #generate_dc(TEST_SAMPLES, path, 0.5, bit_depth=BIT_DEPTH)
    return True

#vu.main()
if __name__ == '__main__':
    create_coeff_file()
    
    vu, lib = vunit_common.init(WORKSPACE)

    vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/syn/axis_if/axis_if.sv")
    vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/sim/axis_bfm/axis_bfm.sv")
    vunit_common.add_source(lib, SYN_ROOT / "./fir.sv")
    vunit_common.add_source(lib, SIM_ROOT / "./fir_tb.sv")
    vunit_common.add_source(lib, SIM_ROOT / str("./" + DATA_FILE_PREFIX + COEFFICIENT_FILE_POSTFIX))

    # Create testbench
    tb = lib.test_bench("fir_tb")

    input_data_path = ""

    tb.add_config("TEST", parameters={
        "BIT_DEPTH" : BIT_DEPTH
        }, pre_config=pre_config)

    vu.main(post_run=post_func_alt)