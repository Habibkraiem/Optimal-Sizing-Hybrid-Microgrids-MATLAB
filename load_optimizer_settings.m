function opts = load_optimizer_settings(budget)
% LOAD_OPTIMIZER_SETTINGS  One settings struct per algorithm, in the order
% {PSO, GA, GWO, RDA}, sized so that each algorithm uses about the same
% number of fitness evaluations (budget). Chapter 8, Section 8.4.
if nargin < 1, budget = 6000; end
N = 30;
it_pso = max(1, floor((budget - N) / N));         % N evaluations per iteration
it_ga  = max(1, floor((budget - N) / (N - 1)));   % elite not re-evaluated
it_gwo = it_pso;
opts = { ...
  struct('N',N, 'maxIt',it_pso, 'wmax',0.9, 'wmin',0.4, 'c1',2, 'c2',2, 'vfrac',0.15), ...
  struct('N',N, 'maxIt',it_ga,  'pc',0.85, 'pm',0.2, 'sigma',0.1), ...
  struct('N',N, 'maxIt',it_gwo), ...
  struct('N',N, 'maxIt',budget, 'nMale',6, 'gamma',0.6, 'alpha',0.85, 'beta',0.4, 'step',0.1) };
% RDA has no iteration-dependent schedule; its run is stopped by the
% BudgetFitness counter (extra iterations then cost almost nothing).
end
