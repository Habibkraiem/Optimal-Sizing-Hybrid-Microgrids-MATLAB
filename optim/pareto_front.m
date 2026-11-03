function isND = pareto_front(Fobj)
% PARETO_FRONT  Logical mask of non-dominated rows (all objectives minimized).
%   Fobj: n x m matrix of objective values, one row per design
% Chapter 8, Section 8.6
n = size(Fobj,1);  isND = true(n,1);
for i = 1:n
    dom = all(Fobj <= Fobj(i,:), 2) & any(Fobj < Fobj(i,:), 2);
    if any(dom), isND(i) = false; end
end
end
