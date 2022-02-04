clear;
close all;
%% comentario
%% Configuración del sistema OFDM
NUM_SYMB = 1;       % Número de símbols a transmitir
SEED=100;            % Semilla para el generador de números aleatorios
CONSTEL = 'QPSK';    % Constelación utilizada BPSK o QPSK
MODO = '2K';
SNR=200;             %SNR en dB
CP = 1/32;          % Cyclic prefix

tic

% Inicializamos el generador de números aleatorios con la semilla

%rng(SEED);

%Octave
rand("seed",SEED);

% Definición de la constelación
switch MODO
    case '2K'
        N_portadoras = 1705;
        T_U = 224e-6;        % Tiempo útil
        NFFT=2048;
    case '8K'
        N_portadoras = 6817;
        T_U = 896e-6;
        NFFT=8192;
end

N_pilotos = ceil(N_portadoras/12);
NDATA=N_portadoras- N_pilotos;   
NCP = NFFT*CP;          % Número de muestras del prefijo cíclico

PLOC=1:12:N_portadoras;

switch CONSTEL
    case 'BPSK'
        M=1;
        C=[1 -1];
        norma = sqrt(2);
    case 'QPSK'
        C=[1+1i 1-1i -1+1i -1-1i];
        M=2;      
        norma = sqrt(2);
    case '16QAM'
        C = [3+3i 3+1i 1+3i 1+1i 3-3i 3-1i 1-3i 1-1i -3+3i -3+1i -1+3i -1+1i -3-3i -3-1i -1-3i -1-1i];
        M=4;
        norma = sqrt(18);
    case '64QAM'
        C = [7+7i 7+5i 5+7i 5+5i 7+1i 7+3i 5+1i 5+3i 1+7i 1+5i 3+7i 3+5i 1+1i 1+3i 3+1i 3+3i 7-7i 7-5i 5-7i 5-5i 7-1i 7-3i 5-1i 5-3i 1-7i 1-5i 3-7i 3-5i 1-1i 1-3i 3-1i 3-3i -7+7i -7+5i -5+7i -5+5i -7+1i -7+3i -5+1i -5+3i -1+7i -1+5i -3+7i -3+5i -1+1i -1+3i -3+1i -3+3i -7-7i -7-5i -5-7i -5-5i -7-1i -7-3i -5-1i -5-3i -1-7i -1-5i -3-7i -3-5i -1-1i -1-3i -3-1i -3-3i];
        M=6;
        norma = sqrt(98);
end

%scatterplot(C);
%grid
%title('Constelación')

%% Transmisor
% Generación de los bits a transmitir
numbits = NUM_SYMB*NDATA*M;
bits_tx = rand(numbits, 1)>0.5; % numbits x 1

% Bits to symbols
aux  = reshape(bits_tx, M, []).'; % numbits/M x M
symb = zeros(size(aux, 1),1);     % numbits/M x 1
for k=1:M
    symb = symb + (2^(k-1))*aux(:,k); % primera columna = lsb 
end

% Mapper
const_points = C(symb+1); % numbits/M x 1
const_points = const_points./(norma);

%scatterplot(const_points);
%grid
%title('Constelación transmitida') 

% Símbolos OFDM en frecuencia (rejilla tiempo frecuencia)
ofdm_freq = zeros(NFFT, NUM_SYMB); % NFFT x NUM_SYMB
ofdm_util = ofdm_freq(ceil((NFFT-N_portadoras)/2)+(1:N_portadoras),:);

registro = ones(1,11);
pilotos = zeros(N_portadoras,1);
for n = 1:N_portadoras
    pilotos(n,:) = 4/3*2*(0.5-registro(end));
    registro = [xor(registro(end),registro(end-2)),registro(1:(end-1))];
end

ofdm_util(PLOC,:) = pilotos(PLOC,1)*ones(1,NUM_SYMB);
ofdm_util(ofdm_util==0) = const_points;
ofdm_freq(ceil((NFFT-N_portadoras)/2)+(1:N_portadoras),:) = ofdm_util;

figure
stem(real(ofdm_freq(:,1))); % Pintamos un único símbolo
grid
xlabel('Portadoras OFDM');
ylabel('Amplitud');
title('Espectro OFDM')

% ifftshift permite pasar de una representación del espectro con el f=0 en el
% centro a una representación con f=0 a la izquierda.
% Importante el 1 para hacer la transformación en la dimensión correcta
ofdm_freq=ifftshift(ofdm_freq, 1); % NFFT x NUM_SYMB


% Modulacion OFDM
% Importante el 1 para hacer la transformación en la dimensión correcta
ofdm_time = ifft(ofdm_freq, NFFT, 1); % NFFT x NUM_SYMB

% Prefijo cíclico de forma matricial
ofdm_time = [ofdm_time(end-(NCP-1):end, :); ofdm_time];

