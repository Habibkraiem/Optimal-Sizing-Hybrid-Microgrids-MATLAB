function [par, eco] = load_parameters()
% LOAD_PARAMETERS  All model and economic parameters in one place.
% !!! EXAMPLE VALUES ONLY: replace every value with datasheet data and
% local prices before using the results in a report, a paper or the book.
% Keep this file and the assumption table of Chapter 9 identical.

% ---- Technical parameters (Chapters 3 and 4)
par.pv  = struct('gamma',-0.004, 'NOCT',45, 'f_der',0.9);
par.wt  = struct('Pr',20, 'vci',3, 'vr',12, 'vco',25);      % one turbine
par.bat = struct('Pmax',50, 'SOCmin',0.2, 'SOCmax',0.95, ...
                 'eta_ch',0.95, 'eta_dis',0.95, 'sigma',0, 'SOC0',0.5);
par.eta_mppt  = 0.97;
par.eta_ilc   = 0.96;
par.grid      = false;          % islanded by default
par.P_imp_max = 0;
par.P_exp_max = 0;
par.P_charger = 7;              % kW per EV charger

% ---- Economic parameters (Chapter 5) -- USD, 2024-2025 sources (see Chapter 9, Table 9.3)
eco.i = 0.06;                   % real discount rate
eco.N = 25;                     % project lifetime (years)
% PV: between IRENA 2024 utility-scale average (691 USD/kW) and small rooftop in
% Saudi Arabia (1,250 USD/kW, Alghamdi et al., Energies 2025); O&M 10 USD/kW/yr (same study)
eco.pv  = struct('cap',900,    'om',10,   'rep',800);     % per kW
% Small wind (< 100 kW): about 7,850 USD/kW installed -> 20 kW turbine
eco.wt  = struct('cap',157000, 'om',3000, 'rep',140000);  % per turbine
% Battery: IRENA 2024 utility-scale 192 USD/kWh, BNEF 2025 turnkey 117 USD/kWh;
% a ~1 MWh community system costs more per kWh
eco.bat = struct('cap',250,    'om',5,    'rep',200);     % per kWh
eco.pv_life        = 25;
eco.wt_life        = 20;
eco.bat_cal_life   = 12;
eco.bat_cycle_life = 4000;      % equivalent full cycles
eco.conv = struct('cap',150,  'om',2,    'rep',120);      % battery converter, per kW
% 7 kW AC charger in Saudi Arabia: SAR 5,000-12,000 with installation -> about 2,100 USD
eco.ch   = struct('cap',2100, 'om',50,   'rep',1600);     % per unit
eco.conv_life      = 10;
eco.ch_life        = 10;
eco.c_imp   = 0.08;             % USD/kWh imported
eco.c_exp   = 0.03;             % USD/kWh exported
eco.EF_grid = 0.6;              % kg CO2/kWh (use your country's value)
end
