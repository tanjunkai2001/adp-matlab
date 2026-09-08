function result = mf_evaluate(plant,cost,learned,ref,meanfield,cfg,K0)
%MF_EVALUATE Fixed-N social cost on independent populations, paired noise.
% Standard errors are across independent populations, NOT time samples or
% interacting individuals. They condition on the fitted gains/mean curve.
N=cfg.population; nRep=cfg.repeats; dt=cfg.dt;
steps=round(cfg.horizon/dt); total=N*nRep;
assert(size(meanfield.mean,2)==steps+1 && ...
    max(abs(meanfield.t-(0:steps)*dt))<1e-10,'mf:MeanGrid', ...
    'The learned mean-field trajectory must cover the evaluation grid.');
stream=RandStream('mt19937ar','Seed',cfg.seed);
x0=4*rand(stream,2,total);
x=repmat(x0,1,1,3);
gain=[learned.K;ref.K;K0];
feed=[learned.Ks;ref.Ks;zeros(1,2)];
referenceMean=zeros(2,steps+1); referenceMean(:,1)=[2;2];
transition=expm((plant.A-plant.B*(ref.K+ref.Ks))*dt);
for k=1:steps
    referenceMean(:,k+1)=transition*referenceMean(:,k);
end
populationCosts=zeros(nRep,3);
traceIndex=1:10:steps+1;
trace=zeros(2,N,numel(traceIndex),3);
trace(:,:,1,:)=reshape(x(:,1:N,:),2,N,1,3);
traceCounter=2;
for k=1:steps
    dW=sqrt(dt)*randn(stream,1,total); % shared among policies; independent agents
    for p=1:3
        state=x(:,:,p);
        if p==1, meanNow=meanfield.mean(:,k);
        elseif p==2, meanNow=referenceMean(:,k);
        else, meanNow=zeros(2,1);
        end
        input=-gain(p,:)*state-feed(p,:)*meanNow;
        empiricalMean=reshape(mean(reshape(state,2,N,nRep),2),2,nRep);
        errorState=state-repelem(cost.Gamma*empiricalMean,1,N);
        stage=sum(errorState.*(cost.Q*errorState),1)+cost.R*input.^2;
        populationCosts(:,p)=populationCosts(:,p)+ ...
            dt*mean(reshape(stage,N,nRep),1).';
        x(:,:,p)=state+(plant.A*state+plant.B*input)*dt+ ...
            (plant.C*state+plant.D*input).*dW;
    end
    if mod(k,10)==0
        trace(:,:,traceCounter,:)=reshape(x(:,1:N,:),2,N,1,3);
        traceCounter=traceCounter+1;
    end
end
assert(all(isfinite(populationCosts(:))), ...
    'mf:NonfiniteCost','Finite-population costs are nonfinite.');
paired=populationCosts(:,1)-populationCosts(:,2);
result=struct('policyNames',{{'learned with MC mean','model-based with exact mean','initial K0'}}, ...
    'populationCosts',populationCosts,'meanCost',mean(populationCosts,1), ...
    'standardError',std(populationCosts,0,1)/sqrt(nRep), ...
    'pairedLearnedMinusReference',mean(paired), ...
    'pairedStandardError',std(paired)/sqrt(nRep), ...
    'initialStates',x0,'seed',cfg.seed,'population',N,'repeats',nRep, ...
    'horizon',cfg.horizon,'dt',dt,'terminalStates',x, ...
    'traceTime',(traceIndex-1)*dt,'firstPopulationTrace',trace, ...
    'referenceMean',referenceMean, ...
    'scope','Finite horizon, finite N, conditional on fitted gains and frozen MC mean; reference is not the finite-N centralized optimum.');
end
