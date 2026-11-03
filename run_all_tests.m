% RUN_ALL_TESTS  Checks every function of the book in a few minutes.
% Run it from the MicrogridSizing folder. Each test prints PASS or FAIL.
% Requires MATLAB R2016b or newer. Test 12 needs MATPOWER (optional).
clear; clc; close all;
addpath(genpath(pwd));
nPass = 0;  nFail = 0;
fprintf('=== Microgrid sizing book: code tests ===\n\n');

%% 1. PSO on the sphere function (must reach almost 0)
try
    rng(1);
    sphere = @(x) sum(x.^2);
    opt = struct('N',30,'maxIt',200,'wmax',0.9,'wmin',0.4,'c1',2,'c2',2,'vfrac',0.2);
    [~, f] = pso(sphere, -10*ones(1,5), 10*ones(1,5), opt);
    [nPass, nFail] = check('PSO on sphere (f < 1e-4)', f < 1e-4, f, nPass, nFail);
catch err, [nPass, nFail] = report_error('PSO on sphere', err, nPass, nFail); end

%% 2. PSO on Rastrigin (hard function: a small value is enough)
try
    rng(1);
    rastrigin = @(x) 10*numel(x) + sum(x.^2 - 10*cos(2*pi*x));
    opt = struct('N',30,'maxIt',300,'wmax',0.9,'wmin',0.4,'c1',2,'c2',2,'vfrac',0.2);
    [~, f] = pso(rastrigin, -5.12*ones(1,5), 5.12*ones(1,5), opt);
    [nPass, nFail] = check('PSO on Rastrigin D=5 (f < 5)', f < 5, f, nPass, nFail);
catch err, [nPass, nFail] = report_error('PSO on Rastrigin', err, nPass, nFail); end

%% 3. GA, GWO and RDA on the sphere function
% GA and RDA (fixed step sizes) are checked loosely: they must work, not excel.
algos = {@ga_real, @gwo, @rda};  names = {'GA','GWO','RDA'};  tol = [1, 1e-4, 1];
optsA = { struct('N',30,'maxIt',200,'pc',0.85,'pm',0.2,'sigma',0.1), ...
          struct('N',30,'maxIt',200), ...
          struct('N',30,'maxIt',100,'nMale',6,'gamma',0.6,'alpha',0.85,'beta',0.4,'step',0.1) };
for a = 1:3
    try
        rng(1);
        [~, f] = algos{a}(@(x) sum(x.^2), -10*ones(1,5), 10*ones(1,5), optsA{a});
        [nPass, nFail] = check(sprintf('%s on sphere (f < %g)', names{a}, tol(a)), f < tol(a), f, nPass, nFail);
    catch err, [nPass, nFail] = report_error([names{a} ' on sphere'], err, nPass, nFail); end
end

%% 4. Data: build the synthetic demo data if no data file exists
try
    if ~exist('data/site_profiles.mat', 'file')
        fprintf('No data/site_profiles.mat: creating synthetic demo data...\n');
        make_demo_data();
    end
    S = load('data/site_profiles.mat', 'TT');  TT = S.TT;
    ok = height(TT) == 8760 && all(ismember({'G','Ta','v_hub','P_load','P_ev'}, ...
                                            TT.Properties.VariableNames));
    [nPass, nFail] = check('Data file: 8760 rows and required columns', ok, height(TT), nPass, nFail);
catch err, [nPass, nFail] = report_error('Data file', err, nPass, nFail); end

[par, eco] = load_parameters();

%% 5. PV model: STC check and night
try
    Ta_stc = 25 - (1000/800)*(par.pv.NOCT - 20);       % gives Tc = 25 degC
    P1 = pv_model(1000, Ta_stc, 100, par.pv);
    P0 = pv_model(0, 30, 100, par.pv);
    ok = abs(P1 - 100*par.pv.f_der) < 1e-9 && P0 == 0;
    [nPass, nFail] = check('PV model (STC and night)', ok, P1, nPass, nFail);
catch err, [nPass, nFail] = report_error('PV model', err, nPass, nFail); end

%% 6. Wind model: power curve regions
try
    w = par.wt;
    P = wind_model([0, w.vci-0.1, w.vr, (w.vr+w.vco)/2, w.vco+1], 2, w);
    ok = isequal(P([1 2 5]), [0 0 0]) && abs(P(3) - 2*w.Pr) < 1e-9 && abs(P(4) - 2*w.Pr) < 1e-9;
    [nPass, nFail] = check('Wind model (cut-in, rated, cut-out)', ok, P, nPass, nFail);
catch err, [nPass, nFail] = report_error('Wind model', err, nPass, nFail); end

