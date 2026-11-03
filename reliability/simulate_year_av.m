function out = simulate_year_av(x, TT, par, av)
% SIMULATE_YEAR_AV  simulate_year with hourly component availabilities.
% Same rule-based EMS as simulate_year (Chapter 4); each available capacity
% is multiplied by the fraction of the hour the component is up:
%   av.pv   : N x 1     PV inverter (whole array)
%   av.wt   : N x N_wt  one column per wind turbine (turbines fail independently)
%   av.bat  : N x 1     battery converter (power limit Pmax * av.bat)
%   av.grid : N x 1     grid connection (import/export limits * av.grid)
% Missing fields mean "always available". With all availabilities equal
% to 1 the result is identical to simulate_year.
% Chapter 11, Section 11.4
N = numel(TT.P_load);
if ~isfield(av, 'pv'),   av.pv   = ones(N,1); end
if ~isfield(av, 'bat'),  av.bat  = ones(N,1); end
if ~isfield(av, 'grid'), av.grid = ones(N,1); end
if ~isfield(av, 'wt') || isempty(av.wt), av.wt = ones(N, max(round(x.N_wt),0)); end

P_pv  = par.eta_mppt * par.eta_ilc * pv_model(TT.G, TT.Ta, x.P_pv, par.pv) .* av.pv;
P_wt1 = wind_model(TT.v_hub, 1, par.wt);              % one turbine
P_wt  = P_wt1 .* sum(av.wt, 2);                      % available turbines
P_ren = P_pv + P_wt;
P_dem = TT.P_load + TT.P_ev;

[P_bat, SOC, P_imp, P_exp, P_dump, P_unmet, E_sd] = deal(zeros(N,1));
soc = par.bat.SOC0;  bpar = par.bat;  Pmax0 = par.bat.Pmax;
for t = 1:N
    P_net = P_ren(t) - P_dem(t);
    bpar.Pmax = Pmax0 * av.bat(t);
    if x.E_bat > 0
        if P_net >= 0, req = P_net * par.eta_ilc; else, req = P_net / par.eta_ilc; end
        [p_act, soc, E_sd(t)] = battery_step(req, soc, x.E_bat, bpar);
    else
        p_act = 0;
    end
    P_bat(t) = p_act;  SOC(t) = soc;
    if P_net >= 0
        rest = P_net - p_act / par.eta_ilc;
        if par.grid
            P_exp(t) = min(rest, par.P_exp_max * av.grid(t));
            rest = rest - P_exp(t);
        end
        P_dump(t) = max(rest, 0);
    else
        rest = -P_net + p_act * par.eta_ilc;
        if par.grid
            P_imp(t) = min(rest, par.P_imp_max * av.grid(t));
            rest = rest - P_imp(t);
        end
        P_unmet(t) = max(rest, 0);
    end
end
out.E_dem   = sum(P_dem);
out.E_unmet = sum(P_unmet);
out.E_dump  = sum(P_dump);
out.E_imp   = sum(P_imp);
out.E_exp   = sum(P_exp);
out.LPSP    = out.E_unmet / out.E_dem;
out.LOLE    = sum(P_unmet > 1e-6);
out.EENS    = out.E_unmet;
out.REF     = 1 - out.E_imp / out.E_dem;
out.N_eq    = sum(-P_bat(P_bat < 0)) / max((par.bat.SOCmax - par.bat.SOCmin) * x.E_bat, eps);
out.series  = struct('P_ren',P_ren, 'P_dem',P_dem, 'P_bat',P_bat, 'SOC',SOC, ...
                     'P_imp',P_imp, 'P_exp',P_exp, 'P_dump',P_dump, 'P_unmet',P_unmet, ...
                     'E_sd',E_sd);
end
