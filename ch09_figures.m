% ch09_figures.m  -  Figures 9.1 to 9.7 of the case study, as 300-dpi PNG
% files in results/figures (one measure per axis, grayscale-readable lines).
clear; close all; addpath(genpath(pwd));
if ~exist('results/figures', 'dir'), mkdir('results/figures'); end
load('data/site_profiles.mat', 'TT');
[par, eco] = load_parameters();
B = load('results/best_design.mat', 'res');  res = B.res;  s = res.out.series;
c1 = [42 120 214]/255;  c2 = [235 104 52]/255;  c3 = [27 175 122]/255;  c4 = [237 161 0]/255;
ink = [0.32 0.32 0.31];
set(groot, 'defaultAxesFontSize', 10, 'defaultLineLineWidth', 1.4, ...
    'defaultAxesXColor', ink, 'defaultAxesYColor', ink, 'defaultAxesGridAlpha', 0.15);
t  = TT.Properties.RowTimes;  mo = month(t);  hr = hour(t) + 1;  yr = year(t(1));
mon = {'J','F','M','A','M','J','J','A','S','O','N','D'};
save_fig = @(f, name) exportgraphics(f, fullfile('results','figures',name), 'Resolution', 300);

%% Figure 9.1 - monthly solar and wind resource (two panels, no dual axis)
irr = accumarray(mo, TT.G)/1000 ./ eomday(yr, (1:12)');
wnd = accumarray(mo, TT.v_hub, [], @mean);
f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 11]);
subplot(2,1,1); bar(irr, 0.6, 'FaceColor', c4, 'EdgeColor','none'); grid on; box off;
ylabel('kWh/m^2/day'); title('Daily solar irradiation (monthly mean)'); xticks(1:12); xticklabels(mon);
subplot(2,1,2); bar(wnd, 0.6, 'FaceColor', c1, 'EdgeColor','none'); grid on; box off;
ylabel('m/s'); title('Wind speed at 30 m hub height (monthly mean)'); xticks(1:12); xticklabels(mon);
save_fig(f, 'fig9_1_resource.png');

%% Figure 9.2 - typical January and July days
pv1 = pv_model(TT.G, TT.Ta, 1, par.pv);                 % kW per kW installed
wt1 = wind_model(TT.v_hub, 1, par.wt);                   % kW per turbine
prof = @(x, m) accumarray(hr(mo == m), x(mo == m), [24 1], @mean);
f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 12]);
mlist = [1 7];  mname = {'January','July'};
for k = 1:2
    m = mlist(k);
    subplot(2,2,k); hold on;
    plot(0:23, prof(TT.P_load, m), '-',  'Color', c1);
    plot(0:23, prof(TT.P_ev,   m), '--', 'Color', c2);
    grid on; box off; xlim([0 23]); ylabel('kW'); title(['Demand, mean ' mname{k} ' day']);
    if k == 1, legend('Load','EV charging','Location','northwest','Box','off'); end
    subplot(2,2,k+2); hold on;
    plot(0:23, prof(pv1, m), '-',  'Color', c4);
    plot(0:23, prof(wt1, m)/par.wt.Pr, '--', 'Color', c3);
    grid on; box off; xlim([0 23]); ylim([0 1]); xlabel('Hour'); ylabel('kW per kW installed');
    title(['Production, mean ' mname{k} ' day']);
    if k == 1, legend('PV','Wind','Location','northwest','Box','off'); end
end
save_fig(f, 'fig9_2_typical_days.png');

%% Figure 9.3 - annual energy balance (MWh/year)
E = [sum(s.P_ren), sum(s.P_dem) - sum(s.P_unmet), sum(max(-s.P_bat,0)), sum(s.P_dump), sum(s.P_unmet)] / 1000;
lab = {'Renewable production','Demand served','Battery discharge','Curtailed','Unserved'};
f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 8]);
barh(E(end:-1:1), 0.55, 'FaceColor', c1, 'EdgeColor','none'); grid on; box off;
yticks(1:5); yticklabels(lab(end:-1:1)); xlabel('MWh/year');
for k = 1:5, text(E(6-k) + max(E)*0.01, k, sprintf('%.0f', E(6-k)), 'Color', ink, 'FontSize', 9); end
title('Annual energy balance of the optimal design');
save_fig(f, 'fig9_3_energy_balance.png');

