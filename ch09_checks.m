% ch09_checks.m  -  independent checks of the optimal design (Section 9.6):
% feasibility without penalties, annual energy balance with losses,
% vehicle-level charger check, and battery life / replacement schedule.
% Run after main.m. Results: results/ch09_checks.txt
clear; clc; addpath(genpath(pwd));
if exist('results/ch09_checks.txt','file'), delete('results/ch09_checks.txt'); end
diary('results/ch09_checks.txt');
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();  prob = define_problem();
S = load('results/case_study_runs.mat', 'bestF', 'bestX');
[~, k] = min(S.bestF(:));  xv = S.bestX{k};
[F, res] = fitness(xv, TT, par, eco, prob);

fprintf('--- 1. Design and bounds\n');
nm = prob.names;
for j = 1:numel(xv)
    fprintf('  %-12s raw %9.3f  -> used %9.3f   bounds [%g, %g]%s\n', nm{j}, xv(j), ...
        [res.x.P_pv res.x.N_wt res.x.E_bat res.P_bat res.N_ch]*(1:5==j)', prob.lb(j), prob.ub(j), ...
        repmat('  <- ON A BOUND', 1, double(abs(xv(j)-prob.ub(j)) < 1e-6 || abs(xv(j)-prob.lb(j)) < 1e-6)));
end
fprintf('  E/P ratio of the battery: %.1f h\n', res.x.E_bat / max(res.P_bat, eps));

fprintf('--- 2. Constraints checked on the raw results (no penalty terms)\n');
fprintf('  LPSP = %.5f %% (limit %.2f %%) -> %s\n', 100*res.LPSP, 100*prob.LPSP_max, ...
        ifelse(res.LPSP <= prob.LPSP_max + 1e-9, 'satisfied', 'VIOLATED'));
fprintf('  Penalty part of the fitness: %.3g USD (fitness %.0f, NPC %.0f)\n', F - res.NPC, F, res.NPC);
s = res.out.series;
fprintf('  SOC range over the year: %.4f to %.4f (window %.2f to %.2f)\n', min(s.SOC), max(s.SOC), par.bat.SOCmin, par.bat.SOCmax);
fprintf('  |P_bat| max: %.1f kW (rating %.1f kW)\n', max(abs(s.P_bat)), res.P_bat);
fprintf('  Grid import / export: %.0f / %.0f kWh (islanded design)\n', sum(s.P_imp), sum(s.P_exp));
fprintf('  Refused EV energy (aggregate charger limit): %.0f kWh\n', res.E_ev_lost);

fprintf('--- 3. Annual energy balance (kWh)\n');
TTc = TT;  TTc.P_ev = min(TT.P_ev, res.N_ch*par.P_charger);
parc = par;  parc.bat.Pmax = res.P_bat;
A = energy_audit(res.x, TTc, parc, res.out);
fprintf('  PV at array (DC) %10.0f | PV at AC bus %10.0f | wind %10.0f | import %8.0f\n', A.E_pv_dc, A.E_pv_ac, A.E_wt, A.E_imp);
fprintf('  Demand served    %10.0f | unserved %8.0f | export %8.0f | curtailed %10.0f\n', A.E_served, A.E_unmet, A.E_exp, A.E_dump);
fprintf('  Battery in (DC)  %10.0f | out (DC) %8.0f | change in storage %8.1f\n', A.E_ch_dc, A.E_dis_dc, A.dE_store);
fprintf('  Losses: PV path %8.0f | ILC battery path %8.0f | battery %8.0f | self-discharge %.0f\n', A.L_pv, A.L_ilc, A.L_bat, A.L_sd);
fprintf('  Residuals: AC bus %.2e | battery %.2e | full balance %.2e kWh\n', A.residual_ac, A.residual_bat, A.residual_full);

fprintf('--- 4. Battery ageing and replacements\n');
Nuse = (par.bat.SOCmax - par.bat.SOCmin) * res.x.E_bat;
fprintf('  Usable capacity %.1f kWh (SOC %.2f-%.2f); discharge throughput %.0f kWh/yr\n', Nuse, par.bat.SOCmin, par.bat.SOCmax, A.E_dis_dc);
fprintf('  Equivalent full cycles N_eq = %.1f /yr -> cycle life %.1f yr; calendar life %d yr\n', ...
        res.out.N_eq, eco.bat_cycle_life/res.out.N_eq, eco.bat_cal_life);
L = res.life_bat;  yrs = L:L:eco.N-1e-9;
fprintf('  Life used %.1f yr -> replacements in years: %s\n', L, mat2str(round(yrs,1)));
fprintf('  Present value of each replacement (per kWh): %s USD\n', mat2str(round(eco.bat.rep./(1+eco.i).^yrs, 1)));
remL = L - (eco.N - numel(yrs)*L);
fprintf('  Salvage at year %d: %.1f of %.1f years left\n', eco.N, remL, L);
Nadd = 1 / (1/eco.bat_cal_life + res.out.N_eq/eco.bat_cycle_life);
fprintf('  Alternative (additive ageing, 1/L = 1/L_cal + N_eq/N_cyc): life %.1f yr\n', Nadd);
dNPC = component_npc(res.x.E_bat, eco.bat, Nadd, eco.i, eco.N) - component_npc(res.x.E_bat, eco.bat, L, eco.i, eco.N);
fprintf('  NPC of the same design with additive ageing: %.0f USD (+%.0f USD, +%.1f %%)\n', res.NPC + dNPC, dNPC, 100*dNPC/res.NPC);

