function W = download_nasa_power(lat, lon, yr, tz)
% DOWNLOAD_NASA_POWER  One year of hourly weather data from NASA POWER.
%   W = download_nasa_power(lat, lon, yr, tz)
%   lat, lon : site coordinates (decimal degrees, east and north positive)
%   yr       : calendar year (use a non-leap year, e.g. 2023, to get 8760 hours)
%   tz       : local time zone, e.g. 'Asia/Riyadh'
%   W        : timetable in LOCAL time with columns
%              G   (W/m^2)  all-sky irradiance on a horizontal surface
%              Ta  (degC)   air temperature at 2 m
%              v10 (m/s)    wind speed at 10 m
%              v50 (m/s)    wind speed at 50 m
% The raw CSV file is also saved in data/ for reference.
% Source: NASA POWER (https://power.larc.nasa.gov), community RE, hourly.
% Chapter 2, Section 2.2

if nargin < 4, tz = 'Asia/Riyadh'; end
params = 'ALLSKY_SFC_SW_DWN,T2M,WS10M,WS50M';

% Request in UTC from 31 December of the previous year, so that the whole
% local year is covered after the time-zone conversion.
startStr = sprintf('%04d1231', yr-1);
endStr   = sprintf('%04d1231', yr);
url = sprintf(['https://power.larc.nasa.gov/api/temporal/hourly/point?' ...
    'parameters=%s&community=RE&longitude=%.4f&latitude=%.4f' ...
    '&start=%s&end=%s&format=CSV&time-standard=UTC'], ...
    params, lon, lat, startStr, endStr);

if ~exist('data', 'dir'), mkdir('data'); end
fname = fullfile('data', sprintf('nasa_power_%.2f_%.2f_%d.csv', lat, lon, yr));
fprintf('Downloading NASA POWER data (this can take up to a minute)...\n');
websave(fname, url, weboptions('Timeout', 180));

% --- Skip the text header (between -BEGIN HEADER- and -END HEADER-)
txt   = fileread(fname);
lines = regexp(txt, '\r?\n', 'split');
iEnd  = find(contains(lines, '-END HEADER-'), 1);
if isempty(iEnd)
    error('download_nasa_power:format', ...
          'Unexpected file format. Open %s to read the server message.', fname);
end
opts = detectImportOptions(fname, 'NumHeaderLines', iEnd);
R = readtable(fname, opts);

% --- Time axis: UTC -> local time
t = datetime(R.YEAR, R.MO, R.DY, R.HR, 0, 0, 'TimeZone', 'UTC');
t.TimeZone = tz;

W = timetable(t, R.ALLSKY_SFC_SW_DWN, R.T2M, R.WS10M, R.WS50M, ...
              'VariableNames', {'G','Ta','v10','v50'});

% --- Keep exactly the local calendar year
t0 = datetime(yr,   1, 1, 0, 0, 0, 'TimeZone', tz);
t1 = datetime(yr+1, 1, 1, 0, 0, 0, 'TimeZone', tz);
W  = W(W.t >= t0 & W.t < t1, :);

% --- Missing values (-999) and simple cleaning (Section 2.5)
W = standardizeMissing(W, -999);
W.G(W.G < 0) = 0;
nMiss = sum(ismissing(W));
W = fillmissing(W, 'linear');
fprintf('Rows: %d hours. Missing values filled: G %d, Ta %d, v10 %d, v50 %d\n', ...
        height(W), nMiss(1), nMiss(2), nMiss(3), nMiss(4));
if height(W) ~= 8760
    warning('download_nasa_power:hours', ...
            'Got %d hours (leap year?). The book assumes 8760; choose a non-leap year.', height(W));
end
end
