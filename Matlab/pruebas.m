NFFT=2048;
NCP = 12;            % Número de muestras del prefijo cíclico
NDATA=97;            % Número de portadoras utilizadas
NUM_SYMB = 10;       % Número de símbols a transmitir
SEED=100;            % Semilla para el generador de números aleatorios
CONSTEL = 'BPSK';    % Constelación utilizada BPSK o QPSK
SNR=-50;             %SNR en dB
NUM_CARRIER = 1705; % Número de portadoras para 2k
K_max = 1704;        % Número máximo de portadora
T_U = 224e-6;        % Tiempo útil
PLOC=1:12:1705;

numbits = NUM_SYMB*NDATA*M;
bits_tx = rand(numbits, 1)>0.5; % numbits x 1

%Generacion de los pilotos, ya modulados
registro = ones(1,11);
registro_salida = zeros(1,143);
for n = 1:143
    registro_salida = [registro(end),registro_salida(1:end-1)];
    registro = [xor(registro(end),registro(end-2)),registro(1:(end-1))];
end
registro_salida = fliplr(registro_salida);
pilotos = (4/3)*2*((1/2) - registro_salida);

% Data bits to symbols
aux  = reshape(bits_tx, M, []).'; % numbits/M x M
symb = zeros(size(aux, 1),1);     % numbits/M x 1
for k=1:M
    symb = symb + (2^(k-1))*aux(:,k); % primera columna = lsb 
end
const_points = C(symb+1);
const_points = const_points./(sqrt(2));

% Símbolos OFDM en frecuencia (rejilla tiempo frecuencia)
ofdm_completa = zeros (NFFT, NUM_SYMB);
ofdm_freq = zeros(NUM_CARRIER,NUM_SYMB);
for l=1:NUM_SYMB
    ofdm_freq(1:12:1705, l) = pilotos;
end
ofdm_freq(ofdm_freq==0) = const_points;

ofdm_completa(172:1876,:) = ofdm_freq;