% ch08_compare.m  -  fair comparison of PSO, GA, GWO and RDA (Chapter 8)
% Same problem, same evaluation budget, same seeds. Takes time: start with
% small values of nRuns and budget to check that everything works.
clear; clc; close all; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
prob = define_problem();
fobj = @(xv) fitness(xv, TT, par, eco, prob);

budget = 6000;  nRuns = 30;
algos = {@pso, @ga_real, @gwo, @rda};
names = {'PSO','GA','GWO','RDA'};
opts  = load_optimizer_settings(budget);

results = zeros(nRuns, numel(algos));
hist    = cell(nRuns, numel(algos));
for a = 1:numel(algos)
    for r = 1:nRuns
        rng(r);
        bf = BudgetFitness(fobj, budget);
        algos{a}(@(x) bf.eval(x), prob.lb, prob.ub, opts{a});
        results(r, a) = bf.best;
        hist{r, a}    = bf.history;
    end
    fprintf('%-4s best %.0f  mean %.0f  std %.0f\n', names{a}, ...
            min(results(:,a)), mean(results(:,a)), std(results(:,a)));
end
if ~exist('results', 'dir'), mkdir('results'); end
save('results/comparison.mat', 'results', 'hist', 'names', 'budget');

% --- Statistics (Statistics and Machine Learning Toolbox)
if exist('ranksum', 'file') == 2
    [~, ref] = min(mean(results));
    for a = setdiff(1:numel(names), ref)
        p = ranksum(results(:,ref), results(:,a));
        fprintf('%s vs %s: p = %.3g\n', names{ref}, names{a}, p);
    end
    [pF, ~, stats] = friedman(results, 1, 'off');
    fprintf('Friedman p = %.3g\n', pF);
    disp(table(names', stats.meanranks', 'VariableNames', {'Algorithm','MeanRank'}));
else
    fprintf('Statistics Toolbox not found: skipping Wilcoxon and Friedman tests.\n');
end

% --- Mean convergence against evaluations
figure('Color','w'); hold on;
for a = 1:numel(algos)
    H = nan(nRuns, budget);
    for r = 1:nRuns
        h = hist{r,a};  H(r,1:numel(h)) = h;
    end
    plot(1:budget, mean(H, 1, 'omitnan'), 'LineWidth', 1.3);
end
legend(names); grid on; xlabel('Function evaluations'); ylabel('Mean best fitness');
title(sprintf('Mean convergence over %d runs', nRuns));
