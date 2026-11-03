classdef BudgetFitness < handle
% BUDGETFITNESS  Wraps a fitness function with an evaluation budget, so that
% different algorithms can be compared at equal numbers of evaluations.
% Chapter 8, Section 8.4
    properties
        f; budget; count = 0; best = inf; history = [];
    end
    methods
        function obj = BudgetFitness(f, budget)
            obj.f = f;  obj.budget = budget;
        end
        function F = eval(obj, x)
            if obj.count >= obj.budget
                F = inf; return;                  % budget exhausted
            end
            obj.count = obj.count + 1;
            F = obj.f(x);
            obj.best = min(obj.best, F);
            obj.history(end+1) = obj.best;        % best-so-far vs evaluations
        end
    end
end
