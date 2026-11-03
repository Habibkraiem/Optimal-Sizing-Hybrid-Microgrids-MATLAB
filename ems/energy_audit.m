function A = energy_audit(x, TT, par, out)
% ENERGY_AUDIT  Annual energy balance of one simulated design, with losses.
% System boundary: the AC bus. PV is converted DC -> AC (MPPT, then the
% interlinking converter, ILC); the battery sits on the DC bus and exchanges
% power with the AC bus through the ILC. P_bat in out.series is measured at
% the battery terminals (DC): > 0 charging, < 0 discharging.
%   A.residual_ac   : sources - uses on the AC bus (should be ~0)
%   A.residual_bat  : stored-energy change - (charge in - discharge out) (~0)
%   A.residual_full : full balance including all losses (~0)
% Chapter 4, Section 4.5
s  = out.series;  e = par.eta_ilc;  b = par.bat;
P_pv_dc = pv_model(TT.G, TT.Ta, x.P_pv, par.pv);          % array output (DC)
E_pv_dc  = sum(P_pv_dc);
E_pv_ac  = sum(par.eta_mppt * e * P_pv_dc);               % at the AC bus
E_wt     = sum(wind_model(TT.v_hub, x.N_wt, par.wt));     % wind (AC, after its converter)
E_ch_dc  = sum(max(s.P_bat, 0));                          % into the battery terminals
E_dis_dc = sum(max(-s.P_bat, 0));                         % out of the battery terminals
E_ch_ac  = E_ch_dc / e;                                   % taken from the AC bus
E_dis_ac = E_dis_dc * e;                                  % delivered to the AC bus
E_served = sum(s.P_dem - s.P_unmet);
E_imp = sum(s.P_imp);  E_exp = sum(s.P_exp);  E_dump = sum(s.P_dump);  E_unmet = sum(s.P_unmet);

% Losses
L_pv  = E_pv_dc - E_pv_ac;                                % MPPT + ILC on the PV path
L_ilc = (E_ch_ac - E_ch_dc) + (E_dis_dc - E_dis_ac);      % ILC on the battery path
L_bat = E_ch_dc*(1 - b.eta_ch) + E_dis_dc*(1/b.eta_dis - 1);
if isfield(s, 'E_sd'), L_sd = sum(s.E_sd); else, L_sd = 0; end   % self-discharge
% Stored energy: SOC(t) is the value at the end of hour t
dE_store = (s.SOC(end) - b.SOC0) * x.E_bat;

A = struct('E_pv_dc',E_pv_dc, 'E_pv_ac',E_pv_ac, 'E_wt',E_wt, 'E_imp',E_imp, ...
           'E_served',E_served, 'E_unmet',E_unmet, 'E_exp',E_exp, 'E_dump',E_dump, ...
           'E_ch_dc',E_ch_dc, 'E_dis_dc',E_dis_dc, 'L_pv',L_pv, 'L_ilc',L_ilc, ...
           'L_bat',L_bat, 'L_sd',L_sd, 'dE_store',dE_store);
A.residual_ac   = (E_pv_ac + E_wt + E_imp + E_dis_ac) - (E_served + E_exp + E_dump + E_ch_ac);
A.residual_bat  = dE_store - (b.eta_ch*E_ch_dc - E_dis_dc/b.eta_dis - L_sd);
A.residual_full = (E_pv_dc + E_wt + E_imp) ...
                - (E_served + E_exp + E_dump + L_pv + L_ilc + L_bat + L_sd + dE_store);
end
