% ch11_montecarlo.m  -  Monte Carlo over weather years, load level, EV
% behaviour and costs for the fixed Chapter 9 design (Section 11.3).
% Each mechanism is first sampled alone, then all together.
% Run after main.m. Results: results/ch11_montecarlo.txt
clear; clc; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par0, eco0] = load_parameters();  prob = define_problem();
S = load('results/case_study_runs.mat', 'bestF', 'bestX');
[~, k] = min(S.bestF(:));  xv = S.bestX{k};
W = load_weather_years(TT);                       % several years if available
parEV = struct('mu_arr',18, 'sd_arr',2, 'arr_win',[12 23.9], 'mu_dep',7.5, 'sd_dep',1, ...
               'dep_win',[5 10], 'soc0_min',0.2, 'soc0_max',0.6, 'soc_target',0.9, ...
               'E_bat',60, 'P_ch',7, 'eta',0.9);
h0 = hour(TT.Properties.RowTimes(1));
nMC = 500;
cases = {'load', 'ev', 'costs', 'weather', 'all'};
fid = fopen('results/ch11_montecarlo.txt', 'w');
fprintf(fid, 'Monte Carlo, %d samples per case, fixed design; %d weather year(s) available\n', nMC, numel(W));
fprintf(fid, '%-8s | LCOE mean | 95%% CI of mean | 5th-95th pct    | LPSP mean | P(LPSP > %.0f %%)\n', 100*prob.LPSP_max);
for c = 1:numel(cases)
    [L, P] = deal(zeros(nMC,1));
    for m = 1:nMC
        rng(m);
        TTm = TT;  par = par0;  eco = eco0;
        if any(strcmp(cases{c}, {'weather','all'})), TTm = W{randi(numel(W))}; end
        if any(strcmp(cases{c}, {'load','all'})),    TTm.P_load = TT.P_load * max(0, 1 + 0.1*randn); end
        if any(strcmp(cases{c}, {'ev','all'}))
            Pe = ev_sessions_year(10, 365, parEV);  TTm.P_ev = circshift(Pe, -h0);
        end
        if any(strcmp(cases{c}, {'costs','all'})),   [par, eco] = sample_costs(par0, eco0, 0.2); end
        r = design_result(xv, TTm, par, eco, prob);
        L(m) = r.LCOE;  P(m) = r.LPSP;
    end
    Ls = sort(L);  se = std(L)/sqrt(nMC);
    fprintf(fid, '%-8s | %9.4f | +/- %10.4f | [%.4f, %.4f] | %7.3f %% | %6.1f %%\n', cases{c}, mean(L), ...
            1.96*se, Ls(round(0.05*nMC)), Ls(round(0.95*nMC)), 100*mean(P), 100*mean(P > prob.LPSP_max));
end
fclose(fid);  type('results/ch11_montecarlo.txt');
