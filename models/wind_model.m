function P_wt = wind_model(v, N_wt, par)
% WIND_MODEL  Wind farm output (kW) from hub-height wind speed.
%   v    : wind speed at hub height (m/s), vector (no NaN: clean the data first)
%   N_wt : number of turbines (integer)
%   par  : struct with fields Pr (kW), vci, vr, vco (m/s)
%          optional: curve_v, curve_P (manufacturer power curve table)
% Chapter 3, Section 3.2
if any(isnan(v)), error('wind_model:nan', 'Wind speed contains NaN: clean the data (Section 2.5).'); end
if isfield(par, 'curve_v')                     % tabulated power curve
    P1 = interp1(par.curve_v, par.curve_P, v, 'linear', 0);   % 0 outside the table
    P1(v < par.vci | v >= par.vco) = 0;        % cut-in and cut-out always respected
else                                           % cubic approximation
    P1 = zeros(size(v));
    k  = v >= par.vci & v < par.vr;
    P1(k) = par.Pr * (v(k).^3 - par.vci^3) / (par.vr^3 - par.vci^3);
    P1(v >= par.vr & v < par.vco) = par.Pr;
end
P1 = min(max(P1, 0), par.Pr);                  % never below 0 or above rated power
P_wt = N_wt * P1;
end
