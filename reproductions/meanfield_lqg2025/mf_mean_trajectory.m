function meanfield = mf_mean_trajectory(plant,gain,initialMean,cfg,seed)
%MF_MEAN_TRAJECTORY Algorithm 1 approximation I, equations (43)-(44).
% Reset every path to the known initial mean and average observed states.
dt=cfg.dt; steps=round(cfg.horizon/dt);
stream=RandStream('mt19937ar','Seed',seed);
x=zeros(2,cfg.meanPaths,steps+1);
x(:,:,1)=repmat(initialMean,1,cfg.meanPaths);
dw=sqrt(dt)*randn(stream,cfg.meanPaths,steps);
for k=1:steps
    state=x(:,:,k); input=-gain*state;
    x(:,:,k+1)=state+(plant.A*state+plant.B*input)*dt+ ...
        (plant.C*state+plant.D*input).*dw(:,k).';
end
meanfield=struct('t',(0:steps)*dt,'mean',reshape(mean(x,2),2,[]), ...
    'standardError',reshape(std(x,0,2)/sqrt(cfg.meanPaths),2,[]), ...
    'paths',x,'dw',dw,'seed',seed,'gain',gain, ...
    'method','Equation (44), observed independent paths; no analytic mean supplied.');
end
