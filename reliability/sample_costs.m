function [par, eco] = sample_costs(par, eco, r)
% SAMPLE_COSTS  Draw every capital, O&M and replacement cost uniformly within
% +/- r (for example r = 0.2 for +/-20 %) of its base value. Each component
% gets its own factor; capital, O&M and replacement of one component move
% together (one market price). Technical parameters are not changed.
% Chapter 11, Section 11.3
for f = {'pv','wt','bat','conv','ch'}
    k = 1 + r*(2*rand - 1);
    eco.(f{1}).cap = eco.(f{1}).cap * k;
    eco.(f{1}).om  = eco.(f{1}).om  * k;
    eco.(f{1}).rep = eco.(f{1}).rep * k;
end
end
