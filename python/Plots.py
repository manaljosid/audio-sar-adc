import numpy as np
from matplotlib import pyplot as plt
from pathlib import Path

figure_folder = Path(__file__).parent / 'figures'
#colors = ['#9933ff', '#ff9933', '#33ff99']
colors = ['#6699ff', '#ff6699', '#ffcc66', '#66ffcc', '#9966ff']

def sampled_signal_plot(generate_horizontal=False, generate_labels=False):
    def signal(n):
        sig = 0.2 * np.cos(np.pi * n) + np.cos(0.15 * np.pi * n)
        sig = sig - np.min(sig)
        sig = sig / np.max(sig)
        return sig
    
    n = np.linspace(0, 11, 11000)
    x_smooth = n
    y_smooth = signal(n)
    x_coarse = x_smooth[0::1000]
    y_coarse = y_smooth[0::1000]
    x_smooth = x_smooth[0:10000]
    y_smooth = y_smooth[0:10000]

    plt.clf()
    plt.cla()
    plt.plot(x_smooth, y_smooth, linewidth=3.0, color=colors[0])
    marker, line, base = plt.stem(x_coarse, y_coarse, linefmt='--', basefmt='black')
    marker.set_markersize(12)
    marker.set_zorder(100) # Draw on top
    marker.set_color(colors[0])
    line.set_linewidth(3.0)
    line.set_color('black')
    base.set_linewidth(3.0)
    if generate_horizontal:
        marker, line, base = plt.stem(y_coarse, x_coarse, orientation='horizontal', linefmt='--')
        marker.set_alpha(0)
        line.set_color('black')
        line.set_zorder(0)
        base.set_alpha(0)
    plt.box(on=False)
    if generate_labels:
        font_size = 20.0
        plt.xlabel('Time', fontsize=font_size)
        plt.ylabel('Voltage', fontsize=font_size)
    ax = plt.gca()
    ax.xaxis.set_tick_params(labelbottom=False)
    ax.yaxis.set_tick_params(labelleft=False)
    ax.set_xticks([])
    ax.set_yticks([])

    plt.tight_layout()
    plt.savefig(figure_folder / 'sampled_signal.eps', dpi=150, bbox_inches='tight')

def quantized_line_plot():
    n = np.linspace(-1, 1, 1000)
    x = np.round(5.0 * n) / 5.0

    width = 2.0
    font_size = 14.0

    plt.clf()
    plt.cla()
    plt.plot(n, x, color=colors[1], linestyle='--', linewidth=width)
    plt.plot(n, n, color=colors[4], linestyle='-', linewidth=width)
    plt.grid(linewidth=width*0.75)
    plt.xticks(fontsize=font_size*0.75)
    plt.yticks(fontsize=font_size*0.75)

    plt.xlabel('Input voltage', fontsize=font_size)
    plt.ylabel('Output voltage', fontsize=font_size)
    
    ax = plt.gca()
    ax.set_aspect('equal')
    ax.set_xlim([np.min(n), np.max(n)])
    ax.set_ylim([np.min(n), np.max(n)])
    
    plt.tight_layout()
    plt.savefig(figure_folder / 'quantized_line.eps', dpi=150, bbox_inches='tight')

def quantization_error_plot():
    n = np.linspace(-1, 1, 10000)
    x = 0.5* ((((n+0.5) * 10.0) % 2.0) - 1.0)

    width = 2.0
    font_size = 12.0

    plt.clf()
    plt.cla()
    plt.axvline(0, color='0.6', linestyle=':', linewidth=width)
    plt.axhline(0, color='0.6', linestyle=':', linewidth=width)
    plt.axhline(np.min(x), color='0.6', linestyle=':', linewidth=width)
    plt.axhline(np.max(x), color='0.6', linestyle=':', linewidth=width)
    plt.plot(n, x, color=colors[4], linewidth=width)
    #plt.grid(linewidth=width*0.75)
    plt.xticks(np.linspace(-1, 1, 9, endpoint=True), fontsize=font_size*0.75)
    plt.yticks(np.linspace(-0.5, 0.5, 5, endpoint=True), fontsize=font_size*0.75)

    plt.xlabel('Input voltage', fontsize=font_size)
    plt.ylabel('Voltage error', fontsize=font_size)

    ax = plt.gca()
    ax.set_xlim([np.min(n), np.max(n)])
    ax.set_ylim([1.5*np.min(x), 1.5*np.max(x)])
    ax.set_aspect(0.3)

    plt.tight_layout()
    plt.savefig(figure_folder / 'quantization_error.eps', dpi=150, bbox_inches='tight')

def bit_depth_snr_plot():
    n = np.arange(1, 25, 1)
    def calculate_snr(bits):
        return 20.0 * np.log10(np.power(2, bits)) + 20.0 * np.log10(np.sqrt(3.0/2.0))
    snr = calculate_snr(n)
    width = 1.0
    font_size = 12.0

    plt.clf()
    plt.cla()
    plt.plot(n, snr, color=colors[4])
    plt.grid(linewidth=width)
    plt.xticks(fontsize=font_size*0.75)
    plt.yticks(fontsize=font_size*0.75)
    plt.scatter(16, calculate_snr(16), color=colors[1], zorder=100, label='16 bits')
    plt.legend()

    plt.xlabel('Bits', fontsize=font_size)
    plt.ylabel('SNR [dB]', fontsize=font_size)

    ax = plt.gca()
    ax.set_xlim([np.min(n), np.max(n)])
    ax.set_ylim([np.min(snr), np.max(snr)])
    
    plt.tight_layout()
    plt.savefig(figure_folder / 'snr_bit_depth.eps', dpi=150, bbox_inches='tight')

def four_bit_conversion():
    length = 10000
    n = np.linspace(0, 4, length)
    x = np.zeros(length)

    def set_value(vec, val):
        for i in range(vec.size):
            vec[i] = val
        return vec
    
    set_value(x[length//4:], 0.5)
    set_value(x[(length//4)*2:], 0.75)
    set_value(x[(length//4)*3:], 0.625)

    width = 4.0
    font_size = 16

    plt.clf()
    plt.cla()
    
    plt.axhline(0.65, color=colors[2], linestyle='--', linewidth=width, label='Input voltage')
    plt.plot(n, x, color=colors[4], linewidth=width, label='ADC estimate')
    plt.xticks(np.linspace(0, 4, 5, endpoint=True), fontsize=font_size*0.85)
    plt.yticks(np.linspace(-1, 1, 9, endpoint=True), fontsize=font_size*0.85)
    plt.grid(linewidth=width*0.75)
    plt.legend(fontsize=font_size)

    plt.xlabel('Time', fontsize=font_size)
    plt.ylabel('Voltage', fontsize=font_size)
    plt.tight_layout()

    ax = plt.gca()
    ax.set_xlim([np.min(n), np.max(n)])
    ax.set_ylim([-1, 1])
    
    plt.savefig(figure_folder / 'four_bit_conversion.eps', dpi=150, bbox_inches='tight')

if __name__ == '__main__':
    #sampled_signal_plot(generate_labels=True)
    #quantized_line_plot()
    quantization_error_plot()
    #bit_depth_snr_plot()
    #four_bit_conversion()
    plt.show()