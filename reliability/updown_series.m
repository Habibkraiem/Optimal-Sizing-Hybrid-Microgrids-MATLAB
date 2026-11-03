function a = updown_series(N, MTTF, MTTR, up0)
% UPDOWN_SERIES  Two-state (up/down) availability of a component, hour by hour.
% Times to failure and to repair are exponential (continuous time). Each
% down interval [t1, t2) is mapped onto the hourly grid by its overlap with
% every hour it touches, so short failures are kept, not rounded away.
%   N    : number of hours
%   MTTF : mean time to failure (h);  MTTR : mean time to repair (h)
%   up0  : state at t = 0 (optional, default true = available). With
%          up0 = false the year starts in a repair of random length.
%   a    : N x 1, fraction of each hour during which the component is
%          available (1 = up all hour, 0 = down all hour)
% Events after hour N are not simulated: a repair still running at the end
% of the year is cut at N (no wrap to 1 January).
% Chapter 11, Section 11.4
if nargin < 4, up0 = true; end
a = ones(N, 1);  t = 0;
if ~up0
    t2 = min(N, -MTTR * log(rand));
    a = remove_interval(a, 0, t2);  t = t2;
end
while t < N
    t1 = t + (-MTTF * log(rand));            % failure time (h)
    if t1 >= N, break; end
    t2 = min(N, t1 + (-MTTR * log(rand)));   % end of repair (h)
    a = remove_interval(a, t1, t2);
    t = t2;
end
a = min(max(a, 0), 1);
end

function a = remove_interval(a, t1, t2)
% subtract the overlap of [t1, t2) with each hour [h-1, h)
for h = floor(t1)+1 : ceil(t2)
    a(h) = a(h) - (min(t2, h) - max(t1, h-1));
end
end
