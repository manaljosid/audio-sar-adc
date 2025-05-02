from pathlib import Path
import numpy as np
from scipy.fft import fft, fftfreq
from scipy.signal.windows import chebwin
from scipy.signal import iirfilter, lfilter
from matplotlib import pyplot as plt

from vunit import VUnitCLI
from vunit.verilog import VUnit

colors = ['#6699ff', '#ff6699', '#ffcc66', '#66ffcc', '#9966ff']

def init(workspace):
    cli = VUnitCLI()
    cli.parser.set_defaults(output_path=workspace)

    vu = VUnit.from_args(args=cli.parse_args())
    lib = vu.add_library("lib")

    return(vu, lib)

def add_source(lib, source):
    lib.add_source_file(source)

def generate_plot(data: np.ndarray,
                  fs: float,
                  file_path: Path,
                  fft_only:bool = True,
                  use_log_plot:bool = False,
                  use_window:bool = False,
                  show_plot:bool = False,
                  save_figure:bool = True,
                  fft_data_offset: float = 0.0) -> None:
    data_fft = data + fft_data_offset
    N = data.size
    T = 1.0 / fs

    font_size = 10

    if use_window:
        w = chebwin(N, 250.0, sym=True)

        F = fft(data_fft * w)
        F = F / np.max(2.0/N * np.abs(F[0:N//2]))
        F = 20.0 * np.log10(2.0/N * np.abs(F[0:N//2]))
    else:
        F = fft(data_fft)
        F = F / np.max(2.0/N * np.abs(F[0:N//2]))
        F = np.maximum(F, 1e-8)
        F = 20.0 * np.log10(2.0/N * np.abs(F[0:N//2]))
    
    X = fftfreq(N, T)[:N//2]

    if fft_only:
        plt.clf()
        plt.cla()
        if use_log_plot:
            plt.semilogx(X, F, color='black', linewidth=0.75)
        else:
            plt.plot(X, F, color='black', linewidth=0.75)
        plt.grid(which='both')
        plt.tick_params(labelsize=font_size*0.85)
        plt.xlabel('Frequency [Hz]', fontsize=font_size)
        plt.ylabel('Amplitude [dB]', fontsize=font_size)
        #plt.axvline(768000.0, linestyle='--', color=colors[0])
    else:
        t = np.linspace(0, N*T, N)
        fig, ax = plt.subplots(2)

        stem = ax[0].stem(t, data, linefmt='black', basefmt='black')
        stem[0].set_markersize(4)
        stem[1].set_linewidth(0.75)
        stem[2].set_alpha(0.6)
        ax[0].plot(t, data, color='black', alpha=0.6)
        ax[0].grid(which='both')
        ax[0].set_title('Waveform', fontsize=font_size)
        ax[0].set_xlabel('Time', fontsize=font_size)
        ax[0].set_ylabel('Amplitude', fontsize=font_size)
        ax[0].tick_params(labelsize=font_size*0.85)
        if use_log_plot:
            ax[1].semilogx(X, F, color='black', linewidth=0.75)
        else:
            ax[1].plot(X, F, color='black', linewidth=0.75)
        ax[1].grid(which='both')
        ax[1].set_title(f"Single-Sided FFT{', Dolph-Chebyshev window' if use_window else ''}", fontsize=font_size)
        ax[1].set_xlabel('Frequency [Hz]', fontsize=font_size)
        ax[1].set_ylabel('Amplitude [dB]', fontsize=font_size)
        ax[1].tick_params(labelsize=font_size*0.85)
    
    
    if save_figure:
        plt.savefig(file_path, dpi=150, bbox_inches='tight')
    if show_plot:
        plt.show()

def generate_sine(path: Path,
                  length: int,
                  bit_depth: int = 16,
                  amplitude: float = 1.0,
                  frequency: float = 1e3,
                  dither: float = 0.0,
                  sample_rate: float = 1.0):
    """
    Generate a sine wave signal.

    Parameters
    ----------
    path : Path
        The path to the output file to be generated
    length : int
        The number of samples to generate
    bit_depth : int
        The bit depth to quantize to
    amplitude : float
        The amplitude of the signal, normalized to [0,1]
    frequency : float
        The frequency of the sine wave
    dither : float
        The amplitude of the additive dither noise
    sample_rate : float
        The sample rate used for generating the sine
    """
    np.random.seed(0)
    T = 1.0 / sample_rate
    x = np.linspace(0.0, length * T, length, endpoint=False)
    p = 2.0 * dither * (np.random.rand(length) - 0.5)
    y = np.sin(frequency * 2.0 * np.pi * x ) + p
    y = y / np.max(np.abs(y)) # Normalize to [-1,1]
    y = y * amplitude
    y = np.round(((2**bit_depth-1) - 1) * y)
    y.tofile(path, sep='\n',format='%d')

def generate_step(path: Path,
                  length: int,
                  bit_depth: int = 16,
                  amplitude: float = 1.0):
    """
    Generate a step function with the step located at the midpoint.

    Parameters
    ----------
    path : Path
        The path to the output file to be generated
    length : int
        The number of samples to generate
    bit_depth : int
        The bit depth to quantize to
    amplitude : float
        The amplitude of the signal, normalized to [0,1]
    """
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

def generate_impulse(path: Path,
                  length: int,
                  bit_depth: int = 16,
                  amplitude: float = 1.0):
    """
    Generate an impulse signal.

    Parameters
    ----------
    path : Path
        The path to the output file to be generated
    length : int
        The number of samples to generate
    bit_depth : int
        The bit depth to quantize to
    amplitude : float
        The amplitude of the signal, normalized to [0,1]
    """
    x = np.zeros(length)
    x[0] = amplitude * (2**(bit_depth-1) - 1)
    x.tofile(path, sep='\n', format='%d')

def generate_dc(path: Path,
                  length: int,
                  bit_depth: int = 16,
                  amplitude: float = 1.0):
    """
    Generate a DC signal.

    Parameters
    ----------
    path : Path
        The path to the output file to be generated
    length : int
        The number of samples to generate
    bit_depth : int
        The bit depth to quantize to
    amplitude : float
        The amplitude of the signal, normalized to [0,1]
    """
    x = np.ones(length) * amplitude
    x = x * (2**(bit_depth-1) - 1)
    x.tofile(path, sep='\n', format='%d')