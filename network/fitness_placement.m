function [F, res] = fitness_placement(xvec, TT, par, eco, prob, nw)
% FITNESS_PLACEMENT  Joint sizing and placement on a radial feeder.
% nw: network data: br, Pd_peak, Qd_peak, net, cand (candidate buses),
%     rep.idx (hours used for load flow), rep.w (weight of each hour),
%     Vmin, Vmax, w (weights), ref (base-case references: NPC, E_loss, VD)
% Chapter 10, Section 10.5

% --- 1. Sizes and locations
x.P_pv = xvec(1);  x.N_wt = round(xvec(2));  x.E_bat = xvec(3);
par.bat.Pmax = xvec(4);  N_ch = round(xvec(5));
pick = @(v) nw.cand(min(max(round(v),1), numel(nw.cand)));
bus  = struct('pv',pick(xvec(6)), 'wt',pick(xvec(7)), ...
              'bat',pick(xvec(8)), 'ev',pick(xvec(9)));

% --- 2. Operation: EMS with the substation as the grid
par.grid = true;
[~, res] = fitness(xvec(1:5), TT, par, eco, prob);   % costs, EV refusals, LPSP
TT.P_ev  = min(TT.P_ev, N_ch * par.P_charger);       % EV power actually served
s   = res.out.series;
P_pv = par.eta_mppt*par.eta_ilc*pv_model(TT.G, TT.Ta, x.P_pv, par.pv);
P_wt = wind_model(TT.v_hub, x.N_wt, par.wt);

% --- 3. Load flow at representative hours
E_loss = 0;  VD = 0;  pen = 0;
for k = 1:numel(nw.rep.idx)
    t   = nw.rep.idx(k);
    sL  = TT.P_load(t) / max(TT.P_load);              % load scaling
    inj = struct('pv',P_pv(t), 'wt',P_wt(t), 'bat',s.P_bat(t), 'ev',TT.P_ev(t));
    [P, Q] = apply_der(nw.Pd_peak*sL, nw.Qd_peak*sL, bus, inj);
    [V, Pl] = bfs_loadflow(nw.br, P, Q, nw.net);
    Vm  = abs(V);
    E_loss = E_loss + nw.rep.w(k) * Pl;                % kWh
    VD     = VD     + nw.rep.w(k) * sum((Vm - 1).^2);
    pen    = pen + sum(max(0, nw.Vmin - Vm)) + sum(max(0, Vm - nw.Vmax));
end

% --- 4. Objective
F = nw.w(1)*res.NPC/nw.ref.NPC + nw.w(2)*E_loss/nw.ref.E_loss ...
  + nw.w(3)*VD/nw.ref.VD + prob.lambda*pen ...
  + prob.lambda * max(0, res.LPSP - prob.LPSP_max);    % includes refused EV energy
res.bus = bus;  res.E_loss = E_loss;  res.VD = VD;  res.N_ch = N_ch;
end
