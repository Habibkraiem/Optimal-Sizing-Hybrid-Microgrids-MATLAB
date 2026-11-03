% ch07_multiple_runs.m  -  30 independent PSO runs and their statistics (Chapter 7)
clear; clc; close all; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
prob = define_problem();
fobj = @(xv) fitness(xv, TT, par, eco, prob);
opt  = struct('N',30, 'maxIt',200, 'wmax',0.9, 'wmin',0.4, 'c1',2, 'c2',2, 'vfrac',0.15);
if ~exist('results', 'dir'), mkdir('results'); end

nRuns = 30;
best  = zeros(nRuns, 1);
X     = zeros(nRuns, numel(prob.lb));
curves = zeros(opt.maxIt, nRuns);
for r = 1:nRuns
    rng(r);                                    % a different, reproducible seed
    [X(r,:), best(r), curves(:,r)] = pso(fobj, prob.lb, prob.ub, opt);
    fprintf('Run %2d: F = %.0f\n', r, best(r));
end

fprintf('\nBest  : %.0f\n', min(best));
fprintf('Mean  : %.0f\n', mean(best));
fprintf('Worst : %.0f\n', max(best));
fprintf('Std   : %.0f\n', std(best));
save('results/pso_runs.mat', 'best', 'X', 'curves', 'opt');

figure('Color','w');
plot(mean(curves, 2), 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Mean best fitness');
title(sprintf('PSO: mean convergence over %d runs', nRuns));
