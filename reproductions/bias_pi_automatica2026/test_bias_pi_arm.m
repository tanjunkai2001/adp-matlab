function tests=test_bias_pi_arm
tests=functiontests(localfunctions);
end

function testMechanicalPowerAndAbsoluteAngles(tc)
% Independent mechanical energy balance detects Coriolis signs and the
% relative-error/absolute-angle offset at the nonzero arm target.
[plant,~,~]=bp_arm_config();
states=[.2,-.4,.6;-.3,.1,-.1;.7,-.5,.2;-.6,.8,-.9];
inputs=[.3,-.2,.1;-.1,.4,.2];
for k=1:size(states,2)
    x=states(:,k); u=inputs(:,k); dx=plant.dynamics(0,x,u);
    h=1e-6; derivative=(energy(x+h*dx)-energy(x-h*dx))/(2*h);
    verifyEqual(tc,derivative,x(3:4)'*u,'AbsTol',1e-8);
end
x=zeros(4,1); u=[.265;.052]; dx=plant.dynamics(0,x,u);
verifyEqual(tc,dx,[0;0;1;1],'AbsTol',1e-13);
end

function e=energy(x)
theta=x(1:2)+[pi/4;3*pi/4];
M=[.265,.0844*cos(theta(2)-theta(1));.0844*cos(theta(2)-theta(1)),.052];
e=x(3:4)'*M*x(3:4)/2;
end
