% ch03_wind_curve.m  -  cubic approximation against a tabulated power curve
% (Section 3.2). The tabulated curve below is ILLUSTRATIVE, shaped like the
% datasheets of small 20 kW turbines: replace it with the curve of the
% turbine you plan to install. Results: results/ch03_wind_curve.txt
clear; clc; addpath(genpath(pwd));
load('data/site_profiles.mat', 'TT');
[par, ~] = load_parameters();
wc = par.wt;                                          % cubic model
wt = par.wt;                                          % tabulated model
wt.curve_v = [3   4   5   6   7   8   9    10   11   12   13 25];
wt.curve_P = [0 0.6 1.6 3.0 4.9 7.3 10.2 13.5 16.8 19.2 20 20];
v = (3:13)';
fid = fopen('results/ch03_wind_curve.txt', 'w');
fprintf(fid, 'v (m/s) | cubic (kW) | tabulated (kW)\n');
for k = 1:numel(v)
    fprintf(fid, '%7d | %10.1f | %14.1f\n', v(k), wind_model(v(k),1,wc), wind_model(v(k),1,wt));
end
Ec = sum(wind_model(TT.v_hub, 1, wc));  Et = sum(wind_model(TT.v_hub, 1, wt));
fprintf(fid, 'Annual energy of one turbine at the case-study site (hub-height wind of Chapter 9):\n');
fprintf(fid, 'cubic %.0f kWh (capacity factor %.1f %%) | tabulated %.0f kWh (%.1f %%) | difference %+.1f %%\n', ...
        Ec, 100*Ec/(8760*wc.Pr), Et, 100*Et/(8760*wt.Pr), 100*(Ec - Et)/Et);
fprintf(fid, 'Mean hub-height wind speed: %.2f m/s\n', mean(TT.v_hub));
fclose(fid);  type('results/ch03_wind_curve.txt');
