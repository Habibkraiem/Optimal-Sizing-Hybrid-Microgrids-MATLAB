% ch10_fullyear.m  -  validation of Chapter 10 (Section 10.7):
% (1) base case against the published benchmark values,
% (2) representative days against a full-year (8,760 h) load flow,
% for the base case and the four designs A-D of ch10_weights.m.
% Run after ch10_placement.m and ch10_weights.m. Results: results/ch10_fullyear.txt
clear; clc; addpath(genpath(pwd));
if exist('results/ch10_fullyear.txt','file'), delete('results/ch10_fullyear.txt'); end
diary('results/ch10_fullyear.txt');
S = load('results/ch10_runs.mat');  W = load('results/ch10_weights.mat');
nw = S.nw;  load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
par.grid = true;  par.P_imp_max = 1e5;  par.P_exp_max = 1e5;
prob = define_problem();
[br, Pd, Qd] = load_ieee33();

% --- (1) Base case at peak load
[V0, Pl0] = bfs_loadflow(br, Pd, Qd, nw.net);  [Vm0, b0] = min(abs(V0));
ref = [202.67 0.9131 18];                        % widely reported values for this feeder
fprintf('Base case (peak load)  | reference | this code | relative error\n');
fprintf('Active losses (kW)     | %9.2f | %9.2f | %.2e\n', ref(1), Pl0, (Pl0-ref(1))/ref(1));
fprintf('Minimum voltage (p.u.) | %9.4f | %9.4f | %.2e\n', ref(2), Vm0, (Vm0-ref(2))/ref(2));
fprintf('Bus of minimum voltage | %9d | %9d |\n', ref(3), b0);
fprintf('Max voltage deviation  | %9s | %9.4f |\n', '-', max(abs(abs(V0)-1)));
fprintf('Sum of (|V|-1)^2       | %9s | %9.5f |\n\n', '-', sum((abs(V0)-1).^2));

% --- (2) Full year vs representative days
N = height(TT);  sL = TT.P_load / max(TT.P_load);
names = {'Base', 'A', 'B', 'C', 'D'};
fprintf('Design | E_loss rep. (MWh) | E_loss year (MWh) | diff %% | VD rep. | VD year | diff %% | Vmin year (bus, hour) | Vmax year | h with V<0.95 | import / export (MWh)\n');
for j = 0:numel(W.sol)
    if j == 0
        bus = struct('pv',2,'wt',2,'bat',2,'ev',2);  inj0 = true;
        Erep = nw.ref.E_loss;  VDrep = nw.ref.VD;  Eimp = NaN;  Eexp = NaN;
    else
        nwj = nw;  nwj.w = [W.w1(j), (1-W.w1(j))/2, (1-W.w1(j))/2];
        [~, res] = fitness_placement(W.sol{j}, TT, par, eco, prob, nwj);
        bus = res.bus;  inj0 = false;  Erep = res.E_loss;  VDrep = res.VD;
        Eimp = res.out.E_imp/1e3;  Eexp = res.out.E_exp/1e3;
        s = res.out.series;
        Ppv = par.eta_mppt*par.eta_ilc*pv_model(TT.G, TT.Ta, res.x.P_pv, par.pv);
        Pwt = wind_model(TT.v_hub, res.x.N_wt, par.wt);
        Pev = min(TT.P_ev, res.N_ch*par.P_charger);
    end
    E = 0;  VD = 0;  vmin = inf;  vmax = 0;  nlow = 0;  wh = 0;  wb = 0;
    for t = 1:N
        P = Pd*sL(t);  Q = Qd*sL(t);
        if ~inj0
            [P, Q] = apply_der(P, Q, bus, struct('pv',Ppv(t),'wt',Pwt(t),'bat',s.P_bat(t),'ev',Pev(t)));
        end
        [V, Pl] = bfs_loadflow(br, P, Q, nw.net);  Vm = abs(V);
        E = E + Pl;  VD = VD + sum((Vm-1).^2);
        [m, ib] = min(Vm);  if m < vmin, vmin = m; wh = t; wb = ib; end
        vmax = max(vmax, max(Vm));  nlow = nlow + any(Vm < 0.95);
    end
    fprintf('%-6s | %17.1f | %17.1f | %6.2f | %7.1f | %7.1f | %6.2f | %.4f (bus %d, h %d) | %9.4f | %13d | %.1f / %.1f\n', ...
        names{j+1}, Erep/1e3, E/1e3, 100*(Erep-E)/E, VDrep, VD, 100*(VDrep-VD)/VD, vmin, wb, wh, vmax, nlow, Eimp, Eexp);
end
diary off
disp('=== CH10 FULL YEAR DONE ===')
