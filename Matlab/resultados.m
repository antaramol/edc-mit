function BER = resultados(CONSTEL, MODO, bits_tx)


switch MODO
    case '2K'
        N_portadoras = 1705;
    case '8K'
        N_portadoras = 6817;
end

N_pilotos = ceil(N_portadoras/12);

NDATA=N_portadoras- N_pilotos;  
PLOC=1:12:N_portadoras;


% cargar entradas vhdl
rx_re = csvread('../Matlab/s_rx_re.csv')';
rx_im = csvread('../Matlab/s_rx_im.csv')';

S_tx_vhdl = rx_re/2^7 + 1i*rx_im/2^7;

S_tx_vhdl(PLOC,:) = []; 

rx_constel = reshape(S_tx_vhdl,(N_portadoras-N_pilotos),1).';

% Demap
switch CONSTEL
    case 'BPSK'
        bits_rx = rx_constel<0;
        M = '1';
    case 'QPSK'
        bits_rx = zeros(1,length(rx_constel)*2);
        bits_rx(2:2:end) = real(rx_constel)<0;
        bits_rx(1:2:end) = imag(rx_constel)<0;
        M='2';
    case '16QAM'
        norma = sqrt(18);
        bits_rx = zeros(1,length(rx_constel)*4);
        bits_rx(4:4:end) = real(rx_constel)<0;
        bits_rx(3:4:end) = imag(rx_constel)<0;
        bits_rx(2:4:end) = abs(real(rx_constel))<(2/norma);
        bits_rx(1:4:end) = abs(imag(rx_constel))<(2/norma);
        M='4';
    case '64QAM'
        norma = sqrt(98);
        bits_rx = zeros(1,length(rx_constel)*6);
        bits_rx(6:6:end) = real(rx_constel)<0;
        bits_rx(5:6:end) = imag(rx_constel)<0;
        bits_rx(4:6:end) = abs(real(rx_constel))<(4/norma);
        bits_rx(3:6:end) = abs(imag(rx_constel))<(4/norma);
        bits_rx(2:6:end) = abs(real(rx_constel))<(6/norma) & abs(real(rx_constel))>(2/norma);
        bits_rx(1:6:end) = abs(imag(rx_constel))<(6/norma) & abs(imag(rx_constel))>(2/norma);
        M='6';
end

BER = mean(xor(bits_rx, bits_tx(1:size(bits_rx).')));

end
