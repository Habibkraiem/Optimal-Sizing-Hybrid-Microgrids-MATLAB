% BUILD_SITE_PROFILES  Real weather (NASA POWER) + load + EV demand
% -> data/site_profiles.mat, used by every script of the book.
% Edit the SITE block, then run this script once (internet needed).
% Chapter 2 and Chapter 9.
clear; clc; close all;
addpath(genpath(pwd));
rng(1);

%% ---- SITE (edit here) ------------------------------------------------
site.name = 'Arar, Northern Borders, Saudi Arabia';
site.lat  = 30.98;          % deg N  (check the exact coordinates of your site)
site.lon  = 41.04;          % deg E
site.year = 2023;           % non-leap year -> 8760 hours
site.tz   = 'Asia/Riyadh';
h_hub     = 30;             % wind turbine hub height (m)

%% ---- 1. Weather from NASA POWER --------------------------------------
W = download_nasa_power(site.lat, site.lon, site.year, site.tz);

% Wind shear exponent estimated from the 10 m and 50 m data of the site
ok    = W.v10 > 2 & W.v50 > 2;
alpha = median(log(W.v50(ok) ./ W.v10(ok)) / log(50/10));
v_hub = W.v10 * (h_hub/10)^alpha;
fprintf('Site wind shear exponent alpha = %.3f\n', alpha);

%% ---- 2. Load profile --------------------------------------------------
% Option A (best): your own metered hourly load, 8760 x 1 in kW:
%   P_load = readmatrix('data/my_load.csv');
% Option B: synthetic profile (Section 2.3) -- adapt the shape to your site
s_day   = [0.45 0.40 0.38 0.37 0.38 0.45 0.55 0.60 0.60 0.62 0.65 0.70 ...
           0.72 0.72 0.75 0.80 0.85 0.95 1.00 1.00 0.95 0.85 0.70 0.55];
k_month = [0.75 0.75 0.80 0.90 1.00 1.10 1.15 1.15 1.05 0.90 0.80 0.75];
P_load  = build_load_profile(50, s_day, k_month, 0.85, 0.05);

%% ---- 3. EV demand (Section 2.4) ---------------------------------------
parEV = struct('mu_arr',18, 'sd_arr',2, 'arr_win',[12 23.9], ...
               'mu_dep',7.5, 'sd_dep',1, 'dep_win',[5 10], ...
               'soc0_min',0.2, 'soc0_max',0.6, 'soc_target',0.9, ...
               'E_bat',60, 'P_ch',7, 'eta',0.9);
P_ev = ev_sessions_year(10, 365, parEV);           % chronological sessions (Section 2.4)

%% ---- 4. Assemble and save ----------------------------------------------
TT = timetable(W.t, W.G, W.Ta, W.v10, v_hub, P_load, P_ev, ...
     'VariableNames', {'G','Ta','v10','v_hub','P_load','P_ev'});
TT.Properties.Description = sprintf('%s, %.2fN %.2fE, NASA POWER %d', ...
                                    site.name, site.lat, site.lon, site.year);
save('data/site_profiles.mat', 'TT', 'site', 'alpha');

%% ---- 5. Summary for Table 9.2 -------------------------------------------
dailyIrr = sum(TT.G)/1000/365;
mo = month(TT.Properties.RowTimes);
monthlyIrr = accumarray(mo, TT.G) / 1000 ./ eomday(site.year, (1:12)');
monthlyWind = accumarray(mo, TT.v_hub, [], @mean);
fprintf('\n%s\n', TT.Properties.Description);
fprintf('Mean daily irradiation : %.2f kWh/m2/day (min %.2f, max %.2f)\n', ...
        dailyIrr, min(monthlyIrr), max(monthlyIrr));
fprintf('Mean temperature       : %.1f degC (min %.1f, max %.1f)\n', ...
        mean(TT.Ta), min(TT.Ta), max(TT.Ta));
fprintf('Mean wind at %d m      : %.2f m/s\n', h_hub, mean(TT.v_hub));
fprintf('Annual load / EV       : %.0f / %.0f MWh\n', sum(P_load)/1000, sum(P_ev)/1000);

figure('Color','w');
yyaxis left;  bar(1:12, monthlyIrr); ylabel('Irradiation (kWh/m^2/day)');
yyaxis right; plot(1:12, monthlyWind, '-o', 'LineWidth', 1.5); ylabel(sprintf('Wind at %d m (m/s)', h_hub));
xticks(1:12); xticklabels({'J','F','M','A','M','J','J','A','S','O','N','D'});
title(sprintf('Figure 9.1 - %s, %d', site.name, site.year)); grid on;
if ~exist('results', 'dir'), mkdir('results'); end
exportgraphics(gcf, 'results/fig9_1_monthly_resource.pdf', 'ContentType', 'vector');
