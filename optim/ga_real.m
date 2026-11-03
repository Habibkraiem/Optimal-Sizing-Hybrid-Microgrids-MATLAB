function [gbest, gbest_val, curve] = ga_real(fobj, lb, ub, opt)
% GA_REAL  Real-coded genetic algorithm with tournament selection,
% blend crossover, Gaussian mutation and elitism.
%   opt: N, maxIt, pc (crossover prob.), pm (mutation prob. per variable), sigma
% Chapter 8, Section 8.1
D = numel(lb);  N = opt.N;
X = lb + rand(N,D).*(ub-lb);
F = arrayfun(@(i) fobj(X(i,:)), (1:N)');
curve = zeros(opt.maxIt,1);
for k = 1:opt.maxIt
    [~, ib] = min(F);  elite = X(ib,:);  elite_val = F(ib);
    Xn = zeros(N,D);
    for i = 1:N
        p1 = tournament(F);  p2 = tournament(F);
        if rand < opt.pc
            beta  = rand(1,D);
            child = beta.*X(p1,:) + (1-beta).*X(p2,:);
        else
            child = X(p1,:);
        end
        m = rand(1,D) < opt.pm;                         % genes to mutate
        child(m) = child(m) + opt.sigma*(ub(m)-lb(m)).*randn(1,nnz(m));
        Xn(i,:) = max(min(child, ub), lb);
    end
    Xn(1,:) = elite;                                    % elitism
    X = Xn;
    F = [elite_val; arrayfun(@(i) fobj(X(i,:)), (2:N)')];
    % row 1 (the elite) keeps its known fitness: N-1 evaluations
    [gbest_val, ib] = min(F);  gbest = X(ib,:);
    curve(k) = gbest_val;
end
end

function idx = tournament(F)
c = randi(numel(F), 1, 2);
if F(c(1)) <= F(c(2)), idx = c(1); else, idx = c(2); end
end
