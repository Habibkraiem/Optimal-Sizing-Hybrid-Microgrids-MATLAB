% ch04_run_design.m  -  simulate and plot one design (Chapter 4)
clear; clc; close all; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');

[par, ~] = load_parameters();                 % islanded by default
x = struct('P_pv',100, 'N_wt',2, 'E_bat',200);  % example design
out = simulate_year(x, TT, par);

fprintf('LPSP        : %5.2f %%\n', 100*out.LPSP);
fprintf('LOLE        : %5d h/year\n', out.LOLE);
fprintf('Curtailed   : %8.0f kWh\n', out.E_dump);
fprintf('Battery N_eq: %5.0f cycles/year\n', out.N_eq);

% --- SOC over the year and the first week of January
s = out.series;
figure('Color','w');
subplot(2,1,1); plot(s.SOC); ylabel('SOC'); title('Battery SOC over the year'); grid on;
subplot(2,1,2); w = 1:168;
plot(w, [s.P_ren(w) s.P_dem(w) s.P_unmet(w)]);
legend('Renewables','Demand','Unmet'); xlabel('Hour'); ylabel('kW'); grid on;
