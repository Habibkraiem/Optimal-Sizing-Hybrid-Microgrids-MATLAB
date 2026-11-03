% ch10_weights.m  -  effect of the cost weight on DER sizing and placement
% (Chapter 10, Section 10.6.2). Run ch10_placement.m first.
% PSO only (it had zero spread in ch10_placement), 6 runs per weight set.
% Results: results/ch10_weights.txt, results/ch10_weights.mat,
%          results/figures/fig10_4_voltage_noon.png, fig10_5_losses_weights.png
clear; clc; close all; addpath(genpath(pwd));
if exist('results/ch10_weights.txt','file'), delete('results/ch10_weights.txt'); end
diary('results/ch10_weights.txt');

S = load('results/ch10_runs.mat');                 % network data and scenario A
nw = S.nw;  lb = S.lb;  ub = S.ub;
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
par.grid = true;  par.P_imp_max = 1e5;  par.P_exp_max = 1e5;
prob = define_problem();
[br, Pd, Qd] = load_ieee33();

w1 = [1/3 0.2 0.1 0];                              % weight on NPC; rest split equally
budget = 3000;  nRuns = 6;  opts = load_optimizer_settings(budget);
sol = cell(1, numel(w1));
[~, rA] = min(S.bestF(:,1));  sol{1} = S.bestX{rA,1};   % w1 = 1/3 from ch10_placement
tic;
for j = 2:numel(w1)
    nwj = nw;  nwj.w = [w1(j), (1-w1(j))/2, (1-w1(j))/2];
    fobj = @(xv) fitness_placement(xv, TT, par, eco, prob, nwj);
    bF = inf(nRuns,1);  bX = cell(nRuns,1);
    parfor r = 1:nRuns
        rng(r);
        bf = BudgetFitness(fobj, budget);
        x = pso(@(v) bf.eval(v), lb, ub, opts{1});
        bF(r) = bf.best;  bX{r} = x;
    end
    [~, k] = min(bF);  sol{j} = bX{k};
    fprintf('w_NPC = %.2f done: best %.4f, mean %.4f, std %.4f\n', w1(j), min(bF), mean(bF), std(bF));
end
fprintf('Run time: %.1f min\n\n', toc/60);

% --- Hours used in the report
t  = TT.Properties.RowTimes;
d7 = nw.rep.idx(49:72);                            % 15 July, 24 hours
tn = d7(13);                                       % 12:00 on 15 July
tp = find(TT.P_load == max(TT.P_load), 1);         % peak-load hour

V0n = abs(bfs_loadflow(br, Pd*TT.P_load(tn)/max(TT.P_load), Qd*TT.P_load(tn)/max(TT.P_load), nw.net));
Vn  = zeros(33, numel(w1));  Lj = zeros(24, numel(w1));  L0 = zeros(24,1);
for h = 1:24
    sL = TT.P_load(d7(h))/max(TT.P_load);
    [~, L0(h)] = bfs_loadflow(br, Pd*sL, Qd*sL, nw.net);
end
fprintf('%-6s | %-7s %-6s | %-9s %-6s | %-5s %-6s | %-6s | %-9s | %-7s | %-11s | %-11s\n', ...
        'w_NPC','PV kW','bus','BESS kWh','bus','N_ch','bus','WT','NPC USD','dLoss %','Vmin noon','Vmax noon');
for j = 1:numel(w1)
    nwj = nw;  nwj.w = [w1(j), (1-w1(j))/2, (1-w1(j))/2];
    [~, res] = fitness_placement(sol{j}, TT, par, eco, prob, nwj);
    s = res.out.series;  b = res.bus;
    Ppv = par.eta_mppt*par.eta_ilc*pv_model(TT.G, TT.Ta, res.x.P_pv, par.pv);
    Pwt = wind_model(TT.v_hub, res.x.N_wt, par.wt);
    Pev = min(TT.P_ev, res.N_ch*par.P_charger);
    inj = @(tt) struct('pv',Ppv(tt),'wt',Pwt(tt),'bat',s.P_bat(tt),'ev',Pev(tt));
    sL = TT.P_load(tn)/max(TT.P_load);
    [P, Q] = apply_der(Pd*sL, Qd*sL, b, inj(tn));
    Vn(:,j) = abs(bfs_loadflow(br, P, Q, nw.net));
    for h = 1:24
        sL = TT.P_load(d7(h))/max(TT.P_load);
        [P, Q] = apply_der(Pd*sL, Qd*sL, b, inj(d7(h)));
        [~, Lj(h,j)] = bfs_loadflow(br, P, Q, nw.net);
    end
    fprintf('%-6.2f | %-7.1f %-6d | %-9.1f %-6d | %-5d %-6d | %-6d | %-9.0f | %-7.1f | %-11.4f | %-11.4f\n', ...
            w1(j), res.x.P_pv, b.pv, res.x.E_bat, b.bat, res.N_ch, b.ev, res.x.N_wt, res.NPC, ...
            100*(1 - res.E_loss/nw.ref.E_loss), min(Vn(:,j)), max(Vn(:,j)));
    fprintf('         battery power %.1f kW | LPSP %.2f %% | VD %.1f %% of base | July-day losses %.0f kWh (base %.0f)\n', ...
            sol{j}(4), 100*res.LPSP, 100*res.VD/nw.ref.VD, sum(Lj(:,j)), sum(L0));
end
fprintf('Base case at 12:00 on 15 July: Vmin %.4f p.u.\n', min(V0n));
save('results/ch10_weights.mat', 'w1', 'sol', 'Vn', 'V0n', 'Lj', 'L0');

% --- Figure 10.4: voltage profile at noon for each weight
col = [0.32 0.32 0.31; 42 120 214; 235 104 52; 27 175 122; 237 161 0];  col(2:end,:) = col(2:end,:)/255;
mk  = {'o','^','s','d','v'};
f = figure('Color','w','Units','centimeters','Position',[2 2 16 9]); hold on;
plot(1:33, V0n, '--o', 'Color', col(1,:), 'MarkerSize', 4);
lg = {'Base case (no DER)'};
for j = 1:numel(w1)
    plot(1:33, Vn(:,j), ['-' mk{j+1}], 'Color', col(j+1,:), 'MarkerSize', 4, 'MarkerFaceColor', col(j+1,:));
    lg{end+1} = sprintf('w_{NPC} = %.2f', w1(j)); %#ok<SAGROW>
end
yline(0.95, ':', 'Color', [0.5 0.5 0.5]);
grid on; box off; xlim([1 33]); xlabel('Bus'); ylabel('Voltage (p.u.)');
legend(lg, 'Location', 'southwest', 'Box', 'off');
title('Voltage profile at 12:00 on 15 July');
exportgraphics(f, 'results/figures/fig10_4_voltage_noon.png', 'Resolution', 300);

% --- Figure 10.5: losses on the July day for each weight
f = figure('Color','w','Units','centimeters','Position',[2 2 16 8]); hold on;
plot(0:23, L0, '--', 'Color', col(1,:), 'LineWidth', 1.4);
for j = 1:numel(w1), plot(0:23, Lj(:,j), '-', 'Color', col(j+1,:), 'LineWidth', 1.4); end
grid on; box off; xlim([0 23]); xlabel('Hour'); ylabel('Active power losses (kW)');
legend(lg, 'Location', 'northwest', 'Box', 'off');
title('Feeder losses on 15 July for each cost weight');
exportgraphics(f, 'results/figures/fig10_5_losses_weights.png', 'Resolution', 300);
diary off
disp('=== CH10 WEIGHTS DONE ===')
