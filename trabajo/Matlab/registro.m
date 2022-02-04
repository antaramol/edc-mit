%% Generación secuencia PRBS
function pilotos = registro(N_portadoras)
    registro = ones(1,11);
    pilotos = zeros(N_portadoras,1);
    for n = 1:N_portadoras
        pilotos(n,:) = 4/3*2*(0.5-registro(end));
        registro = [xor(registro(end),registro(end-2)),registro(1:(end-1))];
    end

end