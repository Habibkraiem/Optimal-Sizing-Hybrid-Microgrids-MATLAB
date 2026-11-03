% ch09_fill_values.m  -  computes the remaining values of Chapter 9
% (statistics of the algorithm comparison and the input-data summary).
clear; clc; addpath(genpath(pwd));
if exist('results/ch09_values.txt','file'), delete('results/ch09_values.txt'); end
diary('results/ch09_values.txt');

%% 1. Statistics of the algorithm comparison (Section 8.5)
S = load('results/case_study_runs.mat', 'bestF', 'names');
F = S.bestF;  names = S.names;
[~, ref] = min(mean(F));
fprintf('Reference (best mean): %s\n', names{ref});
others = setdiff(1:numel(names), ref);
p = zeros(size(others));
for k = 1:numel(others)
    p(k) = ranksum(F(:,ref), F(:,others(k)));
end
% Holm correction
[ps, ord] = sort(p);  m = numel(ps);  padj = zeros(size(ps));
for k = 1:m, padj(k) = min(1, max(ps(1:k) .* (m - (1:k) + 1))); end
padj(ord) = padj;
for k = 1:numel(others)
    fprintf('%s vs %s: p = %.3g, Holm-adjusted p = %.3g\n', names{ref}, names{others(k)}, p(k), padj(k));
end
% Kruskal-Wallis: the runs of different algorithms are independent samples
% (each run has its own random stream), so a test for independent samples
% is used. Friedman's test would need blocks (e.g. several test problems).
pKW = kruskalwallis(F, names, 'off');
fprintf('Kruskal-Wallis p = %.3g\n', pKW);
R = tiedrank(F(:));  R = reshape(R, size(F));
for a = 1:numel(names), fprintf('Mean rank %s = %.2f (of %d results)\n', names{a}, mean(R(:,a)), numel(F)); end
% Effect size: Vargha-Delaney A12 = P(reference run better than other run)
for k = 1:numel(others)
    b = others(k);  A = 0;
    for i = 1:size(F,1)
        A = A + sum(F(i,ref) < F(:,b)) + 0.5*sum(F(i,ref) == F(:,b));
    end
    A = A / size(F,1)^2;
    gap = 100*(median(F(:,b)) - median(F(:,ref))) / median(F(:,ref));
    fprintf('A12 %s vs %s = %.3f | median gap %.3f %% of NPC (%.0f USD)\n', names{ref}, names{b}, A, gap, ...
            median(F(:,b)) - median(F(:,ref)));
end
for a = 1:numel(names)
    q = prctile(F(:,a), [25 50 75]);
    fprintf('%s: best %.0f | median %.0f | IQR %.0f-%.0f | worst %.0f | mean %.0f | std %.0f\n', ...
            names{a}, min(F(:,a)), q(2), q(1), q(3), max(F(:,a)), mean(F(:,a)), std(F(:,a)));
end
% All 30 x 4 results, for the repository
T = array2table(F, 'VariableNames', names);  T.seed = (1:size(F,1))';
writetable(T, 'results/all_runs.csv');

%% 2. Input data summary (Table 9.2)
D = load('data/site_profiles.mat');  TT = D.TT;
mn = {'January','February','March','April','May','June','July','August', ...
      'September','October','November','December'};
t  = TT.Properties.RowTimes;  mo = month(t);  yr = year(t(1));
irr = accumarray(mo, TT.G)/1000 ./ eomday(yr, (1:12)');
[a1,i1] = min(irr); [a2,i2] = max(irr);
fprintf('Irradiation monthly mean: min %.2f (%s), max %.2f (%s)\n', a1, mn{i1}, a2, mn{i2});
wm = accumarray(mo, TT.v_hub, [], @mean);
[b1,j1] = min(wm); [b2,j2] = max(wm);
fprintf('Hub wind monthly mean: min %.2f (%s), max %.2f (%s)\n', b1, mn{j1}, b2, mn{j2});
tm = accumarray(mo, TT.Ta, [], @mean);
[c1,k1] = min(tm); [c2,k2] = max(tm);
fprintf('Temperature monthly mean: min %.1f (%s), max %.1f (%s)\n', c1, mn{k1}, c2, mn{k2});
dl = sum(reshape(TT.P_load, 24, []), 1);  de = sum(reshape(TT.P_ev, 24, []), 1);
fprintf('Daily load: mean %.0f, min %.0f, max %.0f kWh/day\n', mean(dl), min(dl), max(dl));
fprintf('Daily EV: mean %.0f, min %.0f, max %.0f kWh/day\n', mean(de), min(de), max(de));
fprintf('Peak load %.1f kW, peak EV %.1f kW\n', max(TT.P_load), max(TT.P_ev));
if isfield(D, 'alpha'), fprintf('Wind shear alpha = %.3f\n', D.alpha); end
diary off
disp('=== CH09 DONE ===')
