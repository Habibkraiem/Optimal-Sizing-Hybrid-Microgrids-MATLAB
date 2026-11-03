function [gbest, gbest_val, curve] = gwo(fobj, lb, ub, opt)
% GWO  Grey Wolf Optimizer.  opt: N, maxIt
% Chapter 8, Section 8.2
D = numel(lb);  N = opt.N;
X = lb + rand(N,D).*(ub-lb);
F = arrayfun(@(i) fobj(X(i,:)), (1:N)');
[gbest_val, ib] = min(F);  gbest = X(ib,:);
curve = zeros(opt.maxIt,1);
for k = 1:opt.maxIt
    [~, idx] = sort(F);                        % leaders: three best wolves
    Xa = X(idx(1),:);  Xb = X(idx(2),:);  Xd = X(idx(3),:);
    a = 2 - 2*k/opt.maxIt;                     % from 2 to 0
    for i = 1:N
        Xnew = zeros(1,D);
        for L = {Xa, Xb, Xd}
            A  = 2*a*rand(1,D) - a;
            C  = 2*rand(1,D);
            Dl = abs(C.*L{1} - X(i,:));
            Xnew = Xnew + (L{1} - A.*Dl);
        end
        X(i,:) = max(min(Xnew/3, ub), lb);
        F(i)   = fobj(X(i,:));
    end
    [fmin, im] = min(F);
    if fmin < gbest_val, gbest = X(im,:); gbest_val = fmin; end
    curve(k) = gbest_val;
end
end
