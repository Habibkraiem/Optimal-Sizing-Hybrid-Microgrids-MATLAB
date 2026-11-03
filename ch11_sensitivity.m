% ch11_sensitivity.m  -  one-at-a-time sensitivity of the Chapter 9 design
% (Section 11.1): each assumption x0.8 and x1.2, design fixed.
% Run after main.m. Results: results/ch11_sensitivity.txt and a tornado chart.
clear; clc; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par0, eco0] = load_parameters();  prob = define_problem();
S = load('results/case_study_runs.mat', 'bestF', 'bestX');
[~, k] = min(S.bestF(:));  xv = S.bestX{k};
r0 = design_result(xv, TT, par0, eco0, prob);

params = {'pv.cap','bat.cap','conv.cap','ch.cap','i','load_scale','ev_scale','irr_scale'};
n = numel(params);  [Llo, Lhi, Plo, Phi] = deal(zeros(n,1));
for p = 1:n
    for s = [0.8 1.2]
        [par, eco, TTs] = perturb(par0, eco0, TT, params{p}, s);
        r = design_result(xv, TTs, par, eco, prob);
        if s < 1, Llo(p) = r.LCOE; Plo(p) = r.LPSP; else, Lhi(p) = r.LCOE; Phi(p) = r.LPSP; end
    end
end
fid = fopen('results/ch11_sensitivity.txt', 'w');
fprintf(fid, 'Base: LCOE %.4f USD/kWh, NPC %.0f USD, LPSP %.3f %%\n', r0.LCOE, r0.NPC, 100*r0.LPSP);
fprintf(fid, '%-11s | LCOE -20%% | LCOE +20%% | swing  | LPSP -20%% | LPSP +20%%\n', 'parameter');
[~, order] = sort(abs(Lhi - Llo), 'descend');
for p = order'
    fprintf(fid, '%-11s | %9.4f | %9.4f | %6.4f | %8.2f %% | %8.2f %%\n', params{p}, Llo(p), Lhi(p), ...
            abs(Lhi(p)-Llo(p)), 100*Plo(p), 100*Phi(p));
end
fclose(fid);  type('results/ch11_sensitivity.txt');

[~, order] = sort(abs(Lhi - Llo), 'ascend');
figure('Color','w');
barh(1:n, [Llo(order) Lhi(order)] - r0.LCOE);
set(gca, 'YTick', 1:n, 'YTickLabel', params(order), 'TickLabelInterpreter', 'none'); xline(0, 'k');
xlabel('Change in LCOE from base (USD/kWh)'); legend('-20 %', '+20 %', 'Location', 'southeast');
title('Sensitivity of LCOE (design fixed)');
exportgraphics(gcf, 'results/fig_tornado.png', 'Resolution', 200);
