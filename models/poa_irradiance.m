function G_poa = poa_irradiance(G_h, t, lat, lon, tilt, albedo)
% POA_IRRADIANCE  Hourly irradiance on a tilted, south-facing PV array
% from global horizontal irradiance (Section 3.1).
%   G_h    : global horizontal irradiance (W/m^2), hourly mean, vector
%   t      : local datetime of the START of each hour, with a TimeZone
%   lat, lon : site latitude and longitude (deg, north and east positive)
%   tilt   : array tilt from horizontal (deg); azimuth = due south
%   albedo : ground reflectance (default 0.2)
% Method: Erbs et al. (1982) diffuse fraction, isotropic sky (Liu and
% Jordan, 1963), solar position of Duffie and Beckman. Low sun (zenith
% above 85 deg): the beam is kept as on a horizontal surface.
if nargin < 6, albedo = 0.2; end
G_h = max(G_h(:), 0);
n   = day(t(:), 'dayofyear');
hr  = hour(t(:)) + minute(t(:))/60 + 0.5;               % middle of the hour
utc = hours(tzoffset(t(:)));                            % local offset from UTC (h)
B   = deg2rad((n - 1) * 360/365);
EoT = 229.2*(0.000075 + 0.001868*cos(B) - 0.032077*sin(B) - 0.014615*cos(2*B) - 0.04089*sin(2*B));
ts  = hr + (4*(lon - 15*utc) + EoT)/60;                 % apparent solar time (h)
w   = deg2rad(15*(ts - 12));                            % hour angle
dec = deg2rad(23.45*sin(deg2rad(360*(284 + n)/365)));   % declination
p   = deg2rad(lat);  b = deg2rad(tilt);
cz  = sin(p).*sin(dec) + cos(p).*cos(dec).*cos(w);      % cos(zenith)
ct  = sin(dec).*sin(p - b) + cos(dec).*cos(p - b).*cos(w);   % cos(incidence), south-facing
G0  = 1367*(1 + 0.033*cos(deg2rad(360*n/365))) .* max(cz, 0);   % extraterrestrial, horizontal
kt  = zeros(size(G_h));  k = G0 > 0;  kt(k) = min(G_h(k)./G0(k), 1);
fd  = 0.165*ones(size(kt));                             % Erbs diffuse fraction
fd(kt <= 0.22) = 1 - 0.09*kt(kt <= 0.22);
m   = kt > 0.22 & kt <= 0.8;
fd(m) = 0.9511 - 0.1604*kt(m) + 4.388*kt(m).^2 - 16.638*kt(m).^3 + 12.336*kt(m).^4;
G_d = fd .* G_h;  G_b = G_h - G_d;
Rb  = ones(size(G_h));  s = cz > 0.087;
Rb(s) = max(ct(s), 0) ./ cz(s);
G_poa = G_b.*Rb + G_d*(1 + cos(b))/2 + G_h*albedo*(1 - cos(b))/2;
end
