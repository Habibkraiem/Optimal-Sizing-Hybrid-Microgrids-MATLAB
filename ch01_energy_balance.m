% ch01_energy_balance.m  -  first look at a daily energy balance (Chapter 1)
clear; clc; close all;

t = 0:23;                                   % hours of the day

% --- Illustrative PV profile (kW): bell shape between 6 h and 18 h
P_pv_rated = 50;                            % installed PV power (kW)
P_pv = P_pv_rated * max(0, sin(pi*(t-6)/12));

% --- Illustrative load profile (kW): base + evening peak
P_load = 20 + 15*exp(-((t-20).^2)/8) + 5*exp(-((t-8).^2)/4);

% --- Net power: positive = surplus, negative = deficit
P_net = P_pv - P_load;

E_surplus = sum(P_net(P_net > 0));          % kWh (1-hour steps)
E_deficit = -sum(P_net(P_net < 0));         % kWh

fprintf('Daily PV energy : %6.1f kWh\n', sum(P_pv));
fprintf('Daily load      : %6.1f kWh\n', sum(P_load));
fprintf('Surplus         : %6.1f kWh\n', E_surplus);
fprintf('Deficit         : %6.1f kWh\n', E_deficit);

% --- Plot
figure('Color','w');
plot(t, P_pv, '-o', 'LineWidth', 1.5); hold on;
plot(t, P_load, '-s', 'LineWidth', 1.5);
bar(t, P_net, 0.5, 'FaceAlpha', 0.3);
yline(0, 'k-');
xlabel('Hour of the day'); ylabel('Power (kW)');
legend('PV production', 'Load', 'Net power', 'Location', 'northwest');
title('Daily energy balance (illustrative profiles)');
grid on; xlim([0 23]);
if ~exist('results', 'dir'), mkdir('results'); end
exportgraphics(gcf, 'results/ch01_energy_balance.png', 'Resolution', 300);