%% 7. Battery: SOC stays in its window
try
    b = par.bat;  soc = b.SOCmin;  socs = zeros(1,40);
    for k = 1:20, [~, soc] = battery_step( 1e6, soc, 100, b); socs(k) = soc; end
    for k = 21:40, [~, soc] = battery_step(-1e6, soc, 100, b); socs(k) = soc; end
    ok = max(socs) <= b.SOCmax + 1e-9 && min(socs) >= b.SOCmin - 1e-9 ...
         && abs(socs(20) - b.SOCmax) < 1e-6 && abs(socs(40) - b.SOCmin) < 1e-6;
    [nPass, nFail] = check('Battery SOC window', ok, [min(socs) max(socs)], nPass, nFail);
catch err, [nPass, nFail] = report_error('Battery', err, nPass, nFail); end

%% 8. Smart charging delivers the energy in the best hours
try
    prio = zeros(1,24);  prio(10:14) = 1;                 % sunny hours
    P = smart_charge(8, 17, 20, 7, prio);
    ok = abs(sum(P) - 20) < 1e-9 && sum(P(10:14)) == 20;
    [nPass, nFail] = check('Smart charging', ok, sum(P), nPass, nFail);
catch err, [nPass, nFail] = report_error('Smart charging', err, nPass, nFail); end

%% 9. simulate_year: energy balance, SOC bounds, extreme designs
try
    x = struct('P_pv',100, 'N_wt',2, 'E_bat',200);
    out = simulate_year(x, TT, par);  s = out.series;  e = par.eta_ilc;
    resid = sum(s.P_ren) + sum(max(-s.P_bat,0))*e + sum(s.P_imp) + sum(s.P_unmet) ...
          - sum(s.P_dem) - sum(max(s.P_bat,0))/e - sum(s.P_exp) - sum(s.P_dump);
    [nPass, nFail] = check('Annual energy balance closes', abs(resid) < 1e-6*out.E_dem, resid, nPass, nFail);
    ok = all(s.SOC <= par.bat.SOCmax + 1e-9) && all(s.SOC >= par.bat.SOCmin - 1e-9);
    [nPass, nFail] = check('SOC within bounds all year', ok, [min(s.SOC) max(s.SOC)], nPass, nFail);
    o0 = simulate_year(struct('P_pv',0,'N_wt',0,'E_bat',0), TT, par);
    [nPass, nFail] = check('Empty design: LPSP = 100 %', abs(o0.LPSP - 1) < 1e-12, o0.LPSP, nPass, nFail);
    parBig = par;  parBig.bat.Pmax = 5000;
    oB = simulate_year(struct('P_pv',3000,'N_wt',10,'E_bat',20000), TT, parBig);
    [nPass, nFail] = check('Huge design: LPSP < 1 %', oB.LPSP < 0.01, oB.LPSP, nPass, nFail);
catch err, [nPass, nFail] = report_error('simulate_year', err, nPass, nFail); end

%% 10. Economics and fitness
try
    r = evaluate_design(x, TT, par, eco);
    ok = isfinite(r.NPC) && r.NPC > 0 && isfinite(r.LCOE) && r.LCOE > 0;
    [nPass, nFail] = check('evaluate_design (finite NPC and LCOE)', ok, [r.NPC r.LCOE], nPass, nFail);
    npc_noRep = component_npc(1, struct('cap',100,'om',0,'rep',100), 25, 0.06, 25);
    [nPass, nFail] = check('component_npc (no replacement, no salvage)', abs(npc_noRep - 100) < 1e-9, npc_noRep, nPass, nFail);
    prob = define_problem();
    fobj = @(xv) fitness(xv, TT, par, eco, prob);
    tic; for k = 1:5, fobj(prob.lb + rand(size(prob.lb)).*(prob.ub - prob.lb)); end; dt = toc/5;
    fprintf('       one fitness evaluation takes about %.3f s\n', dt);
    fprintf('       -> 6,000 evaluations take about %.1f min\n', 6000*dt/60);
    [nPass, nFail] = check('fitness runs', isfinite(dt), dt, nPass, nFail);
catch err, [nPass, nFail] = report_error('Economics/fitness', err, nPass, nFail); end

%% 11. Short optimization on the real problem with each algorithm
try
    opts = load_optimizer_settings(300);
    algs = {@pso, @ga_real, @gwo, @rda};  nm = {'PSO','GA','GWO','RDA'};
    for a = 1:4
        rng(1);
        bf = BudgetFitness(fobj, 300);
        algs{a}(@(v) bf.eval(v), prob.lb, prob.ub, opts{a});
        ok = isfinite(bf.best) && bf.count >= 0.9*300;
        [nPass, nFail] = check(sprintf('%s on sizing problem (300 evaluations)', nm{a}), ok, bf.best, nPass, nFail);
    end
catch err, [nPass, nFail] = report_error('Short optimization', err, nPass, nFail); end

