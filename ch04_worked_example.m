% ch04_worked_example.m  -  hour-by-hour power balance of the final design
% on one representative day (Section 4.6), with every converter loss.
% Run after main.m. Results: results/ch04_worked_day.txt
clear; clc; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();  prob = define_problem();
S = load('results/case_study_runs.mat', 'bestF', 'bestX');
[~, k] = min(S.bestF(:));  xv = S.bestX{k};
r = design_result(xv, TT, par, eco, prob);
par.bat.Pmax = r.P_bat;
TTc = TT;  TTc.P_ev = min(TT.P_ev, r.N_ch * par.P_charger);   % as in fitness.m
out = simulate_year(r.x, TTc, par);  s = out.series;  e = par.eta_ilc;

d  = 196;                                   % 15 July (the day used in Chapter 10)
h  = (d-1)*24 + (1:24);
Ppv_dc = pv_model(TT.G(h), TT.Ta(h), r.x.P_pv, par.pv);
Ppv_ac = par.eta_mppt * e * Ppv_dc;
Pwt    = wind_model(TT.v_hub(h), r.x.N_wt, par.wt);
Pb     = s.P_bat(h);                        % DC, > 0 charging
Pb_ac  = (Pb > 0).*Pb/e + (Pb < 0).*Pb*e;   % seen from the AC bus
L_ilc  = (Pb > 0).*(Pb/e - Pb) + (Pb < 0).*(-Pb - (-Pb)*e);
resid  = Ppv_ac + Pwt - Pb_ac - TTc.P_load(h) - TTc.P_ev(h) - s.P_dump(h) + s.P_unmet(h);

fid = fopen('results/ch04_worked_day.txt', 'w');
fprintf(fid, 'Design: PV %.1f kW, %d WT, battery %.1f kWh / %.1f kW, %d chargers. Day %d (15 July)\n', ...
        r.x.P_pv, r.x.N_wt, r.x.E_bat, r.P_bat, r.N_ch, d);
fprintf(fid, 'h  | PV DC | PV AC | load | EV   | P_bat DC | bat AC | ILC loss | curtail | unmet | SOC end | residual\n');
for j = 1:24
    fprintf(fid, '%2d | %5.1f | %5.1f | %4.1f | %4.1f | %8.1f | %6.1f | %8.2f | %7.1f | %5.1f | %7.3f | %.1e\n', ...
        j-1, Ppv_dc(j), Ppv_ac(j), TTc.P_load(h(j)), TTc.P_ev(h(j)), Pb(j), Pb_ac(j), L_ilc(j), ...
        s.P_dump(h(j)), s.P_unmet(h(j)), s.SOC(h(j)), resid(j));
end
fprintf(fid, 'Day totals (kWh): PV DC %.0f, PV AC %.0f, PV-path loss %.0f, load %.0f, EV %.0f, battery in (DC) %.0f, out (DC) %.0f, ILC loss %.1f, curtailed %.0f, unmet %.1f, max |residual| %.1e\n', ...
        sum(Ppv_dc), sum(Ppv_ac), sum(Ppv_dc - Ppv_ac), sum(TTc.P_load(h)), sum(TTc.P_ev(h)), ...
        sum(max(Pb,0)), sum(max(-Pb,0)), sum(L_ilc), sum(s.P_dump(h)), sum(s.P_unmet(h)), max(abs(resid)));
fclose(fid);  type('results/ch04_worked_day.txt');
