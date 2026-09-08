function raw = mf_collect(plant, K0, cfg, seed)
%MF_COLLECT Independent Euler-Maruyama paths under one common probing input.
% Only this simulator sees A/B/C/D. No analytic moments enter the dataset.
assert(isequal(size(K0),[1 2]),'mf:Dimensions','This example has n=2,m=1.');
dt = cfg.dt;
nSteps = round((cfg.lastStart + cfg.window)/dt);
assert(abs(nSteps*dt-cfg.lastStart-cfg.window)<1e-10, ...
    'mf:Grid','Training horizon must lie on the time grid.');
stream = RandStream('mt19937ar','Seed',seed);
t = (0:nSteps)*dt;
frequencies = cfg.frequencyRange(1) + diff(cfg.frequencyRange)* ...
    rand(stream,cfg.nFrequencies,1);
if isfield(cfg,'frequencies')
    frequencies=cfg.frequencies; % same probing input across pooled MC batches
end
probe = sum(sin(frequencies*t),1);
x = zeros(2,cfg.paths,nSteps+1);
u = zeros(cfg.paths,nSteps+1);
dw = sqrt(dt)*randn(stream,cfg.paths,nSteps);
x(:,:,1) = 4*rand(stream,2,cfg.paths);
for k=1:nSteps
    state = x(:,:,k);
    input = -K0*state + probe(k);
    u(:,k) = input.';
    x(:,:,k+1) = state + (plant.A*state+plant.B*input)*dt + ...
        (plant.C*state+plant.D*input).*dw(:,k).';
end
u(:,end) = (-K0*x(:,:,end)+probe(end)).';
assert(all(isfinite(x(:))) && all(isfinite(u(:))), ...
    'mf:NonfiniteData','The simulated trajectory is nonfinite.');
raw = struct('t',t,'x',x,'u',u,'dw',dw,'dt',dt,'seed',seed, ...
    'frequencies',frequencies,'probe',probe,'behaviorGain',K0, ...
    'solver','Euler-Maruyama','initialDistribution','iid uniform [0,4]^2');
end
