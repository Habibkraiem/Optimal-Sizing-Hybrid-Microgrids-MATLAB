% ch07_size_microgrid.m  -  size the microgrid with PSO (Chapter 7)
clear; clc; close all; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
prob = define_problem();
fobj = @(xv) fitness(xv, TT, par, eco, prob);

opt = struct('N',30, 'maxIt',200, 'wmax',0.9, 'wmin',0.4, ...
             'c1',2, 'c2',2, 'vfrac',0.15);
rng(1);
tic;
[xbest, Fbest, curve] = pso(fobj, prob.lb, prob.ub, opt);
fprintf('Run time: %.1f min\n', toc/60);

[~, res] = fitness(xbest, TT, par, eco, prob);   % full results of the best design
fprintf('PV      : %6.1f kW\n',  res.x.P_pv);
fprintf('Wind    : %6d turbines\n', res.x.N_wt);
fprintf('Battery : %6.1f kWh / %5.1f kW\n', res.x.E_bat, res.P_bat);
fprintf('Chargers: %6d\n', res.N_ch);
fprintf('NPC     : %10.0f USD\n', res.NPC);
fprintf('LCOE    : %8.3f USD/kWh\n', res.LCOE);
fprintf('LPSP    : %8.2f %%\n', 100*res.LPSP);

% Warn if a size sits on a bound (Chapter 6)
onb = abs(xbest - prob.lb) < 1e-6 | abs(xbest - prob.ub) < 1e-6;
if any(onb)
    fprintf(['Check: on a bound -> %s\n' ...
             '(a size of zero is fine; an upper bound means: widen it and rerun)\n'], ...
            strjoin(prob.names(onb), ', '));
end

plot(curve, 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Best fitness'); title('PSO convergence: microgrid sizing');
