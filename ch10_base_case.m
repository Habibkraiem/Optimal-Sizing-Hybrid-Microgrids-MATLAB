% ch10_base_case.m  -  validate the IEEE 33-bus base case (Chapter 10)
% Requires MATPOWER on the path (for case33bw). Expected: losses about
% 202.7 kW and minimum voltage about 0.913 p.u. at bus 18.
clear; clc; close all; addpath(genpath(pwd));
[br, Pd, Qd, Vb] = load_ieee33();
net = struct('Vbase_kV',Vb, 'Sbase_MVA',1, 'tol',1e-8, 'maxIt',100);
[V, Ploss] = bfs_loadflow(br, Pd, Qd, net);
[Vmin, imin] = min(abs(V));
fprintf('Total load: %.0f kW, %.0f kvar\n', sum(Pd), sum(Qd));
fprintf('Losses: %.1f kW,  Vmin = %.4f p.u. at bus %d\n', Ploss, Vmin, imin);

figure('Color','w');
plot(1:33, abs(V), '-o', 'LineWidth', 1.2); grid on;
xlabel('Bus'); ylabel('Voltage (p.u.)'); title('IEEE 33-bus base case');
