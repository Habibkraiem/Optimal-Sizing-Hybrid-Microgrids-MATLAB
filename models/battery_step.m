function [P_act, SOC_new, E_sd] = battery_step(P_req, SOC, E_bat, par)
% BATTERY_STEP  One-hour battery update with power, SOC and efficiency limits.
% Sign convention (used everywhere in the book): P > 0 charging, P < 0
% discharging, measured at the battery terminals (DC side).
%   P_req > 0 : charging request (kW);  P_req < 0 : discharging request (kW)
%   SOC       : state of charge at the start of the hour (0..1)
%   E_bat     : energy capacity (kWh)
%   par       : struct with fields Pmax, SOCmin, SOCmax, eta_ch, eta_dis, sigma
%   P_act     : power actually absorbed (>0) or delivered (<0), kW
%   SOC_new   : state of charge at the end of the hour
%   E_sd      : energy lost by self-discharge during the hour (kWh)
% Order inside the hour: self-discharge first, then charge or discharge.
% Self-discharge (fraction sigma per hour) acts only down to SOCmin: it never
% takes the battery out of its window, and it never adds energy. Below
% SOCmin the cells are disconnected by the BMS and the loss is neglected.
% Chapter 3, Section 3.3
dt  = 1;                                    % hour
if E_bat <= 0
    P_act = 0;  SOC_new = SOC;  E_sd = 0;  return;
end
SOC_sd = max(SOC * (1 - par.sigma), min(SOC, par.SOCmin));   % self-discharge
E_sd   = (SOC - SOC_sd) * E_bat;
SOC    = SOC_sd;
if P_req >= 0                               % --- charging
    P_room  = max(0, (par.SOCmax - SOC) * E_bat / (par.eta_ch * dt));
    P_act   = min([P_req, par.Pmax, P_room]);
    SOC_new = SOC + par.eta_ch * P_act * dt / E_bat;
else                                        % --- discharging
    P_avail = max(0, (SOC - par.SOCmin) * E_bat * par.eta_dis / dt);
    P_act   = -min([-P_req, par.Pmax, P_avail]);
    SOC_new = SOC + P_act * dt / (par.eta_dis * E_bat);
end
SOC_new = min(max(SOC_new, min(SOC, par.SOCmin)), max(SOC, par.SOCmax));  % rounding guard
end
