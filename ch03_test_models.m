% ch03_test_models.m  -  all component models over one year (Chapter 3)
clear; clc; close all;
addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');          % from Chapter 2 (or make_demo_data)

% --- Candidate design (example values)
P_pv_rated = 100;      % kW
N_wt       = 2;        % turbines

[par, ~] = load_parameters();
eta_mppt = par.eta_mppt;  eta_ilc = par.eta_ilc;

% --- Production
P_pv = eta_mppt * pv_model(TT.G, TT.Ta, P_pv_rated, par.pv);
P_wt = wind_model(TT.v_hub, N_wt, par.wt);

% --- Demand (AC side)
P_dem = TT.P_load + TT.P_ev;

% --- Annual energy balance (kWh), before storage
E_pv  = sum(P_pv);   E_wt = sum(P_wt);   E_dem = sum(P_dem);
P_net = eta_ilc*P_pv + P_wt - P_dem;
fprintf('PV energy       : %8.0f kWh\n', E_pv);
fprintf('Wind energy     : %8.0f kWh\n', E_wt);
fprintf('Demand          : %8.0f kWh\n', E_dem);
fprintf('Hours in deficit: %d of 8760\n', sum(P_net < 0));

% --- One summer week
rt  = TT.Properties.RowTimes;  yr = year(rt(1));
idx = rt >= datetime(yr,7,1,'TimeZone',rt.TimeZone) & ...
      rt <  datetime(yr,7,8,'TimeZone',rt.TimeZone);
figure('Color','w');
plot(rt(idx), [P_pv(idx) P_wt(idx) P_dem(idx)]);
legend('PV','Wind','Demand'); ylabel('Power (kW)'); grid on;
title('One summer week: production vs demand');
