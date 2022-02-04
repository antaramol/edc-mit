from vunit import VUnit
import numpy as np
import oct2py

oc = oct2py.Oct2Py()
oc.addpath('../Matlab')


print("Trabajo final")

NUM_SYMB = 10    # Número de símbols a transmitir
SEED=100;            # Semilla para el generador de números aleatorios
CONSTEL = 'QPSK';    # Constelación utilizada BPSK o QPSK
MODO = '2K'
SNR=200;             #SNR en dB
CP = 1/32; 

bits_tx = oc.escribir_portadoras(NUM_SYMB, SEED, CONSTEL, MODO, SNR, CP)

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
    BER = oc.resultados(CONSTEL, MODO, bits_tx)
    print("BER = "+ str(BER))


# Run vunit function
vu.main(post_run=post_func)