fprintf('--- 5. Vehicle-level charger check (%d chargers)\n', res.N_ch);
Sess = readtable('results/ev_sessions.csv');
for md = {'stay','move'}
    R = ev_queue_check(Sess, res.N_ch, par.P_charger, md{1});
    fprintf('  mode %-4s: delivered %.1f of %.1f MWh, %d of %d sessions short (%.2f %%), mean wait %.2f h\n', ...
        md{1}, R.E_del/1e3, R.E_req/1e3, R.n_short, height(Sess), 100*R.share_short, R.mean_wait_h);
end
for nc = [8 9 10 11]
    R = ev_queue_check(Sess, nc, par.P_charger, 'stay');
    Ragg = sum(max(TT.P_ev - nc*par.P_charger, 0));          % what the aggregate model refuses
    fprintf('  %2d chargers: vehicle level (overnight parking) %d sessions short, %.1f MWh not delivered | aggregate model refuses %.1f MWh\n', ...
            nc, R.n_short, R.E_short/1e3, Ragg/1e3);
end
fprintf('--- 6. Economic indicators recomputed independently of fitness.m\n');
PWF = sum(1 ./ (1+eco.i).^(1:eco.N));
parts = [component_npc(res.x.P_pv, eco.pv, eco.pv_life, eco.i, eco.N), ...
         component_npc(res.x.N_wt, eco.wt, eco.wt_life, eco.i, eco.N), ...
         component_npc(res.x.E_bat, eco.bat, L, eco.i, eco.N), ...
         component_npc(res.P_bat, eco.conv, eco.conv_life, eco.i, eco.N), ...
         component_npc(res.N_ch, eco.ch, eco.ch_life, eco.i, eco.N), ...
         PWF*(eco.c_imp*A.E_imp - eco.c_exp*A.E_exp)];
NPC2 = sum(parts);  E_srv = A.E_served;                 % energy served to load + EV (AC)
LCOE2 = NPC2 / PWF / E_srv;
fprintf('  NPC = PV %.0f + WT %.0f + battery %.0f + converter %.0f + chargers %.0f + grid %.0f = %.0f USD (fitness: %.0f)\n', parts, NPC2, res.NPC);
fprintf('  LCOE = NPC x CRF / E_served = %.0f x %.5f / %.0f = %.4f USD/kWh (fitness: %.4f)\n', NPC2, 1/PWF, E_srv, LCOE2, res.LCOE);

fprintf('--- 7. Verification summary\n');
isint = abs(res.x.N_wt - round(res.x.N_wt)) < 1e-12 && abs(res.N_ch - round(res.N_ch)) < 1e-12;
inb = all(xv >= prob.lb - 1e-9 & xv <= prob.ub + 1e-9);
Rv = ev_queue_check(Sess, res.N_ch, par.P_charger, 'stay');
row = @(a, b, c) fprintf('  %-34s | %-44s | %s\n', a, b, c);
row('Check', 'Result', 'Status');
row('Decision variables within bounds', mat2str(round(xv,1)), pf(inb));
row('Integer variables', sprintf('N_wt = %d, N_ch = %d', res.x.N_wt, res.N_ch), pf(isint));
row('SOC limits', sprintf('%.4f to %.4f (window %.2f-%.2f)', min(s.SOC), max(s.SOC), par.bat.SOCmin, par.bat.SOCmax), ...
    pf(min(s.SOC) >= par.bat.SOCmin - 1e-9 && max(s.SOC) <= par.bat.SOCmax + 1e-9));
row('Battery power', sprintf('max |P_bat| %.1f kW <= %.1f kW', max(abs(s.P_bat)), res.P_bat), pf(max(abs(s.P_bat)) <= res.P_bat + 1e-9));
n_dwell = sum(Sess.E_del < Sess.E_req - 1e-9);           % short even with one charger per vehicle
row('EV departure energy (vehicle level)', sprintf('%d of %d short (%d by dwell time alone)', Rv.n_short, height(Sess), n_dwell), pf(Rv.n_short <= n_dwell));
row('Charger occupancy', sprintf('peak EV power %.1f kW <= %d x %.0f kW', max(TTc.P_ev), res.N_ch, par.P_charger), pf(max(TTc.P_ev) <= res.N_ch*par.P_charger + 1e-9));
row('Grid import / export', sprintf('%.0f / %.0f kWh (islanded: limits 0)', A.E_imp, A.E_exp), pf(A.E_imp == 0 && A.E_exp == 0));
row('Energy balance residual', sprintf('%.1e kWh (sources %.0f kWh)', A.residual_full, A.E_pv_dc + A.E_wt + A.E_imp), pf(abs(A.residual_full) < 1e-6*A.E_served));
row('Unserved energy', sprintf('%.0f kWh, LPSP %.3f %% (limit %.2f %%)', A.E_unmet + res.E_ev_lost, 100*res.LPSP, 100*prob.LPSP_max), pf(res.LPSP <= prob.LPSP_max + 1e-9));
row('Battery ageing', sprintf('life %.1f yr, %d replacement(s)', L, numel(yrs)), 'reported');
row('Economic indicators recomputed', sprintf('NPC diff %.2e USD, LCOE diff %.1e', NPC2 - res.NPC, LCOE2 - res.LCOE), pf(abs(NPC2 - res.NPC) < 1e-6*res.NPC && abs(LCOE2 - res.LCOE) < 1e-9));
diary off
disp('=== CH09 CHECKS DONE ===')

function y = ifelse(c, a, b)
if c, y = a; else, y = b; end
end

function y = pf(c)
if c, y = 'PASS'; else, y = 'FAIL'; end
end
