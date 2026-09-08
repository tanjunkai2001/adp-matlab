function plant = doubleIntegrator()
%DOUBLEINTEGRATOR Original two-state continuous-time LQR benchmark.
% Plant truth belongs to the simulator. integralPI receives only B and R.
plant.name = 'continuous_time_double_integrator';
plant.timeDomain = 'continuous';
plant.A = [0,1;0,0];
plant.B = [0;1];
plant.Q = eye(2);
plant.R = 1;
plant.stateDimension = 2;
plant.inputDimension = 1;
plant.stageCostConvention = 'x''*Q*x + u''*R*u; no half factor';
plant.dynamics = @(~,x,u) [x(2);u(1)];
plant.stageCost = @(~,x,u) x'*x + u'*u;
end
