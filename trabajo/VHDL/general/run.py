from vunit import VUnit
import numpy as np
import oct2py
import matplotlib.pyplot as plt

from subprocess import call

oc = oct2py.Oct2Py()
oc.addpath('Matlab')


print("Trabajo final")

#NUM_SYMB = 10    # Número de símbols a transmitir
SEED=100;            # Semilla para el generador de números aleatorios
CONSTEL = '64QAM';    # Constelación utilizada BPSK o QPSK
MODO = '8K'
SNR=20;             #SNR en dB
CP = 1/32; 

[bits_tx, N_portadoras, NFFT, const_points, H_real, H_est, S_tx] = oc.escribir_portadoras(SEED, CONSTEL, MODO, SNR, CP,nout=7)
#np.savetxt('../Matlab/bits_tx.csv',bits_tx,delimiter=',')
NFFT = int(NFFT) # Se pasaba como float
N_portadoras = int(N_portadoras)
N_pilotos = int(np.ceil(N_portadoras/12))

# Create VUnit instance by parsing command-line arguments
vu = VUnit.from_argv()

# Enable OSVVM (Open Source VHDL Verification Methology)2
vu.add_osvvm()

# Create library 'src_lib', where our files will be compiled
lib = vu.add_library("src_lib")

# Add all files ending in .vhd in current working directory to our library 'src_lib'
lista = ["*.vhd"]

lib.add_source_files(lista)


# Enable code coverage collection
lib.set_sim_option("enable_coverage", True)
lib.set_compile_option("enable_coverage", True)


# Función llamada después de la ejecución de VHDL
def post_func(results):

    results.merge_coverage(file_name="coverage_data")
    if vu.get_simulator_name() == "ghdl":
        call(["gcovr", "coverage_data"])
        call(["lcov", '--capture', '--directory', '.', '--output', 'coverage.info'])
        call(["genhtml", "coverage.info", "--output-directory", "coverage_report"])

        
    # Mostramos datos y gráficas de interés
    
    [H_est_vhdl, S_tx_vhdl, rx_constel, bits_rx_vhdl] = oc.resultados(CONSTEL, MODO, nout=4)
    BER = np.mean(np.logical_xor(bits_tx, np.transpose(bits_rx_vhdl)))
   
    print("BER = "+ str(BER))

    plt.figure()
    plt.scatter(np.real(const_points),np.imag(const_points))
    plt.grid()
    plt.title('Constelación transmitida')

    # Esto es para eliminar el warning de log10(0) = -inf
    def replaceZeros(data):
        min_nonzero = np.min(data[np.nonzero(data)])
        data[data == 0] = min_nonzero
        return data

    H_est_vhdl = replaceZeros(H_est_vhdl)

    plt.figure()
    plt.plot(np.linspace(-NFFT/2,NFFT/2-1,NFFT),20*np.log10(np.abs(H_real)))
    plt.plot(np.linspace(-np.floor(N_portadoras/2),np.ceil(N_portadoras/2)-1,N_portadoras),20*np.log10(np.abs(H_est)))
    plt.plot(np.linspace(-np.floor(N_portadoras/2),np.ceil(N_portadoras/2)-1,N_portadoras),20*np.log10(np.abs(H_est_vhdl)))
    plt.legend(['H real','H est', 'H(vhdl)'])
    plt.grid()


    S_tx_vhdl = replaceZeros(S_tx_vhdl)

    plt.figure()
    plt.plot(np.linspace(-np.floor((N_portadoras-N_pilotos)/2),np.floor((N_portadoras-N_pilotos)/2)-1,N_portadoras-N_pilotos),20*np.log10(np.abs(S_tx)))
    plt.plot(np.linspace(-np.floor((N_portadoras-N_pilotos)/2),np.floor((N_portadoras-N_pilotos)/2)-1,N_portadoras-N_pilotos),20*np.log10(np.abs(S_tx_vhdl)))
    plt.grid()
    plt.title('Símbolo recibido')
    plt.legend(['S_tx', 'S_tx(vhdl)'])


    plt.figure()
    plt.scatter(np.real(rx_constel),np.imag(rx_constel))
    plt.grid()
    plt.title('Constelación recibida')


    plt.show()


# Run vunit function
vu.main(post_run=post_func)

