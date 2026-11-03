function W = load_weather_years(TT, folder)
% LOAD_WEATHER_YEARS  Cell array of yearly timetables for Monte Carlo (Section 11.3).
% Looks for files weather_YYYY.mat in FOLDER (default 'data'), each holding a
% timetable TT with columns G, Ta, v_hub (8760 rows), for example made with
% download_nasa_power.m for several years. The load and EV columns of the
% case study are copied into each year, so only the weather changes.
% If no file is found, W = {TT} and a warning is printed: the Monte Carlo
% then samples load and costs only.
if nargin < 2, folder = 'data'; end
f = dir(fullfile(folder, 'weather_*.mat'));
W = {};
for k = 1:numel(f)
    S = load(fullfile(folder, f(k).name), 'TT');
    if height(S.TT) ~= height(TT), continue; end   % skip leap years
    Y = TT;
    Y.G = S.TT.G;  Y.Ta = S.TT.Ta;  Y.v_hub = S.TT.v_hub;
    W{end+1} = Y; %#ok<AGROW>
end
if isempty(W)
    warning('load_weather_years:none', ...
        'No data/weather_YYYY.mat files: only the case-study year is used.');
    W = {TT};
end
end
