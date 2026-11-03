% ch09_pareto.m  -  cost-reliability Pareto front by the epsilon-constraint
% method (Section 8.6): one PSO run per LPSP limit. Saves results/pareto.mat
clear; clc; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
prob0 = define_problem();
lims  = [0.001 0.0025 0.005 0.01 0.02 0.05];        % LPSP limits
opt   = struct('N',30, 'maxIt',200, 'wmax',0.9, 'wmin',0.4, 'c1',2, 'c2',2, 'vfrac',0.15);
nL = numel(lims);
NPC = zeros(nL,1);  LPSP = zeros(nL,1);  X = zeros(nL, numel(prob0.lb));
parfor k = 1:nL
    rng(k);
    prob = prob0;  prob.LPSP_max = lims(k);
    fobj = @(xv) fitness(xv, TT, par, eco, prob);
    xb = pso(fobj, prob.lb, prob.ub, opt);
    [~, r] = fitness(xb, TT, par, eco, prob);
    NPC(k) = r.NPC;  LPSP(k) = r.LPSP;  X(k,:) = xb;
end
save('results/pareto.mat', 'lims', 'NPC', 'LPSP', 'X');
fprintf('Pareto front (epsilon-constraint):\n');
for k = 1:nL
    fprintf('  LPSP <= %5.2f %%: NPC %9.0f USD, LPSP %5.2f %%, PV %6.1f kW, BAT %7.1f kWh\n', ...
        100*lims(k), NPC(k), 100*LPSP(k), X(k,1), X(k,3));
end
