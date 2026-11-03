function TT = make_demo_data()
% MAKE_DEMO_DATA  Builds a SYNTHETIC one-year dataset (data/site_profiles.mat)
% so that every script can be tested immediately.
% !!! These profiles are invented for testing only. For the book and for any
% study, replace them with real data downloaded from NASA POWER (Chapter 2).
rng(42);

t = datetime(2025,1,1,0,0,0) + hours(0:8759)';   % non-leap year, local time
h = hour(t);                                      % 0..23
d = day(t, 'dayofyear');                          % 1..365

% --- Irradiance (W/m^2): clear-sky bell shape, seasonal, some cloudy days
season = 0.85 + 0.15*cos(2*pi*(d-172)/365);       % stronger in June
hw     = 6 + 1*cos(2*pi*(d-172)/365);             % half day length (h)
x      = h + 0.5 - 12;                            % hours from solar noon
clear_sky = max(0, cos(pi*x ./ (2*hw))) .* (abs(x) < hw);
cday   = 1 - 0.6*(rand(365,1) < 0.12).*rand(365,1);   % ~12 % cloudy days
G      = 1000 * season .* clear_sky .* cday(d);

% --- Ambient temperature (degC): hot summers, daily cycle
Ta = 25 + 12*cos(2*pi*(d-200)/365) + 7*sin(2*pi*(h-9)/24) + randn(8760,1);

% --- Wind speed at 10 m (m/s): seasonal mean, afternoon peak, correlated noise
base = 4.5*(1 + 0.2*cos(2*pi*(d-120)/365));
e    = filter(0.2, [1 -0.8], randn(8760,1));
v10  = max(0, base + 1.2*sin(2*pi*(h-15)/24) + 2*e);
v_hub = v10 * (30/10)^(1/7);                      % hub height 30 m, alpha = 1/7

% --- Load (kW): evening peak, more cooling in summer
s_day   = [0.45 0.40 0.38 0.37 0.38 0.45 0.55 0.60 0.60 0.62 0.65 0.70 ...
           0.72 0.72 0.75 0.80 0.85 0.95 1.00 1.00 0.95 0.85 0.70 0.55];
k_month = [0.75 0.75 0.80 0.90 1.00 1.10 1.15 1.15 1.05 0.90 0.80 0.75];
P_load  = build_load_profile(50, s_day, k_month, 0.85, 0.05);

% --- EV demand (kW): 10 vehicles per day, residential charging
parEV = struct('mu_arr',18, 'sd_arr',2, 'arr_win',[12 23.9], ...
               'mu_dep',7.5, 'sd_dep',1, 'dep_win',[5 10], ...
               'soc0_min',0.2, 'soc0_max',0.6, 'soc_target',0.9, ...
               'E_bat',60, 'P_ch',7, 'eta',0.9);
P_ev = ev_sessions_year(10, 365, parEV);           % chronological sessions (Section 2.4)

TT = timetable(t, G, Ta, v10, v_hub, P_load, P_ev, ...
     'VariableNames', {'G','Ta','v10','v_hub','P_load','P_ev'});
if ~exist('data', 'dir'), mkdir('data'); end
save('data/site_profiles.mat', 'TT');
fprintf('Synthetic demo data saved to data/site_profiles.mat\n');
fprintf('Annual load %.0f MWh, EV %.0f MWh, mean irradiation %.2f kWh/m2/day\n', ...
        sum(P_load)/1000, sum(P_ev)/1000, sum(G)/1000/365);
end
