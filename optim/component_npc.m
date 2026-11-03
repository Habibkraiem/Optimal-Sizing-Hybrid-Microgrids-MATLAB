function npc = component_npc(n_units, c, life, i, N)
% COMPONENT_NPC  Net present cost of one component, with replacements and salvage.
%   n_units : size of the component (kW, kWh or number of units)
%   c       : struct with cap, om, rep (cost per unit of size, USD)
%   life    : component lifetime (years)
%   i, N    : real discount rate and project lifetime (years)
% Chapter 5, Section 5.5
cap = c.cap * n_units;
om  = sum(c.om * n_units ./ (1+i).^(1:N));

rep = 0;  y = life;
while y < N                                   % replacements during the project
    rep = rep + c.rep * n_units / (1+i)^y;
    y   = y + life;
end
last_install = y - life;                      % year the last unit was installed
remaining    = life - (N - last_install);     % years of life left at the end
salvage = c.rep * n_units * remaining / life / (1+i)^N;

npc = cap + om + rep - salvage;
end
