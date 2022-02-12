function [bits_tx, N_portadoras, NFFT, const_points, H_real, H_est, S_tx] = escribir_portadoras(SEED, CONSTEL, MODO, SNR, CP)
    
    NUM_SYMB = 2; % Para comprobación con vhdl dos símbolos
    rand("seed",SEED);


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

H_real = ((rho_i.*exp(-1i*theta_i)).'*(exp(-1i*2*pi*k*delta_f.*tau_i))).';

h_real_tiempo = ifft(ifftshift(H_real),NFFT,1);

rx_antena = conv(h_real_tiempo,tx);
rx_antena = rx_antena(1:end-(NFFT-1),1);

% rx_antena = tx; %Anula efecto del canal


% Ruido
Ps = mean(tx.*conj(tx)); % Potencia de señal
nsr = 10^(-SNR/10);      % Pn/Ps

noise = (randn(size(tx))+1i*randn(size(tx))) / sqrt(2); % Ruido complejo de potencia 1
noise = sqrt(Ps*nsr).*noise; % Ruido complejo de potencia Ps*snr

rx = rx_antena+noise;
%rx = rx_antena;



%% Receptor
% TO-DO: Receptor (operaciones inversas al transmisor)

ofdm_time_r_NCP = reshape(rx,NFFT+NCP,NUM_SYMB);

ofdm_time_r=ofdm_time_r_NCP(NCP+1:end,:);

ofdm_freq_r=fft(ofdm_time_r,NFFT,1);

ofdm_freq_r= fftshift(ofdm_freq_r,1);

ofdm_util_r =ofdm_freq_r(ceil((NFFT-N_portadoras)/2)+(1:N_portadoras),:);



% guardar datos para vhdl
csvwrite('Matlab/portadoras_re.csv', int32(real(ofdm_util_r(:,1)*2^7))); %Direcciones desde el run.py
csvwrite('Matlab/portadoras_im.csv', int32(imag(ofdm_util_r(:,1)*2^7)));

csvwrite('Matlab/portadoras2_re.csv', int32(real(ofdm_util_r(:,2)*2^7)));
csvwrite('Matlab/portadoras2_im.csv', int32(imag(ofdm_util_r(:,2)*2^7)));


H_est = zeros(N_portadoras,1);

H_est(PLOC,1) = ofdm_util_r(PLOC,1)./pilotos(PLOC,1);

xq = 1:N_portadoras;
H_est = interp1(PLOC,H_est(PLOC,1),xq).';

S_tx = ofdm_util_r./H_est;
S_tx(PLOC,:) = []; 

end