%% Figure 9.4 - one winter and one summer week of operation
f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 12]);
wk = {find(t >= datetime(yr,1,8,'TimeZone',t.TimeZone), 1) + (0:167), ...
      find(t >= datetime(yr,7,8,'TimeZone',t.TimeZone), 1) + (0:167)};
wname = {'Winter week (8-14 January)','Summer week (8-14 July)'};
yTop = 1.45*max(max(s.P_ren([wk{:}])), max(s.P_dem([wk{:}])));   % same scale, room for the legend
for k = 1:2
    w = wk{k};  hh = 0:167;
    subplot(2,2,k); hold on;
    plot(hh, s.P_ren(w), '-',  'Color', c4);
    plot(hh, s.P_dem(w), '--', 'Color', c1);
    if any(s.P_unmet(w) > 0), plot(hh, s.P_unmet(w), ':', 'Color', c2, 'LineWidth', 2); end
    grid on; box off; xlim([0 167]); xticks(0:24:168); ylim([0 yTop]); ylabel('kW'); title(wname{k});
    if k == 1, legend('Renewables','Demand','Unserved','Location','northwest','Box','off'); end
    subplot(2,2,k+2);
    plot(hh, 100*s.SOC(w), '-', 'Color', c3); grid on; box off;
    xlim([0 167]); xticks(0:24:168); ylim([0 100]); xlabel('Hour of the week'); ylabel('Battery SOC (%)');
end
save_fig(f, 'fig9_4_operation_weeks.png');

%% Figure 9.5 - battery state of charge over the year (daily min and max)
socd = reshape(100*s.SOC, 24, []);
f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 7]);
d = 1:size(socd,2);
fill([d fliplr(d)], [min(socd) fliplr(max(socd))], c3, 'FaceAlpha', 0.35, 'EdgeColor','none');
grid on; box off; xlim([1 365]); ylim([0 100]); xlabel('Day of the year'); ylabel('SOC (%)');
title(sprintf('Battery SOC range per day  (%.0f equivalent cycles/year, %.0f-year life)', ...
      res.out.N_eq, res.life_bat));
save_fig(f, 'fig9_5_soc_year.png');

%% Figure 9.6 - mean convergence of the four algorithms
C = load('results/case_study_runs.mat', 'hist', 'names', 'bestF');
best = min(C.bestF(:));  [nR, nA] = size(C.hist);  nE = max(cellfun(@numel, C.hist(:)));
f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 9]); hold on;
cols = {c1, c2, c3, c4};  sty = {'-','--','-.',':'};
for a = 1:nA
    H = nan(nR, nE);
    for r = 1:nR, h = C.hist{r,a}; H(r,1:numel(h)) = h; H(r,numel(h)+1:end) = h(end); end
    gap = 100*(mean(H, 1, 'omitnan') - best)/best;
    plot(1:nE, max(gap, 1e-4), sty{a}, 'Color', cols{a});
end
set(gca, 'YScale', 'log'); grid on; box off; xlim([0 nE]); ylim([1e-3 100]);
xlabel('Function evaluations'); ylabel('Mean gap to best NPC (%)');
legend(C.names, 'Location','northeast', 'Box','off');
title('Mean convergence over 30 runs');
save_fig(f, 'fig9_6_convergence.png');

%% Figure 9.7 - cost-reliability Pareto front
if exist('results/pareto.mat', 'file')
    P = load('results/pareto.mat');
    [lp, ix] = sort(100*P.LPSP);  np = P.NPC(ix)/1e6;
    f = figure('Color','w', 'Units','centimeters', 'Position',[2 2 16 9]); hold on;
    plot(lp, np, '-o', 'Color', c1, 'MarkerFaceColor', c1, 'MarkerSize', 6);
    [~, k1] = min(abs(lp - 100*res.LPSP));
    plot(lp(k1), np(k1), 'o', 'MarkerSize', 11, 'Color', c2, 'LineWidth', 2);
    text(lp(k1), np(k1), '   chosen design (LPSP = 1 %)', 'Color', ink, 'FontSize', 9);
    grid on; box off; xlabel('LPSP (%)'); ylabel('NPC (million USD)');
    title('Cost of reliability: Pareto front (\epsilon-constraint)');
    save_fig(f, 'fig9_7_pareto.png');
end
disp('=== FIGURES DONE ===')
