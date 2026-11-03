% ch09_penalty.m  -  is the penalty factor large enough? (Sections 6.3 and 9.6)
% Reruns PSO with several values of lambda and checks every best design
% WITHOUT the penalty terms. Results: results/ch09_penalty.txt
clear; clc; addpath(genpath(pwd));
if exist('results/ch09_penalty.txt','file'), delete('results/ch09_penalty.txt'); end
diary('results/ch09_penalty.txt');
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();  prob0 = define_problem();
budget = 6000;  nRuns = 3;  opts = load_optimizer_settings(budget);
lambdas = [1e6 1e7 1e8 1e9 1e10];
if ~isempty(getenv('MG_SMOKE')), budget = 60; nRuns = 2; lambdas = lambdas(1:2); opts = load_optimizer_settings(budget); end   % quick syntax check
fprintf('lambda  | best fitness | NPC (USD) | LPSP (%%) | violation (pp) | penalty (USD)\n');
for L = lambdas
    prob = prob0;  prob.lambda = L;
    fobj = @(xv) fitness(xv, TT, par, eco, prob);
    bF = inf(nRuns,1);  bX = cell(nRuns,1);
    parfor r = 1:nRuns
        rng(r);
        bf = BudgetFitness(fobj, budget);
        x = pso(@(v) bf.eval(v), prob.lb, prob.ub, opts{1});
        bF(r) = bf.best;  bX{r} = x;
    end
    [~, k] = min(bF);
    [Fb, res] = fitness(bX{k}, TT, par, eco, prob);
    viol = max(0, res.LPSP - prob.LPSP_max);
    fprintf('%7.0e | %12.0f | %9.0f | %8.4f | %14.4f | %12.0f\n', L, Fb, res.NPC, 100*res.LPSP, 100*viol, Fb - res.NPC);
end
diary off
disp('=== CH09 PENALTY DONE ===')
