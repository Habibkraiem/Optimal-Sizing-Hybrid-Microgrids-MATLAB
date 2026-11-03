function res = design_result(xv, TT, par, eco, prob)
% DESIGN_RESULT  Physical results of one design vector, without penalties:
% NPC (all components), LCOE, LPSP (refused EV energy counted as unserved),
% LOLE and the simulation output. Used by Chapter 11 and the checks of Chapter 9.
[~, res] = fitness(xv, TT, par, eco, prob);
end
