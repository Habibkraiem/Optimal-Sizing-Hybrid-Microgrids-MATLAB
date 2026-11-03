function P_pv = pv_model(G, Ta, P_rated, par)
% PV_MODEL  Hourly PV output (kW, DC) from irradiance and ambient temperature.
%   G       : irradiance on the array plane (W/m^2), vector
%   Ta      : ambient temperature (degC), vector
%   P_rated : rated array power at STC (kW)
%   par     : struct with fields gamma (1/degC), NOCT (degC), f_der (-)
% Chapter 3, Section 3.1
Tc   = Ta + (G/800) * (par.NOCT - 20);
P_pv = P_rated * par.f_der .* (G/1000) .* (1 + par.gamma*(Tc - 25));
P_pv = max(P_pv, 0);
end
