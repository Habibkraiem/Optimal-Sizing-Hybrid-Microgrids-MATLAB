function [P_ev, E_del, E_short] = smart_charge(t_arr, t_dep, E_need, P_ch, priority)
% SMART_CHARGE  Greedy smart charging of one EV (a heuristic, not an optimum).
%   t_arr, t_dep : arrival and departure hours, as indices into priority
%                  (t_dep > t_arr). Use a 48-hour priority vector for a
%                  vehicle that arrives in the evening and leaves next morning.
%   E_need       : energy to deliver (kWh)
%   P_ch         : charger power (kW)
%   priority     : 1xH vector, higher = better hour to charge (e.g. PV surplus)
%   P_ev         : 1xH charging power (kW), 1-hour steps
%   E_del        : energy delivered before departure (kWh)
%   E_short      : energy that could not be delivered (kWh), 0 if feasible
% The function fills the best-ranked parked hours first, at most P_ch each.
% It is feasible only if E_need <= P_ch * (t_dep - t_arr); otherwise the
% shortfall is returned (and must be counted as unserved EV energy).
% Chapter 3, Section 3.4
P_ev  = zeros(size(priority));
hrs   = t_arr:t_dep-1;                         % hours parked
[~, order] = sort(priority(hrs), 'descend');
E_left = E_need;
for k = order
    if E_left <= 0, break; end
    h = hrs(k);
    P_ev(h) = min(P_ch, E_left);               % 1-hour step: kW = kWh
    E_left  = E_left - P_ev(h);
end
E_del   = sum(P_ev);
E_short = max(E_left, 0);
if E_short > 1e-6
    warning('smart_charge:incomplete', ...
        'Vehicle short by %.1f kWh at departure (needs %.1f kWh, max %.1f kWh).', ...
        E_short, E_need, P_ch*numel(hrs));
end
end
