function [gbest, gval, curve] = rda(fobj, lb, ub, opt)
% RDA  Red Deer Algorithm -- SIMPLIFIED EDUCATIONAL VERSION (Chapter 8, Section 8.3).
%   opt: N, maxIt, nMale, gamma, alpha, beta, step (fraction of range)
% Simplifications: symmetric random steps for roar/fight/mating, and
% elitist selection of the next generation. For research, use an
% implementation that follows the original paper exactly.
% This version caches the hinds' fitness (Exercise 4 of Chapter 8).
D = numel(lb);  N = opt.N;  R = ub - lb;
clip = @(z) max(min(z, ub), lb);
move = @() (rand(1,D) - 0.5) .* R * opt.step;      % random local step
X = lb + rand(N,D).*R;
F = arrayfun(@(i) fobj(X(i,:)), (1:N)');
curve = zeros(opt.maxIt,1);

for k = 1:opt.maxIt
    [F, idx] = sort(F);  X = X(idx,:);
    M  = X(1:opt.nMale,:);  FM = F(1:opt.nMale);     % 2. males
    H  = X(opt.nMale+1:end,:);                       %    hinds
    hF = F(opt.nMale+1:end);                         %    their (cached) fitness
    nH = size(H,1);

    for i = 1:size(M,1)                              % 3. roar
        c = clip(M(i,:) + move());  fc = fobj(c);
        if fc < FM(i), M(i,:) = c; FM(i) = fc; end
    end

    [FM, ix] = sort(FM);  M = M(ix,:);               % 4. commanders / stags
    nC = max(1, round(opt.gamma * size(M,1)));
    C = M(1:nC,:);  FC = FM(1:nC);  S = M(nC+1:end,:);  FS = FM(nC+1:end);

    for c = 1:nC                                     % 5. fight
        if isempty(S), break; end
        s = randi(size(S,1));  mid = (C(c,:) + S(s,:))/2;  b = move();
        cand = [C(c,:); S(s,:); clip(mid + b); clip(mid - b)];
        fc   = [FC(c); FS(s); fobj(cand(3,:)); fobj(cand(4,:))];
        [FC(c), ib] = min(fc);  C(c,:) = cand(ib,:);
    end

    pw = max(FC) - FC + eps;  pw = pw / sum(pw);     % 6. harems by power
    nh = floor(pw * nH);  nh(1) = nh(1) + nH - sum(nh);
    perm  = randperm(nH);
    harem = mat2cell(perm(:), nh(:), 1);

    O = zeros(0, D);                                 % offspring
    for c = 1:nC
        hc  = harem{c};                              % 7. mate in own harem
        sel = hc(randperm(numel(hc), ceil(opt.alpha*numel(hc))));
        for jj = 1:numel(sel)
            O(end+1,:) = clip((C(c,:) + H(sel(jj),:))/2 + move()); %#ok<AGROW>
        end
        if nC > 1                                    % 8. another harem
            c2 = randi(nC);  while c2 == c, c2 = randi(nC); end
            h2  = harem{c2};
            sel = h2(randperm(numel(h2), ceil(opt.beta*numel(h2))));
            for jj = 1:numel(sel)
                O(end+1,:) = clip((C(c,:) + H(sel(jj),:))/2 + move()); %#ok<AGROW>
            end
        end
    end
    for s = 1:size(S,1)                              % 9. stags mate
        [~, jn] = min(sum((H - S(s,:)).^2, 2));
        O(end+1,:) = clip((S(s,:) + H(jn,:))/2 + move()); %#ok<AGROW>
    end
    FO = arrayfun(@(i) fobj(O(i,:)), (1:size(O,1))');

    pool  = [C; S; H; O];  fpool = [FC; FS; hF; FO];
    [fpool, ip] = sort(fpool);                       % 10. selection
    X = pool(ip(1:N),:);  F = fpool(1:N);
    gbest = X(1,:);  gval = F(1);  curve(k) = gval;
end
end
