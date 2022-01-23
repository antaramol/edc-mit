clear 

n=8;
m=23;

portadoras_re = single(load('portadoras_re.csv'));

d2b = [(portadoras_re(:,1)<0) abs(fix(rem(portadoras_re(:,1)*pow2(-(n-1):m),2)))];

for i = 1:1705
    aux = append(dec2bin(d2b(i,:))');
end

writematrix(aux, "pruebas.csv");