%% 12. IEEE 33-bus base case (needs MATPOWER)
if exist('case33bw', 'file') == 2
    try
        [br, Pd, Qd, Vb] = load_ieee33();
        net = struct('Vbase_kV',Vb, 'Sbase_MVA',1, 'tol',1e-8, 'maxIt',100);
        [V, Pl] = bfs_loadflow(br, Pd, Qd, net);
        [Vmin, imin] = min(abs(V));
        ok = abs(Pl - 202.7) < 2 && abs(Vmin - 0.913) < 0.002 && imin == 18;
        [nPass, nFail] = check('IEEE 33-bus base case (202.7 kW, 0.913 p.u. @ 18)', ok, [Pl Vmin imin], nPass, nFail);
    catch err, [nPass, nFail] = report_error('IEEE 33-bus', err, nPass, nFail); end
else
    fprintf('SKIP  IEEE 33-bus base case: MATPOWER not on the path\n');
end

%% 13. Failure model
try
    rng(1);  up = updown_series(8760*50, 1000, 50);
    A = mean(up);  A_th = 1000/(1000+50);
    [nPass, nFail] = check('Two-state availability close to MTTF/(MTTF+MTTR)', abs(A - A_th) < 0.01, [A A_th], nPass, nFail);
catch err, [nPass, nFail] = report_error('Failure model', err, nPass, nFail); end

%% 14. Chronological EV sessions: physical conditions hold exactly
try
    rng(2);
    pe = struct('mu_arr',18,'sd_arr',2,'arr_win',[12 23.9],'mu_dep',7.5,'sd_dep',1,'dep_win',[5 10], ...
                'soc0_min',0.2,'soc0_max',0.6,'soc_target',0.9,'E_bat',60,'P_ch',7,'eta',0.9);
    [Pe, Se, ie] = ev_sessions_year(10, 30, pe);
    ok = ie.ok_after_arrival && ie.ok_before_depart && ie.ok_not_above_req && ie.ok_profile_energy ...
         && all(Se.t_arr >= 12) && ie.max_charging <= ie.max_plugged;
    [nPass, nFail] = check('EV sessions: after arrival, before departure, E_del <= E_req, profile = sum', ...
                           ok, [ie.E_req ie.E_del ie.E_profile], nPass, nFail);
catch err, [nPass, nFail] = report_error('EV sessions', err, nPass, nFail); end

%% 15. Energy audit with losses closes (AC bus, battery, full balance)
try
    parA = par;  parA.bat.Pmax = 50;
    xa = struct('P_pv',150, 'N_wt',1, 'E_bat',300);
    oa = simulate_year(xa, TT, parA);
    A = energy_audit(xa, TT, parA, oa);
    tolE = 1e-6 * oa.E_dem;
    ok = abs(A.residual_ac) < tolE && abs(A.residual_bat) < tolE && abs(A.residual_full) < tolE;
    [nPass, nFail] = check('Energy audit residuals ~ 0', ok, [A.residual_ac A.residual_bat A.residual_full], nPass, nFail);
catch err, [nPass, nFail] = report_error('Energy audit', err, nPass, nFail); end

%% 16. Charger check: N chargers for N vehicles parked overnight is enough
try
    R10 = ev_queue_check(Se, 10, 7, 'stay');  R8 = ev_queue_check(Se, 8, 7, 'stay');
    ok = R10.n_short == 0 && R8.n_short > 0;
    [nPass, nFail] = check('Vehicle-level charger check (10 ok, 8 short)', ok, [R10.n_short R8.n_short], nPass, nFail);
catch err, [nPass, nFail] = report_error('Charger check', err, nPass, nFail); end

%% 17. Plane-of-array irradiance: tilt 0 returns GHI, tilt = latitude gains 3-15 %
try
    t17 = TT.Properties.RowTimes;
    if isempty(t17.TimeZone), t17.TimeZone = 'Asia/Riyadh'; end
    g0 = poa_irradiance(TT.G, t17, 30.98, 41.04, 0);
    g31 = poa_irradiance(TT.G, t17, 30.98, 41.04, 31);
    ratio = sum(g31)/sum(TT.G);
    ok = max(abs(g0 - max(TT.G,0))) < 1e-6 && ratio > 1.03 && ratio < 1.15;
    [nPass, nFail] = check(sprintf('POA irradiance (tilt 31 deg: x%.3f)', ratio), ok, ratio, nPass, nFail);
catch err, [nPass, nFail] = report_error('POA irradiance', err, nPass, nFail); end

