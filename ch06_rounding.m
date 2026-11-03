% ch06_rounding.m  -  rounding inside the fitness vs continuous relaxation
% followed by rounding (Section 6.4). PSO, same budget and seeds as main.m.
% Results: results/ch06_rounding.txt
clear; clc; addpath(genpath(pwd));
if exist('results/ch06_rounding.txt','file'), delete('results/ch06_rounding.txt'); end
diary('results/ch06_rounding.txt');
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();  prob = define_problem();
budget = 6000;  nRuns = 5;  opts = load_optimizer_settings(budget);
if ~isempty(getenv('MG_SMOKE')), budget = 60; nRuns = 2; opts = load_optimizer_settings(budget); end   % quick syntax check
probC = prob;  probC.round = false;                       % continuous relaxation
fC = @(xv) fitness(xv, TT, par, eco, probC);
[bC, bR] = deal(inf(nRuns,1));  xs = cell(nRuns,1);
parfor r = 1:nRuns
    rng(r);
    bf = BudgetFitness(fC, budget);
    x = pso(@(v) bf.eval(v), probC.lb, probC.ub, opts{1});
    bC(r) = bf.best;                                      % continuous optimum
    bR(r) = fitness(x, TT, par, eco, prob);               % same point, rounded afterwards
    xs{r} = x;
end
S = load('results/case_study_runs.mat', 'bestF');
F1 = S.bestF(1:nRuns, 1);                                 % PSO with rounding inside, seeds 1..5
fprintf('Seed | rounding inside (main.m) | continuous optimum | continuous then rounded | N_wt, N_ch (continuous)\n');
for r = 1:nRuns
    fprintf('%4d | %24.0f | %18.0f | %23.0f | %.2f, %.2f\n', r, F1(r), bC(r), bR(r), xs{r}(2), xs{r}(5));
end
fprintf('Mean | %24.0f | %18.0f | %23.0f\n', mean(F1), mean(bC), mean(bR));
fprintf('Rounded designs violating the LPSP limit (fitness above 1e7 USD): %d of %d\n', sum(bR > 1e7), nRuns);
diary off
disp('=== CH06 ROUNDING DONE ===')
