function res = evaluate_design(x, TT, par, eco)
% EVALUATE_DESIGN  All sizing criteria for one design (Chapter 5, Section 5.5).
%   x   : design (P_pv, N_wt, E_bat)
%   eco : economic data: i, N, cost structs pv, wt, bat (cap, om, rep),
%         pv_life, wt_life, bat_cal_life, bat_cycle_life,
%         c_imp, c_exp (USD/kWh), EF_grid (kg/kWh)
out = simulate_year(x, TT, par);

% --- Battery life from cycling, capped by calendar life
if out.N_eq > 0
    life_bat = min(eco.bat_cal_life, eco.bat_cycle_life / out.N_eq);
else
    life_bat = eco.bat_cal_life;
end

% --- Component NPCs
npc_pv  = component_npc(x.P_pv,  eco.pv,  eco.pv_life, eco.i, eco.N);
npc_wt  = component_npc(x.N_wt,  eco.wt,  eco.wt_life, eco.i, eco.N);
npc_bat = component_npc(x.E_bat, eco.bat, life_bat,    eco.i, eco.N);

% --- Grid exchange over the project life (present worth)
PWF      = sum(1 ./ (1+eco.i).^(1:eco.N));    % present worth of 1 USD/year
npc_grid = PWF * (eco.c_imp*out.E_imp - eco.c_exp*out.E_exp);

% --- Results
res.NPC  = npc_pv + npc_wt + npc_bat + npc_grid;
CRF      = 1 / PWF;
res.LCOE = res.NPC * CRF / max(out.E_dem - out.E_unmet, eps);
res.LPSP = out.LPSP;
res.LOLE = out.LOLE;
res.CO2  = eco.EF_grid * out.E_imp;           % kg/year
res.REF  = out.REF;
res.curt = out.E_dump / max(sum(out.series.P_ren), eps);
res.life_bat = life_bat;
res.out  = out;
end
