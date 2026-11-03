function prob = define_problem()
% DEFINE_PROBLEM  Bounds and targets of the sizing problem (Chapter 6, Section 6.5).
% EXAMPLE bounds: set them from the physical limits of your site.
%            P_pv  N_wt   E_bat  P_bat  N_ch
prob.lb   = [   0  -0.49     0     0   -0.49];
prob.ub   = [1500  10.49  3000   500   30.49];
prob.names = {'P_pv (kW)','N_wt','E_bat (kWh)','P_bat (kW)','N_ch'};
prob.LPSP_max = 0.01;          % 1 % reliability target (example)
prob.REF_min  = 0;             % no renewable-fraction constraint here
prob.lambda   = 1e9;           % penalty factor (see Section 6.3)
end
