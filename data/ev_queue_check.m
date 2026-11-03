function R = ev_queue_check(S, N_ch, P_ch, mode)
% EV_QUEUE_CHECK  Vehicle-level check of a number of chargers (Section 6.5).
% The sizing model treats the chargers as an aggregate power limit
% (N_ch * P_charger). This function replays the individual sessions of
% ev_sessions_year on N_ch chargers, first come first served, and reports
% how much of each vehicle's energy is really delivered before departure.
%   S    : session table (day, t_arr, t_dep, E_req), times in hours
%   mode : 'stay'  - a vehicle occupies its charger until it leaves (overnight parking)
%          'move'  - a vehicle frees the charger as soon as it is full
%   R    : struct with energies, number of vehicles short, waiting statistics
if nargin < 4, mode = 'stay'; end
arr = (S.day - 1)*24 + S.t_arr;  dep = (S.day - 1)*24 + S.t_dep;
[arr, o] = sort(arr);  dep = dep(o);  Ereq = S.E_req(o);
free = zeros(max(N_ch,0), 1);                  % time at which each charger is free
Edel = zeros(size(Ereq));  wait = zeros(size(Ereq));
for k = 1:numel(arr)
    if N_ch == 0, break; end
    [tf, c] = min(free);                       % earliest free charger
    start = max(arr(k), tf);
    if start >= dep(k), continue; end          % no charger before departure
    Edel(k) = min(Ereq(k), P_ch*(dep(k) - start));
    wait(k) = start - arr(k);
    if strcmp(mode, 'stay')
        free(c) = dep(k);
    else
        free(c) = start + Edel(k)/P_ch;
    end
end
short = Edel < Ereq - 1e-6;
R = struct('mode',mode, 'N_ch',N_ch, 'E_req',sum(Ereq), 'E_del',sum(Edel), ...
           'E_short',sum(Ereq - Edel), 'n_short',sum(short), 'share_short',mean(short), ...
           'mean_wait_h',mean(wait), 'max_wait_h',max(wait));
end
