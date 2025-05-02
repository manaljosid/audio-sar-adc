from pathlib import Path
import numpy as np
from scipy.fft import fft, fftfreq
from scipy.signal.windows import chebwin
from scipy.signal import iirfilter, lfilter
from matplotlib import pyplot as plt

import vunit_common

# NOTE: Constants
OSR = 512
F_OUTPUT = 48000.0 * 16.0 * OSR
TEST_FREQ = 1e5#768000.0/2.0
TEST_SAMPLES = 32768*16
BIT_DEPTH = 16

# NOTE: This assumes the location of the directories relative to where this is run from
FIGURES = Path(__file__).parent / ".." / "figures"
WORKSPACE = Path(__file__).parent / ".." / "workspace" / "modelsim"
LIB_ROOT = Path(__file__).parent / ".." / ".." / "lib"
SYN_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "syn"
SIM_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "sim"

vu, lib = vunit_common.init(WORKSPACE)

vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/syn/axis_if/axis_if.sv")
vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/sim/axis_bfm/axis_bfm.sv")
vunit_common.add_source(lib, SYN_ROOT / "./dsm1.sv")
vunit_common.add_source(lib, SIM_ROOT / "./dsm1_tb.sv")

# Create testbench
tb = lib.test_bench("dsm1_tb")

input_data_path = ""

def post_func(results):
    report = results.get_report()
    path = report.output_path / "modelsim" / "dsm1_output_data.csv"
    data = np.loadtxt(path, delimiter=',')
    vunit_common.generate_plot(data,
                               F_OUTPUT,
                               FIGURES / f'dsm1_fft_osr_{int(OSR)}.eps',
                               fft_only=True,
                               use_log_plot=True,
                               use_window=True,
                               show_plot=True,
                               save_figure=True,
                               fft_data_offset=-0.5)
    return True

def post_func_alt(results):
    report = results.get_report()
    path = report.output_path / "modelsim" / "dsm1_output_data.csv"
    data = np.loadtxt(path, delimiter=',')
    N = data.size
    T = 1.0 / F_OUTPUT
    t = np.linspace(0, N*T, N)

    fs = F_OUTPUT # Hz
    fc = 1500000.0 # Hz
    b, a = iirfilter(4, fc, btype='lowpass', analog=False, ftype='bessel', fs=fs)
    y = lfilter(b, a, data)
    transition = (N//2)/fs
    threshold = transition + (1.0 / 768000.0)

    slice = int(np.round((threshold + threshold - transition)*fs))
    max = np.max(y[slice:])
    min = np.min(y[slice:])

    ampl = max-min
    ampl = -20.0 * np.log10(ampl)
    print(f'SNR: {ampl} dB')
    enob = (ampl - 1.76) / 6.02
    print(f'ENOB: {enob} bits')

    font_size = 10

    transition = transition * 1e6
    threshold = threshold * 1e6

    plt.axvline(transition, linestyle='--', color=vunit_common.colors[0])
    plt.axvline(threshold, linestyle='--', color=vunit_common.colors[0])
    plt.plot(t*1e6, y, color='black')
    plt.grid(which='both')
    plt.xlabel('Time [$\mu$s]', fontsize=font_size)
    plt.ylabel('Normalised amplitude [V]', fontsize=font_size)
    ax = plt.gca()
    diff = threshold - transition
    ax.set_xlim([threshold + diff, np.max(t)*1e6]) #transition - (diff/2.0), threshold + (diff*4.0)
    ax.set_ylim([0.9998, 1.0002]) #0.4, 1.1 #0.9998, 1.0002
    plt.savefig(FIGURES / 'dsm1_step_zoom.eps', dpi=150, bbox_inches='tight')
    plt.show()
    return True

#def generate_sine(frequency: float, length: int, path: str, dither: float = 0.0):
#    """
#    Generate a sine wave csv for the testbench
#
#    Parameters
#    ----------
#    frequency : float
#        The frequency of the sine wave, in Hz
#    length : int
#        The number of samples to generate
#    dither : float
#        Dithering amplitude
#    path : str
#        The path and file name for the output csv file
#    """
#    T = 1.0 / F_OUTPUT
#    x = np.linspace(0.0, length * T, length, endpoint=False)
#    p = 2.0 * dither * (np.random.rand(length) - 0.5)
#    y = np.round(((2**15) - 1) * (np.sin(frequency * 2.0 * np.pi * x ) + p))
#    y.tofile(path, sep='\n',format='%d')


def generate_sine(frequency: float, length: int, path: str, enable_dither:bool = False, dither: float = 0.0, bit_depth: int = 16):
    """
    Generate a sine wave csv for the testbench

    Parameters
    ----------
    frequency : float
        The frequency of the sine wave, in Hz
    length : int
        The number of samples to generate
    dither : float
        Dithering amplitude in db
    path : str
        The path and file name for the output csv file
    """
    T = 1.0 / F_OUTPUT
    x = np.linspace(0.0, length * T, length, endpoint=False)
    np.random.seed(0)
    p = 10**(dither/20) *  2.0 * (np.random.rand(length) - 0.5)
    y = np.sin(frequency * 2.0 * np.pi * x)
    if enable_dither:
        y = y + p
    y = y / np.max(abs(y))
    y = np.round(((2**(bit_depth - 1)) - 1) * y)
    y.tofile(path, sep='\n',format='%d')

def generate_step(amplitude: float, length: int, path: str, bit_depth: int = 16):
    dither = -80
    x = np.zeros(length+1)
    x[length//2:] = np.ones((length//2)+1)
    np.random.seed(0)
    p = (10.0**(dither/20.0)) * 2.0 * (np.random.rand(length+1) - 0.5)
    #x = x + p
    x = x / np.max(np.abs(x))
    x = x * amplitude
    x = np.round((2**(bit_depth-1) - 1) * x)
    
    x.tofile(path, sep='\n', format='%d')

def pre_config(output_path):
    path = WORKSPACE / "modelsim" / "dsm1_input_data.csv"
    #generate_sine(TEST_FREQ, TEST_SAMPLES, path, bit_depth=BIT_DEPTH)
    generate_step(0.66, TEST_SAMPLES, path, BIT_DEPTH)
    return True

tb.add_config("TEST", parameters={"BIT_DEPTH" : BIT_DEPTH}, pre_config=pre_config) #parameters={"INPUT_DATA" : input_data_path}

vu.main(post_run=post_func_alt)