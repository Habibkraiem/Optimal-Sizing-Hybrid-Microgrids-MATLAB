% main.m  -  complete case study (Chapter 9)
% Long run: 4 algorithms x nRuns x budget evaluations. Start small.
clear; clc; close all;
addpath(genpath(pwd));
if ~exist('results', 'dir'), mkdir('results'); end
diary('results/main_log.txt');      % everything printed is also saved here

%% 1. Data (Chapter 2)
load('data/site_profiles.mat', 'TT');

%% 2. Parameters (Chapters 3 and 5)
[par, eco] = load_parameters();

%% 3. Problem (Chapter 6)
prob = define_problem();
fobj = @(xv) fitness(xv, TT, par, eco, prob);

%% 4. Optimizers and settings (Chapters 7 and 8)
algos = {@pso, @ga_real, @gwo, @rda};
names = {'PSO','GA','GWO','RDA'};
budget = 6000;  nRuns = 30;
opts  = load_optimizer_settings(budget);

%% 5. Runs
tic;
bestF = inf(nRuns, numel(algos));  bestX = cell(nRuns, numel(algos));
hist  = cell(nRuns, numel(algos));
for a = 1:numel(algos)
    parfor r = 1:nRuns          % runs in parallel if the Parallel Computing Toolbox is installed
        rng(r);
        bf = BudgetFitness(fobj, budget);
        x  = algos{a}(@(v) bf.eval(v), prob.lb, prob.ub, opts{a});
        bestF(r,a) = bf.best;  bestX{r,a} = x;  hist{r,a} = bf.history;
    end
    fprintf('%s done: best %.0f, mean %.0f\n', names{a}, min(bestF(:,a)), mean(bestF(:,a)));
end
fprintf('Total run time: %.1f min\n', toc/60);
save('results/case_study_runs.mat', 'bestF', 'bestX', 'hist', 'names', 'budget', 'nRuns');

%% 6. Best design overall and its full results
[~, k] = min(bestF(:));  [r, a] = ind2sub(size(bestF), k);
[~, res] = fitness(bestX{r,a}, TT, par, eco, prob);
save('results/best_design.mat', 'res');
fprintf('\nBest design (%s, run %d):\n', names{a}, r);
fprintf('  PV %.1f kW | %d turbines | battery %.1f kWh / %.1f kW | %d chargers\n', ...
        res.x.P_pv, res.x.N_wt, res.x.E_bat, res.P_bat, res.N_ch);
fprintf('  NPC %.0f USD | LCOE %.3f USD/kWh | LPSP %.2f %% | LOLE %d h\n', ...
        res.NPC, res.LCOE, 100*res.LPSP, res.LOLE);

% NPC share of each component (Table 9.5)
c.pv   = component_npc(res.x.P_pv,  eco.pv,   eco.pv_life,   eco.i, eco.N);
c.wt   = component_npc(res.x.N_wt,  eco.wt,   eco.wt_life,   eco.i, eco.N);
c.bat  = component_npc(res.x.E_bat, eco.bat,  res.life_bat,  eco.i, eco.N);
c.conv = component_npc(res.P_bat,   eco.conv, eco.conv_life, eco.i, eco.N);
c.ch   = component_npc(res.N_ch,    eco.ch,   eco.ch_life,   eco.i, eco.N);
fprintf('  NPC shares: PV %.1f %% | WT %.1f %% | battery %.1f %% | converter %.1f %% | chargers %.1f %%\n', ...
        100*[c.pv c.wt c.bat c.conv c.ch]/res.NPC);
fprintf('  Curtailment %.1f %% | battery life %.1f y | refused EV energy %.0f kWh\n', ...
        100*res.curt, res.life_bat, res.E_ev_lost);
onb = abs(bestX{r,a} - prob.ub) < 1e-6;
if any(onb), fprintf('  WARNING: on an upper bound -> %s\n', strjoin(prob.names(onb), ', ')); end
diary off

%% 7. Tables and figures (Section 9.5)
make_case_study_figures(res, bestF, hist, names);
