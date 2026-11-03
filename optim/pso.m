function [gbest, gbest_val, curve] = pso(fobj, lb, ub, opt)
% PSO  Particle Swarm Optimization with linearly decreasing inertia.
%   fobj : handle, F = fobj(x) with x a 1xD row vector (to minimize)
%   lb,ub: 1xD lower and upper bounds
%   opt  : struct with fields N (particles), maxIt, wmax, wmin, c1, c2, vfrac
% Chapter 7, Section 7.3
D = numel(lb);                                % number of variables
N = opt.N;
vmax = opt.vfrac * (ub - lb);                 % max velocity per variable

% ---- 1. Initialization -------------------------------------------
X = lb + rand(N, D) .* (ub - lb);             % random positions in bounds
V = zeros(N, D);                              % start at rest
F = zeros(N, 1);
for i = 1:N
    F(i) = fobj(X(i,:));                      % 2. evaluate each particle
end

% ---- 3. Personal and global bests --------------------------------
P = X;  Pval = F;                             % personal bests
[gbest_val, ig] = min(Pval);
gbest = P(ig,:);                              % global best
curve = zeros(opt.maxIt, 1);

% ---- 4. Main loop -------------------------------------------------
for k = 1:opt.maxIt
    w = opt.wmax - (opt.wmax - opt.wmin) * k / opt.maxIt;   % inertia decreases

    for i = 1:N
        r1 = rand(1, D);  r2 = rand(1, D);
        % 4.1 velocity update
        V(i,:) = w*V(i,:) ...
               + opt.c1 * r1 .* (P(i,:) - X(i,:)) ...
               + opt.c2 * r2 .* (gbest  - X(i,:));
        % 4.2 velocity clamping
        V(i,:) = max(min(V(i,:), vmax), -vmax);
        % 4.3 move and keep inside bounds
        X(i,:) = X(i,:) + V(i,:);
        X(i,:) = max(min(X(i,:), ub), lb);
        % 4.4 evaluate
        F(i) = fobj(X(i,:));
        % 4.5 personal best
        if F(i) < Pval(i)
            P(i,:) = X(i,:);  Pval(i) = F(i);
            % 4.6 global best
            if F(i) < gbest_val
                gbest = X(i,:);  gbest_val = F(i);
            end
        end
    end
    curve(k) = gbest_val;                     % 4.7 convergence curve
end
end
