function [br, Pd_kW, Qd_kvar, Vbase_kV] = load_ieee33()
% LOAD_IEEE33  IEEE 33-bus radial feeder (Baran & Wu, 1989) from MATPOWER.
% Requires the free MATPOWER toolbox on the MATLAB path (case33bw.m).
%   br       : [from to R(ohm) X(ohm)] for the 32 in-service branches,
%              ordered from the substation outwards
%   Pd_kW    : 33 x 1 peak active load (kW)
%   Qd_kvar  : 33 x 1 peak reactive load (kvar)
%   Vbase_kV : base voltage (12.66 kV)
% Chapter 10, Section 10.1
if exist('case33bw', 'file') ~= 2
    % MATPOWER not installed: use the data of Baran & Wu (1989), embedded below.
    % Validated: base-case losses 202.7 kW, minimum voltage 0.913 p.u. at bus 18.
    br = [1 2 .0922 .0470; 2 3 .4930 .2511; 3 4 .3660 .1864; 4 5 .3811 .1941;
          5 6 .8190 .7070; 6 7 .1872 .6188; 7 8 .7114 .2351; 8 9 1.0300 .7400;
          9 10 1.0440 .7400; 10 11 .1966 .0650; 11 12 .3744 .1238; 12 13 1.4680 1.1550;
          13 14 .5416 .7129; 14 15 .5910 .5260; 15 16 .7463 .5450; 16 17 1.2890 1.7210;
          17 18 .7320 .5740; 2 19 .1640 .1565; 19 20 1.5042 1.3554; 20 21 .4095 .4784;
          21 22 .7089 .9373; 3 23 .4512 .3083; 23 24 .8980 .7091; 24 25 .8960 .7011;
          6 26 .2030 .1034; 26 27 .2842 .1447; 27 28 1.0590 .9337; 28 29 .8042 .7006;
          29 30 .5075 .2585; 30 31 .9744 .9630; 31 32 .3105 .3619; 32 33 .3410 .5302];
    PQ = [0 0; 100 60; 90 40; 120 80; 60 30; 60 20; 200 100; 200 100; 60 20; 60 20;
          45 30; 60 35; 60 35; 120 80; 60 10; 60 20; 60 20; 90 40; 90 40; 90 40;
          90 40; 90 40; 90 50; 420 200; 420 200; 60 25; 60 25; 60 20; 120 70;
          200 600; 150 70; 210 100; 60 40];
    Pd_kW = PQ(:,1);  Qd_kvar = PQ(:,2);  Vbase_kV = 12.66;
    br = order_radial(br, 1);
    return;
end
mpc = case33bw;
if ~isequal(mpc.bus(:,1)', 1:33)
    error('load_ieee33:numbering', 'Unexpected bus numbering in case33bw.');
end
Vbase_kV = mpc.bus(1, 10);                       % BASE_KV column
Zb  = Vbase_kV^2 / mpc.baseMVA;                  % MATPOWER stores R, X in p.u.
on  = mpc.branch(:, 11) == 1;                    % BR_STATUS: drop open tie lines
br  = [mpc.branch(on,1), mpc.branch(on,2), mpc.branch(on,3)*Zb, mpc.branch(on,4)*Zb];
Pd_kW   = mpc.bus(:,3) * 1000;                   % MW -> kW
Qd_kvar = mpc.bus(:,4) * 1000;                   % Mvar -> kvar
br = order_radial(br, 1);
end

function br2 = order_radial(br, root)
% Orders branches by distance from the root and orients them from -> to.
nbr = size(br,1);  used = false(nbr,1);
br2 = zeros(0,4);  frontier = root;
while ~isempty(frontier)
    nxt = [];
    for b = frontier
        idx = find(~used & (br(:,1) == b | br(:,2) == b));
        for k = idx'
            used(k) = true;  r = br(k,:);
            if r(1) ~= b, r([1 2]) = r([2 1]); end
            br2(end+1,:) = r; %#ok<AGROW>
            nxt(end+1) = r(2); %#ok<AGROW>
        end
    end
    frontier = nxt;
end
if any(~used)
    error('load_ieee33:notRadial', 'Some branches are not connected to the substation.');
end
end
