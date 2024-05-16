clf
clear
clc
close all;

% Define the parameters of the system
a1 = fixedPointToDecimal(110);      %128
a2 = fixedPointToDecimal(50);       %64
a3 = fixedPointToDecimal(80);       %64
b0 = fixedPointToDecimal(64);       %26
b1 = fixedPointToDecimal(7);       %13
b2 = fixedPointToDecimal(3);       %13

% Output the parameters of the system
disp('The parameters of the system are:');                                                                                                                   
disp(['a1 = ', num2str(a1)]);
disp(['a2 = ', num2str(a2)]);
disp(['a3 = ', num2str(a3)]);
disp(['b0 = ', num2str(b0)]);
disp(['b1 = ', num2str(b1)]);
disp(['b2 = ', num2str(b2)]);
disp(' ');

% Define simulation time and sampling time
t_start = 0;
t_end = 30;
Ts = 0.1;
t = t_start:Ts:t_end;
N = length(t);

% Define input signal (unit step function)
R = -500 * ones(1, N);
R(1:10) = 0;
R(11:40) = 100;
R(41:70) = -100;

% Initialize output signal and error signal
U = zeros(1, N);
E = zeros(1, N);
Y = zeros(1, N);

% Simulate feedback system
for n = 4:N
    if mod(n, 5) == 4
        Y(n) = 1.0 * U(n-2); % Calculate feedback signal (delayed by 2 samples
        % Y(n) = 400 / (1 + exp(-U(n-2) / 100)); % Calculate feedback signal (delayed by 2 samples)
    else
        Y(n) = Y(n-1);
    end

    % Y(120:140) = -1900;

    E(n) = R(n) - Y(n); % Calculate error signal

    U(n) = a1*U(n-1) + a2*U(n-2) + a3*U(n-3) + b0*E(n) + b1*E(n-1) + b2*E(n-2); % Calculate output signal
    if U(n) > 1024
        U(n) = 1024;
    end
    if U(n) < -1024
        U(n) = -1024;
    end
    U(n) = round(U(n));
end

% Plot system response
figure;
plot(t, R, 'LineWidth', 2, 'Color', [0.1 0.8 0.5]);
hold on
plot(t, Y, 'LineWidth', 2, 'Color', [0.7 0.5 0.1]);
hold on
plot(t, U, 'LineWidth', 2, 'Color', [0.1 0.2 0.7]);
grid on;
legend('Input Target Value', 'Feedback Value', 'Output Value');
xlabel('Time (s)');
ylabel('Output');
title('Response of 3-zero 3-pole PID system with feedback to unit step function');

% Calculate transfer function of the system
num = [b0 b1 b2];
den = [1 -a1 -a2 -a3];
sys = tf(num, den, Ts);

% Plot pole-zero map
% figure;
% pzmap(sys);
% title('Pole-Zero Map on the Z-plane');

% Check system stability
poles = pole(sys);
if all(abs(poles) < 1)
    disp('The system is stable');
else
    disp('The system is unstable');
end

disp('Poles:');
disp(abs(poles));