% Salida secuencial (el : lee por columnas)
tx = ofdm_time(:); % (NFFT+NCP)·NUM_SYMB x 1
 
figure
plot(real(tx), 'b-');
hold on
plot(imag(tx), 'r-');
xlabel('Muestras temporales');
ylabel('Amplitud');
legend('real', 'imag');
grid
title('Señal OFDM en el tiempo')

% Espectro de la señal transmitida
% figure
% pwelch(tx);

%% Canal AWGN


% Canal real

parametros = [0.057662 1.003019 4.855121
0.176809 5.422091 3.419109
0.407163 0.518650 5.864470
0.303585 2.751772 2.215894
0.258782 0.602895 3.758058
0.061831 1.016585 5.430202
0.150340 0.143556 3.952093
0.051534 0.153832 1.093586
0.185074 3.324866 5.775198
0.400967 1.935570 0.154459
0.295723 0.429948 5.928383
0.350825 3.228872 3.053023
0.262909 0.848831 0.628578
0.225894 0.073883 2.128544
0.170996 0.203952 1.099463
0.149723 0.194207 3.462951
0.240140 0.924450 3.664773
0.116587 1.381320 2.833799
0.221155 0.640512 3.334290
0.259730 1.368671 0.393889];

rho_i = parametros(:,1);
tau_i = parametros(:,2)*10^-6;
theta_i = parametros(:,3);


delta_f = 1/T_U;
k = (-NFFT/2:NFFT/2-1);

% H_real = zeros(NFFT,1);
% for n= 1:2048
%     H_real(n,1) = sum(rho_i.*exp(-1i*theta_i).*exp(-1i*2*pi*k(n)*delta_f*tau_i));
% end

