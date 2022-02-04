from vunit import VUnit
import numpy as np
import oct2py
import matplotlib.pyplot as plt

oc = oct2py.Oct2Py()
oc.addpath('../Matlab')


print("Trabajo final")

#NUM_SYMB = 10    # Número de símbols a transmitir
SEED=100;            # Semilla para el generador de números aleatorios
CONSTEL = 'QPSK';    # Constelación utilizada BPSK o QPSK
MODO = '2K'
SNR=200;             #SNR en dB
CP = 1/32; 

[bits_tx, N_portadoras, NFFT, const_points, H_real, H_est, S_tx] = oc.escribir_portadoras(SEED, CONSTEL, MODO, SNR, CP,nout=7)
#np.savetxt('../Matlab/bits_tx.csv',bits_tx,delimiter=',')
NFFT = int(NFFT) # Se pasaba como float
N_portadoras = int(N_portadoras)
N_pilotos = int(np.ceil(N_portadoras/12))

# Create VUnit instance by parsing command-line arguments
vu = VUnit.from_argv()

# Create library 'src_lib', where our files will be compiled
lib = vu.add_library("src_lib")

# Add all files ending in .vhd in current working directory to our library 'src_lib'
lista = ["edc_common.vhd","top_level.vhd", "contador.vhd", "prbs.vhd", "interpolator.vhd", 
    "ecualizador.vhd", "FSM.vhd","top_contador_memoria.vhd","dpram.vhd",
    "tb_top.vhd", 
    "estimador.vhd",
    "tb_estimador.vhd",
    #"tb_prbs.vhd"
    ]

lib.add_source_files(lista)


def post_func(results):
    [H_est_vhdl, S_tx_vhdl, rx_constel, bits_rx_vhdl] = oc.resultados(CONSTEL, MODO, nout=4)
    BER = np.mean(np.logical_xor(bits_tx, np.transpose(bits_rx_vhdl)))
   
    print("BER = "+ str(BER))

    plt.figure()
    plt.scatter(np.real(const_points),np.imag(const_points))
    plt.grid()
    plt.title('Constelación transmitida')

    plt.figure()
    plt.plot(np.linspace(-NFFT/2,NFFT/2-1,NFFT),20*np.log10(np.abs(H_real)))
    plt.plot(np.linspace(-np.floor(N_portadoras/2),np.ceil(N_portadoras/2)-1,N_portadoras),20*np.log10(np.abs(H_est)))
    plt.plot(np.linspace(-np.floor(N_portadoras/2),np.ceil(N_portadoras/2)-1,N_portadoras),20*np.log10(np.abs(H_est_vhdl)))
    plt.legend(['H real','H est', 'H(vhdl)'])
    plt.grid()

    plt.figure()
    plt.plot(np.linspace(-np.floor((N_portadoras-N_pilotos)/2),np.floor((N_portadoras-N_pilotos)/2)-1,N_portadoras-N_pilotos),20*np.log10(np.abs(S_tx)))
    plt.plot(np.linspace(-np.floor((N_portadoras-N_pilotos)/2),np.floor((N_portadoras-N_pilotos)/2)-1,N_portadoras-N_pilotos),20*np.log10(np.abs(S_tx_vhdl)))
    plt.grid()
    plt.legend(['S_tx', 'S_tx(vhdl)'])

    plt.show()


# Run vunit function
vu.main(post_run=post_func)

