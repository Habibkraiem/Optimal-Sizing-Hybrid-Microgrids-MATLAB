function [F, res] = fitness(xvec, TT, par, eco, prob)
% FITNESS  Vector in, score out: the function every optimizer calls.
% Chapter 6, Section 6.5
% --- Decode the vector into a design (round integer variables)
x.P_pv  = xvec(1);
x.N_wt  = round(xvec(2));
x.E_bat = xvec(3);
P_bat   = xvec(4);
N_ch    = round(xvec(5));
if isfield(prob, 'round') && ~prob.round      % experiment of Section 6.4:
    x.N_wt = max(xvec(2), 0);  N_ch = max(xvec(5), 0);   % continuous relaxation
end

% --- Apply design-dependent parameters
par.bat.Pmax = P_bat;
P_ev_req = TT.P_ev;                                  % EV demand that should be served
TT.P_ev  = min(P_ev_req, N_ch * par.P_charger);      % what the chargers can deliver
E_ev_lost = sum(P_ev_req - TT.P_ev);                 % EV energy refused (too few chargers)

% --- Evaluate
res = evaluate_design(x, TT, par, eco);

% --- Costs of the battery converter and of the chargers.
% Without them, P_bat and N_ch would be "free" variables (Section 6.5).
npc_conv = component_npc(P_bat, eco.conv, eco.conv_life, eco.i, eco.N);
npc_ch   = component_npc(N_ch,  eco.ch,   eco.ch_life,   eco.i, eco.N);
res.NPC  = res.NPC + npc_conv + npc_ch;

% --- Reliability counts refused EV energy as unserved energy.
% Without this, the optimizer would remove the chargers to cut the demand.
E_dem_full = res.out.E_dem + E_ev_lost;
E_unmet    = res.out.E_unmet + E_ev_lost;
res.LPSP   = E_unmet / E_dem_full;
res.E_ev_lost = E_ev_lost;
PWF      = sum(1 ./ (1+eco.i).^(1:eco.N));
res.LCOE = res.NPC / PWF / max(E_dem_full - E_unmet, eps);

res.x = x;  res.P_bat = P_bat;  res.N_ch = N_ch;

% --- Objective + penalties
F = res.NPC ...
  + prob.lambda * max(0, res.LPSP - prob.LPSP_max) ...
  + prob.lambda * max(0, prob.REF_min - res.REF);
end