% for n = 1:20
%     H_real = H_real + rho_i(n)*exp(-1i*theta_i(n))*exp(-1i*2*pi*k.'*delta_f*tau_i(n));
% end
% 
% figure, hold on, plot((-floor(N_portadoras/2):ceil(N_portadoras/2)-1)*delta_f,20*log10(abs(H_real(NFFT/2-floor(N_portadoras/2):NFFT/2+ceil(N_portadoras/2)-1))))


H_real = ((rho_i.*exp(-1i*theta_i)).'*(exp(-1i*2*pi*k*delta_f.*tau_i))).';

figure, hold on, grid on, plot((-NFFT/2:NFFT/2-1)*delta_f,20*log10(abs(H_real)))

h_real_tiempo = ifft(ifftshift(H_real),NFFT,1);

rx_antena = conv(h_real_tiempo,tx);
rx_antena = rx_antena(1:end-(NFFT-1),1);

% rx_antena = tx; %Anula efecto del canal

% figure
% plot(real(rx_antena), 'b-');
% hold on
% plot(imag(rx_antena), 'r-');
% xlabel('Muestras temporales');
% ylabel('Amplitud');
% legend('real', 'imag');
% grid
% title('Señal OFDM en el tiempo')


% Ruido
Ps = mean(tx.*conj(tx)); % Potencia de señal
nsr = 10^(-SNR/10);      % Pn/Ps

noise = (randn(size(tx))+1i*randn(size(tx))) / sqrt(2); % Ruido complejo de potencia 1
noise = sqrt(Ps*nsr).*noise; % Ruido complejo de potencia Ps*snr
% Alternativa a las dos líneas anteriores:
% noise = wgn(size(tx,1), 1, Ps*nsr, 'complex');

rx = rx_antena+noise;
%rx = rx_antena;

% Return termina la ejecución del script. Las líneas de después no se
% ejecutarán
% return


%% Receptor
% TO-DO: Receptor (operaciones inversas al transmisor)

ofdm_time_r_NCP = reshape(rx,NFFT+NCP,NUM_SYMB);

ofdm_time_r=ofdm_time_r_NCP(NCP+1:end,:);

ofdm_freq_r=fft(ofdm_time_r,NFFT,1);

ofdm_freq_r= fftshift(ofdm_freq_r,1);

ofdm_util_r =ofdm_freq_r(ceil((NFFT-N_portadoras)/2)+(1:N_portadoras),:);

% scatterplot(ofdm_util_r(:,1))

figure
stem(abs(ofdm_freq_r(:,1))); % Pintamos un único símbolo
grid
xlabel('Portadoras rececpción OFDM');
ylabel('Amplitud');
title('Espectro OFDM')


H_est = zeros(N_portadoras,1);
% H_est(PLOC,1) = H_real(PLOC+NFFT/2-ceil(1705/2),1);
H_est(PLOC,1) = ofdm_util_r(PLOC,1)./pilotos(PLOC,1);

xq = 1:N_portadoras;
H_est = interp1(PLOC,H_est(PLOC,1),xq).';

% Interpolación lineal de H_est
% x = 1:12;
% for n = 1:N_pilotos-1 % ceil(PLOC/12)
%     b = H_est((n-1)*12+1);
%     a = (H_est(12*n+1) - H_est((n-1)*12+1))/12;
%     y = a*x + b;
%     H_est((n-1)*12+2:12*n+1) = y;
% end



% guardar datos para vhdl
%writematrix(real(int32(ofdm_util_r(:,1)*2^7)), 'portadoras_re.csv');
%writematrix(imag(int32(ofdm_util_r(:,1)*2^7)), 'portadoras_im.csv');

% Octave
csvwrite('portadoras_re.csv', int32(real(ofdm_util_r(:,1)*2^7))');
csvwrite('portadoras_im.csv', int32(imag(ofdm_util_r(:,1)*2^7))');
% cargar entradas vhdl
%real_matrix_vhdl = readmatrix('salida_re.csv')';
%imag_matrix_vhdl = readmatrix('salida_im.csv')';

% Octave
real_matrix_vhdl = csvread('estim_re.csv')';
imag_matrix_vhdl = csvread('estim_im.csv')';


H_est_vhdl = double(real_matrix_vhdl)/2^7 + 1i*double(imag_matrix_vhdl)/2^7;


figure(3)
plot((-floor(N_portadoras/2):ceil(N_portadoras/2)-1)*delta_f,20*log10(abs(H_est)))
plot((-floor(N_portadoras/2):ceil(N_portadoras/2)-1)*delta_f,20*log10(abs(H_est_vhdl)))
legend('H real','H est', 'H(vhdl)')


% División en frecuencia Tx = Rx / H_est
S_tx = ofdm_util_r./H_est;
%S_tx_vhdl = ofdm_util_r./H_est_vhdl;

% Comparamos con vhdl
%rx_re = readmatrix('s_rx_re.csv')';
%rx_im = readmatrix('s_rx_im.csv')';

%Octave
rx_re = csvread('s_rx_re.csv')';
rx_im = csvread('s_rx_im.csv')';

S_tx_vhdl = rx_re/2^7 + 1i*rx_im/2^7;


% Quitamos los pilotos
S_tx(PLOC,:) = []; 
S_tx_vhdl(PLOC,:) = []; 

figure
hold on
plot((-floor((N_portadoras-N_pilotos)/2):ceil((N_portadoras-N_pilotos)/2)-1)*delta_f,20*log10(imag(S_tx(:,1))))
plot((-floor((N_portadoras-N_pilotos)/2):ceil((N_portadoras-N_pilotos)/2)-1)*delta_f,20*log10(imag(S_tx_vhdl)))
legend('S_tx', 'S_tx(vhdl)')

% Concatenar los bits recibidos
%rx_constel = reshape(S_tx,(N_portadoras-N_pilotos)*NUM_SYMB,1).';
rx_constel = reshape(S_tx_vhdl,(N_portadoras-N_pilotos),1).';

%scatterplot(rx_constel);

% Demap
switch CONSTEL
    case 'BPSK'
        bits_rx = rx_constel<0;
    case 'QPSK'
        bits_rx = zeros(1,length(rx_constel)*2);
        bits_rx(2:2:end) = real(rx_constel)<0;
        bits_rx(1:2:end) = imag(rx_constel)<0;
    case '16QAM'
        bits_rx = zeros(1,length(rx_constel)*4);
        bits_rx(4:4:end) = real(rx_constel)<0;
        bits_rx(3:4:end) = imag(rx_constel)<0;
        bits_rx(2:4:end) = abs(real(rx_constel))<(2/norma);
        bits_rx(1:4:end) = abs(imag(rx_constel))<(2/norma);
    case '64QAM'
        bits_rx = zeros(1,length(rx_constel)*6);
        bits_rx(6:6:end) = real(rx_constel)<0;
        bits_rx(5:6:end) = imag(rx_constel)<0;
        bits_rx(4:6:end) = abs(real(rx_constel))<(4/norma);
        bits_rx(3:6:end) = abs(imag(rx_constel))<(4/norma);
        bits_rx(2:6:end) = abs(real(rx_constel))<(6/norma) & abs(real(rx_constel))>(2/norma);
        bits_rx(1:6:end) = abs(imag(rx_constel))<(6/norma) & abs(imag(rx_constel))>(2/norma);
end

%BER = mean(xor(bits_rx, bits_tx.'));
%fprintf(1,'CONSTEL = %s, SNR = %ddB, MODO = %s, CP = 1/%d\n',CONSTEL,SNR,MODO,1/CP);
%fprintf(1, 'BER = %f\n', BER);

BER_vhdl = mean(xor(bits_rx, bits_tx(1:length(bits_rx)).'));
fprintf(1,'CONSTEL = %s, SNR = %ddB, MODO = %s, CP = 1/%d\n',CONSTEL,SNR,MODO,1/CP);
fprintf(1, 'BER_vhdl = %f\n', BER_vhdl);
toc