%% 18. Battery: self-discharge never leaves the SOC window and never adds energy
try
    b = par.bat;  b.sigma = 0.002;  b.Pmax = 50;  E = 100;
    [p1, s1, l1] = battery_step(  0, b.SOCmin + 0.0001, E, b);   % idle just above SOCmin
    [p2, s2, l2] = battery_step(  0, b.SOCmin, E, b);            % idle at SOCmin
    [p3, s3]     = battery_step(-50, b.SOCmin + 0.001, E, b);    % discharge near SOCmin
    ok = s1 >= b.SOCmin - 1e-12 && l1 >= 0 && l1 <= 0.0001*E + 1e-12 && s2 == b.SOCmin && l2 == 0 ...
         && s3 >= b.SOCmin - 1e-12 && p3 <= 0 && p1 == 0;
    [nPass, nFail] = check('Battery self-discharge stays in [SOCmin, SOCmax]', ok, [s1 s2 s3], nPass, nFail);
    parS = par;  parS.bat.sigma = 0.0005;  parS.bat.Pmax = 50;
    xs = struct('P_pv',150, 'N_wt',1, 'E_bat',300);
    os = simulate_year(xs, TT, parS);  As = energy_audit(xs, TT, parS, os);
    ok = abs(As.residual_bat) < 1e-6*os.E_dem && abs(As.residual_full) < 1e-6*os.E_dem && As.L_sd > 0 ...
         && min(os.series.SOC) >= parS.bat.SOCmin - 1e-9;
    [nPass, nFail] = check('Energy audit closes with self-discharge (sigma > 0)', ok, [As.residual_bat As.L_sd], nPass, nFail);
catch err, [nPass, nFail] = report_error('Battery self-discharge', err, nPass, nFail); end

%% 19. Availability model: hourly fractions, short failures kept, all-up = simulate_year
try
    rng(3);  a = updown_series(8760*20, 50, 0.3);         % failures much shorter than 1 h
    A_th = 50/50.3;
    ok = all(a >= 0 & a <= 1) && abs(mean(a) - A_th) < 0.002 && any(a > 0 & a < 1);
    [nPass, nFail] = check('Availability: fractions in [0,1], short repairs kept', ok, [mean(a) A_th], nPass, nFail);
    xr = struct('P_pv',150, 'N_wt',2, 'E_bat',300);  parR = par;  parR.bat.Pmax = 50;
    o1 = simulate_year(xr, TT, parR);
    o2 = simulate_year_av(xr, TT, parR, struct());
    av = struct('wt', [ones(8760,1) zeros(8760,1)]);       % one of two turbines down all year
    o3 = simulate_year_av(xr, TT, parR, av);
    o4 = simulate_year(struct('P_pv',150,'N_wt',1,'E_bat',300), TT, parR);
    ok = abs(o1.E_unmet - o2.E_unmet) < 1e-6 && abs(o3.E_unmet - o4.E_unmet) < 1e-6;
    [nPass, nFail] = check('simulate_year_av (all up = simulate_year, per-turbine masks)', ok, [o1.E_unmet o2.E_unmet o3.E_unmet o4.E_unmet], nPass, nFail);
catch err, [nPass, nFail] = report_error('Availability model', err, nPass, nFail); end

%% 20. Sensitivity and cost-sampling helpers
try
    [~, e2, T2] = perturb(par, eco, TT, 'bat.cap', 1.2);
    [~, ~, T3]  = perturb(par, eco, TT, 'load_scale', 0.8);
    rng(4);  [~, e4] = sample_costs(par, eco, 0.2);
    ok = abs(e2.bat.cap - 1.2*eco.bat.cap) < 1e-9 && isequal(T2.P_load, TT.P_load) ...
         && abs(sum(T3.P_load) - 0.8*sum(TT.P_load)) < 1e-6 ...
         && abs(e4.pv.cap/eco.pv.cap - 1) <= 0.2 + 1e-12 && abs(e4.pv.cap/eco.pv.cap - e4.pv.om/eco.pv.om) < 1e-12;
    [nPass, nFail] = check('perturb and sample_costs', ok, [e2.bat.cap e4.pv.cap], nPass, nFail);
catch err, [nPass, nFail] = report_error('Sensitivity helpers', err, nPass, nFail); end

fprintf('\n=== %d passed, %d failed ===\n', nPass, nFail);

%% ---- local functions ----
function [nPass, nFail] = check(name, ok, value, nPass, nFail)
if ok
    fprintf('PASS  %s\n', name);  nPass = nPass + 1;
else
    fprintf('FAIL  %s   (value: %s)\n', name, mat2str(value, 5));  nFail = nFail + 1;
end
end

function [nPass, nFail] = report_error(name, err, nPass, nFail)
fprintf('FAIL  %s   ERROR: %s\n', name, err.message);
if ~isempty(err.stack)
    fprintf('      in %s, line %d\n', err.stack(1).name, err.stack(1).line);
end
nFail = nFail + 1;
end
