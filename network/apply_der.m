function [P, Q] = apply_der(Pd, Qd, bus, inj)
% APPLY_DER  Adds DER injections and EV/battery loads to the bus loads.
%   Pd, Qd : base bus loads at this hour (kW, kvar)
%   bus    : struct with fields pv, wt, bat, ev (bus numbers)
%   inj    : struct with fields pv, wt, bat, ev (kW at this hour)
% Chapter 10, Section 10.3
P = Pd;  Q = Qd;
P(bus.pv)  = P(bus.pv)  - inj.pv;
P(bus.wt)  = P(bus.wt)  - inj.wt;
P(bus.bat) = P(bus.bat) + inj.bat;    % charging > 0, discharging < 0
P(bus.ev)  = P(bus.ev)  + inj.ev;
end
