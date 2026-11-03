function out = simulate_year(x, TT, par)
% SIMULATE_YEAR  Rule-based (load-following) dispatch over one year.
%   x   : design struct with fields P_pv (kW), N_wt (-), E_bat (kWh)
%   TT  : timetable (or struct) with G, Ta, v_hub, P_load, P_ev (8760 x 1)
%   par : model parameters: par.pv, par.wt, par.bat, par.eta_mppt,
%         par.eta_ilc, par.grid (true/false), par.P_imp_max, par.P_exp_max
% All power is referred to the AC bus.  Chapter 4, Section 4.4
N = numel(TT.P_load);

% --- Renewable production referred to the AC bus (vectorized)
P_pv  = par.eta_mppt * par.eta_ilc * pv_model(TT.G, TT.Ta, x.P_pv, par.pv);
P_wt  = wind_model(TT.v_hub, x.N_wt, par.wt);
P_ren = P_pv + P_wt;
P_dem = TT.P_load + TT.P_ev;

% --- Preallocate outputs
[P_bat, SOC, P_imp, P_exp, P_dump, P_unmet, E_sd] = deal(zeros(N,1));
soc = par.bat.SOC0;

for t = 1:N
    P_net = P_ren(t) - P_dem(t);              % surplus (>0) or deficit (<0)
    if x.E_bat > 0
        % the battery sees the request through the interlinking converter
        if P_net >= 0
            req = P_net * par.eta_ilc;         % charge with the surplus
        else
            req = P_net / par.eta_ilc;         % discharge to cover the deficit
        end
        [p_act, soc, E_sd(t)] = battery_step(req, soc, x.E_bat, par.bat);
    else
        p_act = 0;
    end
    P_bat(t) = p_act;                          % >0 charging, <0 discharging
    SOC(t)   = soc;

    if P_net >= 0                              % ---- surplus branch
        rest = P_net - p_act / par.eta_ilc;
        if par.grid
            P_exp(t) = min(rest, par.P_exp_max);
            rest     = rest - P_exp(t);
        end
        P_dump(t) = max(rest, 0);
    else                                       % ---- deficit branch
        rest = -P_net + p_act * par.eta_ilc;   % p_act <= 0 here
        if par.grid
            P_imp(t) = min(rest, par.P_imp_max);
            rest     = rest - P_imp(t);
        end
        P_unmet(t) = max(rest, 0);
    end
end

% --- Indicators (1-hour steps: kW summed = kWh)
out.E_dem   = sum(P_dem);
out.E_unmet = sum(P_unmet);
out.E_dump  = sum(P_dump);
out.E_imp   = sum(P_imp);
out.E_exp   = sum(P_exp);
out.LPSP    = out.E_unmet / out.E_dem;
out.LOLE    = sum(P_unmet > 1e-6);                  % hours with unserved load
out.REF     = 1 - out.E_imp / out.E_dem;            % renewable fraction (grid case)
out.N_eq    = sum(-P_bat(P_bat < 0)) / ...
              max((par.bat.SOCmax - par.bat.SOCmin) * x.E_bat, eps);
out.series  = struct('P_ren',P_ren, 'P_dem',P_dem, 'P_bat',P_bat, 'SOC',SOC, ...
                     'P_imp',P_imp, 'P_exp',P_exp, 'P_dump',P_dump, 'P_unmet',P_unmet, ...
                     'E_sd',E_sd);
end
