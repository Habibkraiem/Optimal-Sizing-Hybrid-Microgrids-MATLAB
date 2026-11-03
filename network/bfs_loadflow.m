function [V, Ploss_kW, Ibr] = bfs_loadflow(br, P_kW, Q_kvar, net)
% BFS_LOADFLOW  Backward-forward sweep load flow for radial networks.
%   br     : nbr x 4 matrix [from to R(ohm) X(ohm)], ordered so that every
%            branch appears after the branch feeding its sending bus
%            (load_ieee33 returns it in this order)
%   P_kW   : nbus x 1 net active load at each bus (kW), negative = injection
%   Q_kvar : nbus x 1 net reactive load (kvar)
%   net    : struct with Vbase_kV, Sbase_MVA, tol, maxIt
% Bus 1 is the substation (V = 1 p.u.).  Chapter 10, Section 10.2
Zb  = net.Vbase_kV^2 / net.Sbase_MVA;          % base impedance (ohm)
Z   = (br(:,3) + 1j*br(:,4)) / Zb;             % per unit
S   = (P_kW(:) + 1j*Q_kvar(:)) / (1000*net.Sbase_MVA);
from = br(:,1);  to = br(:,2);
nb  = numel(P_kW);  nbr = size(br,1);
V   = ones(nb,1);                              % flat start

for it = 1:net.maxIt
    Inode = conj(S ./ V);                      % 1. load currents
    Ibr   = zeros(nbr,1);
    for b = nbr:-1:1                           % 2. backward sweep
        Ibr(b) = Inode(to(b));
        Inode(from(b)) = Inode(from(b)) + Ibr(b);
    end
    Vold = V;
    for b = 1:nbr                              % 3. forward sweep
        V(to(b)) = V(from(b)) - Z(b) * Ibr(b);
    end
    if max(abs(V - Vold)) < net.tol, break; end   % 4. convergence
end
Ploss_kW = sum(real(Z) .* abs(Ibr).^2) * 1000 * net.Sbase_MVA;
end
