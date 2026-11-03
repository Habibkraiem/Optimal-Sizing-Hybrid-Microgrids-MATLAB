% ch08_benchmark.m  -  the four optimizers on two benchmark functions with a
% known optimum (f = 0 at x = 0), equal budget, 20 runs (Section 8.4).
% Results: results/ch08_benchmark.txt
clear; clc; addpath(genpath(pwd));
if exist('results/ch08_benchmark.txt','file'), delete('results/ch08_benchmark.txt'); end
diary('results/ch08_benchmark.txt');
D = 10;  budget = 6000;  nRuns = 20;
if ~isempty(getenv('MG_SMOKE')), budget = 300; nRuns = 2; end   % quick syntax check
fun = {@(x) sum(x.^2), @(x) 10*numel(x) + sum(x.^2 - 10*cos(2*pi*x))};
fname = {'Sphere', 'Rastrigin'};  lim = [100 5.12];
algos = {@pso, @ga_real, @gwo, @rda};  names = {'PSO','GA','GWO','RDA'};
opts = load_optimizer_settings(budget);
fprintf('D = %d, budget %d evaluations, %d runs, seeds 1..%d\n', D, budget, nRuns, nRuns);
for f = 1:2
    lb = -lim(f)*ones(1,D);  ub = lim(f)*ones(1,D);
    fprintf('\n%s (optimum 0)\n%-4s | %10s | %10s | %10s | %10s\n', fname{f}, 'Alg', 'best', 'median', 'mean', 'worst');
    for a = 1:4
        v = zeros(nRuns,1);
        for r = 1:nRuns
            rng(r);
            bf = BudgetFitness(fun{f}, budget);
            algos{a}(@(z) bf.eval(z), lb, ub, opts{a});
            v(r) = bf.best;
        end
        fprintf('%-4s | %10.3g | %10.3g | %10.3g | %10.3g\n', names{a}, min(v), median(v), mean(v), max(v));
    end
end
diary off
disp('=== CH08 BENCHMARK DONE ===')
