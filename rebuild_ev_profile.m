% rebuild_ev_profile.m  -  replaces the EV demand of data/site_profiles.mat
% with the chronological session model of Section 2.4 (ev_sessions_year),
% keeping the weather and the load unchanged. No internet needed.
% A copy of the previous file is kept as data/site_profiles_v1.mat.
clear; clc; addpath(genpath(pwd));
if ~exist('data/site_profiles_v1.mat', 'file')
    copyfile('data/site_profiles.mat', 'data/site_profiles_v1.mat');
end
D = load('data/site_profiles_v1.mat');  TT = D.TT;   % always start from the original file
rng(1);
parEV = struct('mu_arr',18, 'sd_arr',2, 'arr_win',[12 23.9], ...
               'mu_dep',7.5, 'sd_dep',1, 'dep_win',[5 10], ...
               'soc0_min',0.2, 'soc0_max',0.6, 'soc_target',0.9, ...
               'E_bat',60, 'P_ch',7, 'eta',0.9);
[P_ev, S, info] = ev_sessions_year(10, 365, parEV);
h0 = hour(TT.Properties.RowTimes(1));           % align hour 1 with the first row
P_ev = circshift(P_ev, -h0);
P1 = D.TT.P_ev;                                  % previous EV column
TT.P_ev = P_ev;  D.TT = TT;
save('data/site_profiles.mat', '-struct', 'D');  % same variables, new EV column
if ~exist('results', 'dir'), mkdir('results'); end
writetable(S, 'results/ev_sessions.csv');

fid = fopen('results/ev_check.txt', 'w');
fprintf(fid, 'Sessions: %d (10 vehicles x 365 days)\n', height(S));
fprintf(fid, 'Energy requested: %.1f kWh | delivered: %.1f kWh | in hourly profile: %.1f kWh\n', ...
        info.E_req, info.E_del, info.E_profile);
fprintf(fid, 'Delivered - profile: %.2e kWh | requested - delivered: %.1f kWh (sessions limited by dwell time)\n', ...
        info.E_del - info.E_profile, info.E_req - info.E_del);
fprintf(fid, 'Checks: charging after arrival %d, before departure %d, E_del <= E_req %d, profile = sum of sessions %d\n', ...
        info.ok_after_arrival, info.ok_before_depart, info.ok_not_above_req, info.ok_profile_energy);
fprintf(fid, 'Sessions not fully charged before departure: %d\n', info.n_short);
fprintf(fid, 'Arrival: min %.2f h, max %.2f h | departure: min %.2f h, max %.2f h (next day)\n', ...
        min(S.t_arr), max(S.t_arr), min(S.t_dep)-24, max(S.t_dep)-24);
fprintf(fid, 'Dwell time: min %.1f h, mean %.1f h | energy per session: min %.1f, mean %.1f, max %.1f kWh\n', ...
        min(S.t_dep - S.t_arr), mean(S.t_dep - S.t_arr), min(S.E_req), mean(S.E_req), max(S.E_req));
fprintf(fid, 'Max vehicles plugged in at once: %d | max charging at once: %d\n', info.max_plugged, info.max_charging);
fprintf(fid, 'Peak EV power: %.1f kW | daily EV energy: mean %.0f kWh\n', max(P_ev), mean(sum(reshape(P_ev,24,[]),1)));
fprintf(fid, 'Old profile (wrapped days): annual %.1f MWh, peak %.1f kW, energy 00-06 h %.1f %%\n', ...
        sum(P1)/1e3, max(P1), 100*sum(P1(mod(0:8759,24) < 6))/sum(P1));
fprintf(fid, 'New profile (chronological): annual %.1f MWh, peak %.1f kW, energy 00-06 h %.1f %%\n', ...
        sum(P_ev)/1e3, max(P_ev), 100*sum(P_ev(mod(0:8759,24) < 6))/sum(P_ev));
fclose(fid);
type('results/ev_check.txt');
