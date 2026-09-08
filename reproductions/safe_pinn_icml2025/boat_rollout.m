function out=boat_rollout(net,initial,budget,dt)
%BOAT_ROLLOUT Batch independent rollouts, Hamiltonian-minimizing unit-disk u.
% RK4 plant integration with held input each dt; fine-grid check is separate.
count=size(initial,2);steps=round(2/dt);dt=2/steps;
x=initial;z=budget;cost=zeros(1,count);[maxG,~]=boat_geometry(x);
states=zeros(steps+1,2,count);states(1,:,:)=reshape(x,[1 2 count]);
inputs=zeros(steps,2,count);budgets=zeros(steps+1,count);budgets(1,:)=z;
leftDomain=false(1,count); numericalValid=true(1,count); predictor=dlaccelerate(@valueGradient);
for k=1:steps
    S=dlarray([2-(k-1)*dt+zeros(1,count);x;z],'CB');
    [~,p]=dlfeval(predictor,net,S);p=extractdata(p);
    norms=sqrt(sum(p(2:3,:).^2,1));u=-p(2:3,:)./max(norms,1e-10);
    [~,l1]=boat_geometry(x);f1=flow(x,u);xm=x+dt*f1/2;
    [gm,l2]=boat_geometry(xm);f2=flow(xm,u);x3=x+dt*f2/2;f3=flow(x3,u);x4=x+dt*f3;f4=flow(x4,u);
    [g3,l3]=boat_geometry(x3);[g4,l4]=boat_geometry(x4);
    next=x+dt*(f1+2*f2+2*f3+f4)/6;[gn,ln]=boat_geometry(next);
    integral=dt*(l1+2*l2+2*l3+l4)/6;cost=cost+integral;z=z-integral;
    numericalValid=numericalValid & all(isfinite([next;u;z;cost;gm;g3;g4;gn;ln]),1);
    maxG=max(maxG,max(max(gm,g3),max(g4,gn)));x=next;
    leftDomain=leftDomain | x(1,:)<-3 | x(1,:)>2 | abs(x(2,:))>2 | z<-.1 | z>14.86;
    states(k+1,:,:)=reshape(x,[1 2 count]);inputs(k,:,:)=reshape(u,[1 2 count]);budgets(k+1,:)=z;
end
[~,terminal]=boat_geometry(x);cost=cost+terminal;
out=struct('initial',initial,'initialBudget',budget,'cost',cost,'maxObstacleG',maxG, ...
    'epigraphRollout',max(cost-budget,maxG),'x',states,'u_applied',inputs, ...
    'budget',budgets,'dt',dt,'leftTrainingDomain',leftDomain,'numericalValid',numericalValid);
end
function f=flow(x,u)
f=[u(1,:)+2-.5*x(2,:).^2;u(2,:)];
end
function [V,p]=valueGradient(net,S)
V=boat_value(net,S);p=dlgradient(sum(V,'all'),S);
end
