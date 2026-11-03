function [P_ev_mean, P_ev_all] = ev_profile_mc(N_ev, N_runs, par)
% EV_PROFILE_MC  Mean daily EV charging profile (uncontrolled) by Monte Carlo.
% PERIODIC DAILY APPROXIMATION, kept for the illustration of Section 2.4:
% sessions past midnight wrap onto the same day. For annual simulations use
% ev_sessions_year, which follows each vehicle chronologically.
%   N_ev   : number of vehicles per day
%   N_runs : number of Monte Carlo runs (days)
%   par    : struct with fields mu_arr, sd_arr, soc0_min, soc0_max,
%            soc_target, E_bat, P_ch, eta
%   P_ev_mean : 1x24 mean hourly demand (kW)
%   P_ev_all  : N_runs x 24, one random day per row (kW)
% Chapter 2, Section 2.4
dt = 1/60;                          % 1-minute resolution (h)
nSteps = round(24/dt);
P_ev_all = zeros(N_runs, 24);

for r = 1:N_runs
    P_min = zeros(1, nSteps);       % charging power, minute by minute
    for k = 1:N_ev
        t_arr = par.mu_arr + par.sd_arr*randn;
        t_arr = mod(t_arr, 24);     % wrap into 0..24 h
        soc0  = par.soc0_min + (par.soc0_max - par.soc0_min)*rand;
        E_need = (par.soc_target - soc0) * par.E_bat / par.eta;   % kWh from grid
        t_ch   = E_need / par.P_ch;                               % hours
        i0 = floor(t_arr/dt) + 1;
        n  = ceil(t_ch/dt);
        idx = mod((i0:i0+n-1) - 1, nSteps) + 1;  % charging past midnight wraps
        P_min(idx) = P_min(idx) + par.P_ch;
    end
    P_ev_all(r,:) = mean(reshape(P_min, 60, 24), 1);   % hourly average (kW)
end
P_ev_mean = mean(P_ev_all, 1);
end
