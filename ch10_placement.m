% ch10_placement.m  -  joint sizing and placement of PV, wind, battery and an
% EV charging station on the IEEE 33-bus feeder (Chapter 10).
% Results: results/ch10_values.txt, results/ch10_runs.mat, results/figures/fig10_*.png
clear; clc; close all; addpath(genpath(pwd));
if ~exist('results/figures', 'dir'), mkdir('results/figures'); end
if exist('results/ch10_values.txt','file'), delete('results/ch10_values.txt'); end
diary('results/ch10_values.txt');

load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
par.grid = true;  par.P_imp_max = 1e5;  par.P_exp_max = 1e5;   % substation = grid
prob = define_problem();
[br, Pd, Qd, Vb] = load_ieee33();
nw.br = br;  nw.Pd_peak = Pd;  nw.Qd_peak = Qd;
nw.net = struct('Vbase_kV',Vb, 'Sbase_MVA',1, 'tol',1e-8, 'maxIt',100);
nw.cand = 2:33;  nw.Vmin = 0.90;  nw.Vmax = 1.05;  nw.w = [1 1 1]/3;

% --- Representative days: the 15th of January, April, July and October
t = TT.Properties.RowTimes;  yr = year(t(1));
days = datetime(yr, [1 4 7 10], 15, 'TimeZone', t.TimeZone);
idx = [];
for d = days, idx = [idx; find(t >= d, 1) + (0:23)']; end %#ok<AGROW>
nw.rep.idx = idx;  nw.rep.w = (8760/numel(idx)) * ones(size(idx));

% --- Base case (no DER, no EV station) and references
E0 = 0;  VD0 = 0;
for k = 1:numel(idx)
    sL = TT.P_load(idx(k))/max(TT.P_load);
    [V, Pl] = bfs_loadflow(br, Pd*sL, Qd*sL, nw.net);
    E0 = E0 + nw.rep.w(k)*Pl;  VD0 = VD0 + nw.rep.w(k)*sum((abs(V)-1).^2);
end
[V0, Pl0] = bfs_loadflow(br, Pd, Qd, nw.net);  [Vmin0, b0] = min(abs(V0));
x0 = zeros(1,9);  x0(5) = 10;  x0(6:9) = 1;           % reference: 10 chargers, no DER
[~, r0] = fitness([x0(1:5)], TT, par, eco, prob);
nw.ref = struct('NPC', r0.NPC, 'E_loss', E0, 'VD', VD0);
fprintf('Base case: peak losses %.1f kW, Vmin %.4f p.u. at bus %d, annual losses %.0f MWh\n', ...
        Pl0, Vmin0, b0, E0/1000);

% --- Optimization: PSO and RDA, 10 runs each, equal budget
lb = [prob.lb, 0.51*ones(1,4)];  ub = [prob.ub, (numel(nw.cand)+0.49)*ones(1,4)];
fobj = @(xv) fitness_placement(xv, TT, par, eco, prob, nw);
budget = 3000;  nRuns = 10;
opts = load_optimizer_settings(budget);
algos = {@pso, @rda};  names = {'PSO','RDA'};  oi = [1 4];
bestF = inf(nRuns, 2);  bestX = cell(nRuns, 2);
tic;
for a = 1:2
    parfor r = 1:nRuns
        rng(r);
        bf = BudgetFitness(fobj, budget);
        x = algos{a}(@(v) bf.eval(v), lb, ub, opts{oi(a)});
        bestF(r,a) = bf.best;  bestX{r,a} = x;
    end
    fprintf('%s done: best %.4f, mean %.4f, std %.4f\n', names{a}, min(bestF(:,a)), mean(bestF(:,a)), std(bestF(:,a)));
end
fprintf('Run time: %.1f min\n', toc/60);
save('results/ch10_runs.mat', 'bestF', 'bestX', 'names', 'nw', 'lb', 'ub');

% --- Report the best design of each algorithm at the peak hour
tp = find(TT.P_load == max(TT.P_load), 1);
for a = 1:2
    [~, r] = min(bestF(:,a));  xv = bestX{r,a};
    [~, res] = fitness_placement(xv, TT, par, eco, prob, nw);
    b = res.bus;  s = res.out.series;
    Ppv = par.eta_mppt*par.eta_ilc*pv_model(TT.G(tp), TT.Ta(tp), res.x.P_pv, par.pv);
    Pwt = wind_model(TT.v_hub(tp), res.x.N_wt, par.wt);
    Pev = min(TT.P_ev(tp), res.N_ch*par.P_charger);
    [P, Q] = apply_der(Pd, Qd, b, struct('pv',Ppv,'wt',Pwt,'bat',s.P_bat(tp),'ev',Pev));
    [V, Pl] = bfs_loadflow(br, P, Q, nw.net);  [vm, bm] = min(abs(V));
    fprintf(['%s best: PV %.1f kW @ bus %d | WT %d @ bus %d | BESS %.1f kWh / %.1f kW @ bus %d | ' ...
             'EVCS %d x 7 kW @ bus %d\n'], names{a}, res.x.P_pv, b.pv, res.x.N_wt, b.wt, ...
             res.x.E_bat, xv(4), b.bat, res.N_ch, b.ev);
    fprintf('   NPC %.0f USD | annual losses %.0f MWh (%.1f %% less than base) | peak-hour losses %.1f kW | Vmin %.4f @ bus %d\n', ...
             res.NPC, res.E_loss/1000, 100*(1 - res.E_loss/E0), Pl, vm, bm);
    if a == 1, Vbest = abs(V); best = res; xbest = xv; end
end

% --- Figure 10.2: voltage profile at the peak hour
evb = best.bus.ev;  Pe = Pd;  Pe(evb) = Pe(evb) + best.N_ch*par.P_charger;
Vev = abs(bfs_loadflow(br, Pe, Qd, nw.net));
f = figure('Color','w','Units','centimeters','Position',[2 2 16 9]); hold on;
plot(1:33, abs(V0), '-o',  'Color',[0.32 0.32 0.31], 'MarkerSize',4);
plot(1:33, Vev,     '--s', 'Color',[235 104 52]/255, 'MarkerSize',4);
plot(1:33, Vbest,   '-^',  'Color',[42 120 214]/255, 'MarkerSize',4, 'MarkerFaceColor',[42 120 214]/255);
yline(0.95, ':', 'Color',[0.5 0.5 0.5]);
grid on; box off; xlim([1 33]); xlabel('Bus'); ylabel('Voltage (p.u.)');
legend('Base case','EV station only (full power)','Optimal DER placement (PSO)','Location','southwest','Box','off');
title('Voltage profile at the peak-load hour');
exportgraphics(f, 'results/figures/fig10_2_voltage.png', 'Resolution', 300);

% --- Figure 10.3: hourly losses on the representative July day, with and without DER
d7 = idx(49:72);  L0 = zeros(24,1);  L1 = zeros(24,1);
Ppv = par.eta_mppt*par.eta_ilc*pv_model(TT.G, TT.Ta, best.x.P_pv, par.pv);
Pwt = wind_model(TT.v_hub, best.x.N_wt, par.wt);  s = best.out.series;
for h = 1:24
    tt = d7(h);  sL = TT.P_load(tt)/max(TT.P_load);
    [~, L0(h)] = bfs_loadflow(br, Pd*sL, Qd*sL, nw.net);
    inj = struct('pv',Ppv(tt),'wt',Pwt(tt),'bat',s.P_bat(tt),'ev',min(TT.P_ev(tt), best.N_ch*par.P_charger));
    [P, Q] = apply_der(Pd*sL, Qd*sL, best.bus, inj);
    [~, L1(h)] = bfs_loadflow(br, P, Q, nw.net);
end
f = figure('Color','w','Units','centimeters','Position',[2 2 16 8]); hold on;
plot(0:23, L0, '--', 'Color',[0.32 0.32 0.31], 'LineWidth',1.4);
plot(0:23, L1, '-',  'Color',[42 120 214]/255, 'LineWidth',1.4);
grid on; box off; xlim([0 23]); xlabel('Hour'); ylabel('Active power losses (kW)');
legend('Without DER','With optimal DER','Location','northwest','Box','off');
title('Feeder losses on a representative July day');
exportgraphics(f, 'results/figures/fig10_3_losses.png', 'Resolution', 300);
diary off
disp('=== CH10 DONE ===')
