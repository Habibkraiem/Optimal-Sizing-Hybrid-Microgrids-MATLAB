% ch11_reliability.m  -  sequential Monte Carlo with component failures for
% the fixed Chapter 9 design (Section 11.4). MTTF/MTTR values are
% ILLUSTRATIVE (Table 11.4): replace them with manufacturer or utility data.
% Run after main.m. Results: results/ch11_reliability.txt
clear; clc; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();  prob = define_problem();
S = load('results/case_study_runs.mat', 'bestF', 'bestX');
[~, k] = min(S.bestF(:));  xv = S.bestX{k};
r0 = design_result(xv, TT, par, eco, prob);
x0 = r0.x;  par.bat.Pmax = r0.P_bat;
TT.P_ev = min(TT.P_ev, r0.N_ch * par.P_charger);    % as in fitness.m

rel.pv   = struct('MTTF', 20000, 'MTTR',  72);   % PV inverter (whole array)
rel.wt   = struct('MTTF',  4000, 'MTTR', 120);   % each wind turbine
rel.bat  = struct('MTTF', 30000, 'MTTR',  48);   % battery converter
rel.grid = struct('MTTF',  2000, 'MTTR',   4);   % grid connection (unused when islanded)
nYears = 1000;  N = height(TT);  nwt = max(round(x0.N_wt), 0);
[LOLE, EENS, LPSP] = deal(zeros(nYears,1));
for y = 1:nYears
    rng(y);
    av.pv   = updown_series(N, rel.pv.MTTF,  rel.pv.MTTR);
    av.bat  = updown_series(N, rel.bat.MTTF, rel.bat.MTTR);
    av.grid = updown_series(N, rel.grid.MTTF, rel.grid.MTTR);
    av.wt   = zeros(N, nwt);
    for j = 1:nwt, av.wt(:,j) = updown_series(N, rel.wt.MTTF, rel.wt.MTTR); end
    out = simulate_year_av(x0, TT, par, av);
    LOLE(y) = out.LOLE;  EENS(y) = out.EENS;  LPSP(y) = out.LPSP;
end
o1 = simulate_year(x0, TT, par);
fid = fopen('results/ch11_reliability.txt', 'w');
fprintf(fid, 'Design: PV %.1f kW, %d WT, battery %.1f kWh / %.1f kW, %d chargers (islanded)\n', ...
        x0.P_pv, nwt, x0.E_bat, r0.P_bat, r0.N_ch);
fprintf(fid, 'No failures      : LOLE %d h, EENS %.0f kWh, LPSP %.3f %% (EV demand within charger limit)\n', ...
        o1.LOLE, o1.E_unmet, 100*o1.LPSP);
fprintf(fid, 'With failures    : LOLE mean %.0f h (5th-95th %d-%d), EENS mean %.0f kWh (95th %.0f), LPSP mean %.3f %%\n', ...
        mean(LOLE), prctile_s(LOLE,5), prctile_s(LOLE,95), mean(EENS), prctile_s(EENS,95), 100*mean(LPSP));
fprintf(fid, 'P(LPSP > %.0f %%) with failures: %.1f %% of years | %d simulated years\n', ...
        100*prob.LPSP_max, 100*mean(LPSP > prob.LPSP_max), nYears);
fclose(fid);  type('results/ch11_reliability.txt');

function q = prctile_s(x, p)
% percentile without the Statistics Toolbox (nearest rank)
x = sort(x(:));  q = x(max(1, min(numel(x), round(p/100*numel(x)))));
end
