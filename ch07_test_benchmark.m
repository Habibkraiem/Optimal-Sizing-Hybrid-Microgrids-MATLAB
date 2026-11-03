% ch07_test_benchmark.m  -  validate PSO on the Rastrigin function (Chapter 7)
clear; clc; close all; addpath(genpath(pwd));
rastrigin = @(x) 10*numel(x) + sum(x.^2 - 10*cos(2*pi*x));
D = 5;  lb = -5.12*ones(1,D);  ub = 5.12*ones(1,D);
opt = struct('N',30, 'maxIt',300, 'wmax',0.9, 'wmin',0.4, ...
             'c1',2, 'c2',2, 'vfrac',0.2);
rng(1);
[xbest, fbest, curve] = pso(rastrigin, lb, ub, opt);
fprintf('Best value: %.4g at x = %s\n', fbest, mat2str(xbest, 3));
semilogy(max(curve, eps), 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Best fitness'); title('PSO on Rastrigin (D = 5)');
