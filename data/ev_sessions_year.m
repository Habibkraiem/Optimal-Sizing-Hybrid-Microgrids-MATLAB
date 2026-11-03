function [P_ev, S, info] = ev_sessions_year(N_ev, nDays, par)
% EV_SESSIONS_YEAR  Chronological EV charging demand for a whole year.
% Each vehicle arrives in the evening of day d, stays parked overnight and
% leaves on the morning of day d+1. Charging is uncontrolled: it starts at
% the first full minute after arrival at full charger power and stops when
% the energy is delivered or the vehicle leaves, whichever comes first.
% The last, partial minute is charged at reduced power, so the delivered
% energy equals the request exactly (or the dwell-time limit). Sessions
% that cross midnight continue on the next day (no wrapping inside a day);
% sessions of the last day continue on 1 January (periodic year).
% One charger per vehicle is assumed here; ev_queue_check.m checks a
% limited number of chargers.
%   N_ev  : vehicles per day
%   nDays : days in the year (365)
%   par   : mu_arr, sd_arr, arr_win ([earliest latest] arrival, h),
%           mu_dep, sd_dep, dep_win ([earliest latest] departure, h of next day),
%           soc0_min, soc0_max, soc_target, E_bat (kWh), P_ch (kW), eta (-)
%   P_ev  : nDays*24 x 1 hourly charging power seen by the grid (kW)
%   S     : table, one row per session: arrival, departure, start and end
%           of charging (h from the start of day d), requested and delivered energy
%   info  : energy check and occupancy statistics
% Chapter 2, Section 2.4
dt  = 1/60;                                   % 1-minute resolution (h)
nT  = round(nDays*24/dt);                     % minutes in the year
P_min = zeros(nT, 1);                         % grid-side power, minute by minute
plug  = zeros(nT, 1);                         % vehicles parked and plugged in
chg   = zeros(nT, 1);                         % vehicles actually charging
nS = N_ev*nDays;
[day, t_arr, t_dep, t_start, t_end, E_req, E_del] = deal(zeros(nS,1));
s = 0;
for d = 1:nDays
    for k = 1:N_ev
        s = s + 1;
        a = trunc_normal(par.mu_arr, par.sd_arr, par.arr_win);       % h, day d
        b = 24 + trunc_normal(par.mu_dep, par.sd_dep, par.dep_win);  % h, next day
        soc0 = par.soc0_min + (par.soc0_max - par.soc0_min)*rand;
        Ereq = (par.soc_target - soc0) * par.E_bat / par.eta;        % kWh from the grid
        ia = ceil(a/dt);                      % minutes elapsed at the first full minute
        nP = floor(b/dt) - ia;                % full minutes between arrival and departure
        Edel = min(Ereq, par.P_ch * nP * dt); % limited by the dwell time
        xm = Edel / (par.P_ch * dt);          % minutes of full power needed
        nF = min(floor(xm + 1e-9), nP);       % complete minutes at full power
        f  = min(max(xm - nF, 0), 1);         % fraction of power in the last minute
        if nF >= nP, f = 0; end
        i0 = (d-1)*24/dt + ia + 1;            % first charging minute (year index)
        ip = wrap(i0:i0+nP-1, nT);  ic = wrap(i0:i0+nF-1, nT);
        plug(ip) = plug(ip) + 1;
        chg(ic)  = chg(ic) + 1;
        P_min(ic) = P_min(ic) + par.P_ch;
        if f > 0
            j = wrap(i0+nF, nT);
            chg(j)   = chg(j) + 1;
            P_min(j) = P_min(j) + f*par.P_ch;
        end
        day(s) = d;  t_arr(s) = a;  t_dep(s) = b;  E_req(s) = Ereq;
        t_start(s) = ia*dt;  t_end(s) = (ia + nF + f)*dt;
        E_del(s) = (nF + f) * par.P_ch * dt;
    end
end
P_ev = mean(reshape(P_min, 60, []), 1)';        % hourly average (kW)
S = table(day, t_arr, t_dep, t_start, t_end, E_req, E_del);
info.E_req      = sum(E_req);
info.E_del      = sum(E_del);
info.E_profile  = sum(P_ev);                    % 1-h steps: kW summed = kWh
info.n_short    = sum(E_del < E_req - 1e-9);    % sessions not fully charged
info.max_plugged  = max(plug);
info.max_charging = max(chg);
% physical checks (all must be true)
info.ok_after_arrival  = all(t_start >= t_arr);
info.ok_before_depart  = all(t_end <= t_dep + 1e-12);
info.ok_not_above_req  = all(E_del <= E_req + 1e-9);
info.ok_profile_energy = abs(info.E_profile - info.E_del) <= 1e-6 * info.E_del;
end

function x = trunc_normal(mu, sd, win)
% Normal sample restricted to [win(1), win(2)] by rejection (no wrapping).
x = mu + sd*randn;
while x < win(1) || x > win(2), x = mu + sd*randn; end
end

function i = wrap(i, n)
% Minutes after the end of the year continue on 1 January (periodic year).
i = mod(i - 1, n) + 1;
end
