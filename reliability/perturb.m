function [par, eco, TT] = perturb(par, eco, TT, name, s)
% PERTURB  Multiply one assumption by the factor s (one-at-a-time sensitivity).
%   name : 'pv.cap', 'wt.cap', 'bat.cap', 'conv.cap', 'ch.cap' (capital costs),
%          'i' (discount rate), 'c_imp', 'c_exp' (tariffs),
%          'load_scale' (TT.P_load), 'ev_scale' (TT.P_ev),
%          'irr_scale' (TT.G), 'wind_scale' (TT.v_hub)
%   s    : factor, for example 0.8 or 1.2
% Chapter 11, Section 11.1
switch name
    case {'pv.cap','wt.cap','bat.cap','conv.cap','ch.cap'}
        f = strtok(name, '.');
        eco.(f).cap = eco.(f).cap * s;
        eco.(f).rep = eco.(f).rep * s;          % replacements follow the same price
    case {'i','c_imp','c_exp'}
        eco.(name) = eco.(name) * s;
    case 'load_scale'
        TT.P_load = TT.P_load * s;
    case 'ev_scale'
        TT.P_ev = TT.P_ev * s;
    case 'irr_scale'
        TT.G = TT.G * s;
    case 'wind_scale'
        TT.v_hub = TT.v_hub * s;
    otherwise
        error('perturb:name', 'Unknown parameter name: %s', name);
end
end
