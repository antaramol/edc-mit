%% Generación secuencia PRBS

clear

registro = ones(1,11);
registro_salida = zeros(1,143);
for n = 1:143
    % registro_salida = [registro(end),registro_salida(1:end-1)];
    registro_salida(n) = registro(end);
    registro = [xor(registro(end),registro(end-2)),registro(1:(end-1))];
end

registro_salida = 4/3*2*(0.5-registro_salida);