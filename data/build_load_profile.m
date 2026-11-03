function P_load = build_load_profile(P_peak, s_day, k_month, k_weekend, noise)
% BUILD_LOAD_PROFILE  Synthetic hourly load for one (non-leap) year.
%   P_peak    : peak demand scale (kW)
%   s_day     : 1x24 normalized daily shape (max = 1)
%   k_month   : 1x12 monthly multipliers
%   k_weekend : multiplier for Saturdays and Sundays (e.g. 0.8)
%   noise     : standard deviation of the random term (e.g. 0.05)
% Chapter 2, Section 2.3
t = datetime(2025,1,1,0,0,0) + hours(0:8759)';    % non-leap year
P_load = zeros(8760,1);
for i = 1:8760
    h  = hour(t(i)) + 1;                  % 1..24
    m  = month(t(i));                     % 1..12
    kw = 1;
    if isweekend(t(i)), kw = k_weekend; end
    P_load(i) = P_peak * s_day(h) * k_month(m) * kw * (1 + noise*randn);
end
P_load = max(P_load, 0);                  % no negative load
end
