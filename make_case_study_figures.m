function make_case_study_figures(res, bestF, hist, names)
% MAKE_CASE_STUDY_FIGURES  Basic tables and figures for Chapter 9.
% A starting point: adapt styles and add the figures listed in Section 9.5.
if ~exist('results', 'dir'), mkdir('results'); end
s = res.out.series;

% --- Table: algorithm comparison
T = table(names', min(bestF)', mean(bestF)', max(bestF)', std(bestF)', ...
    'VariableNames', {'Algorithm','Best','Mean','Worst','Std'});
disp(T);
writetable(T, 'results/table_algorithm_comparison.csv');

% --- Figure: mean convergence against evaluations
[nRuns, nA] = size(hist);
budget = max(cellfun(@numel, hist(:)));
fig = figure('Color','w'); hold on;
for a = 1:nA
    H = nan(nRuns, budget);
    for r = 1:nRuns
        h = hist{r,a};  H(r,1:numel(h)) = h;
    end
    plot(1:budget, mean(H, 1, 'omitnan'), 'LineWidth', 1.3);
end
legend(names); grid on; xlabel('Function evaluations'); ylabel('Mean best fitness');
title('Mean convergence'); exportgraphics(fig, 'results/fig_convergence.pdf', 'ContentType','vector');

% --- Figure: one summer week and one winter week of operation
weeks = {1:168, 4345:4512};    % first week of January, first week of July
fig = figure('Color','w');
for k = 1:2
    w = weeks{k};
    subplot(2,1,k);
    yyaxis left;  plot(w, [s.P_ren(w) s.P_dem(w) s.P_unmet(w)]); ylabel('kW');
    yyaxis right; plot(w, s.SOC(w), '--'); ylabel('SOC');
    grid on; xlabel('Hour of the year');
    legend('Renewables','Demand','Unmet','SOC', 'Location','northwest');
end
exportgraphics(fig, 'results/fig_operation_weeks.pdf', 'ContentType','vector');

% --- Figure: annual energy balance
E = [sum(s.P_ren), sum(max(-s.P_bat,0)), sum(s.P_imp), sum(s.P_unmet); ...
     sum(s.P_dem), sum(max(s.P_bat,0)),  sum(s.P_exp), sum(s.P_dump)] / 1000;
fig = figure('Color','w');
bar(categorical({'Supply side','Use side'}), E, 'stacked'); ylabel('MWh/year');
legend({'Renewables / Demand','Battery out / in','Import / Export','Unmet / Curtailed'}, ...
       'Location','eastoutside');
title('Annual energy balance'); grid on;
exportgraphics(fig, 'results/fig_energy_balance.pdf', 'ContentType','vector');
end
