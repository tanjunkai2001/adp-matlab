function tests = test_meanfield_lqg2025
tests=functiontests(localfunctions);
end

function testSecondMomentsAreNotOuterMean(t)
raw=struct('x',zeros(2,2,3),'u',zeros(2,3),'dt',1,'t',0:2);
raw.x(:,:,1)=[1 -1;2 -2];
raw.x(:,:,2)=[2 -2;1 -1];
raw.x(:,:,3)=[3 -3;1 -1];
c=struct('window',1,'lastStart',1,'startStride',1);
d=mf_build_data(raw,c);
verifyEqual(t,d.moments.meanOuter,zeros(3,3),'AbsTol',0);
verifyEqual(t,d.moments.second(1,:),[1 2 4],'AbsTol',0);
verifyEqual(t,d.intSecond(1,:),[1 2 4],'AbsTol',0);
verifyEqual(t,d.deltaSecond(1,:),[3 0 -3],'AbsTol',0);
end

function testExcitationRankFailure(t)
c=mf_config;
d=emptyData;
verifyError(t,@()mf_learn(d,c.cost,c.K0,c.learn),'mf:RankDeficient');
end

function testConditionFailure(t)
c=mf_config; d=emptyData;
% A full-rank observation layout, rejected by a deliberate condition limit.
r=RandStream('mt19937ar','Seed',14);
d.intSecond=randn(r,12,3); d.intXu=randn(r,12,2); d.intUu=randn(r,12,1);
d.intMeanOuter=randn(r,12,3); d.intMeanXu=randn(r,12,2);
c.learn.maxScaledCondition=1.01;
verifyError(t,@()mf_learn(d,c.cost,c.K0,c.learn),'mf:IllConditioned');
end

function testPrimaryFitFailurePreservesReplayData(t)
c=mf_config;
c.train.paths=5; c.train.window=0.002; c.train.lastStart=0.003;
c.train.repeats=1; % Four windows cannot identify six excitation columns.
folder=tempname;
t.addTeardown(@()rmdir(folder,'s'));
verifyError(t,@()demo_meanfield_lqg2025(folder,c),'mf:RankDeficient');
inputFile=fullfile(folder,'training-data.mat');
assertTrue(t,isfile(inputFile),'A rejected primary fit must retain its inputs.');
saved=load(inputFile);
verifyEqual(t,saved.cfg,c);
verifyEqual(t,saved.raw,mf_collect(c.plant,c.K0,c.train,c.seed));
verifyEqual(t,saved.data,mf_build_data(saved.raw,saved.cfg.train));
verifyFalse(t,isfield(saved,'learned'));
verifyError(t,@()mf_learn(saved.data,saved.cfg.cost,saved.cfg.K0, ...
    saved.cfg.learn),'mf:RankDeficient');
failure=jsondecode(fileread(fullfile(folder,'failure.json')));
verifyEqual(t,failure.stage,'primary_fit');
verifyEqual(t,failure.identifier,'mf:RankDeficient');
verifyEqual(t,failure.inputFile,'training-data.mat');
verifyFalse(t,isfile(fullfile(folder,'results.mat')));
end

function testReferenceSolvesBothRiccatiEquations(t)
c=mf_config; r=mf_reference(c.plant,c.cost,c.K0);
verifyLessThan(t,r.stochasticAREresidual,1e-9);
verifyLessThan(t,r.meanAREresidual,1e-10);
verifyLessThan(t,r.meanSquareAbscissa,0);
verifyLessThan(t,r.meanAbscissa,0);
verifyGreaterThan(t,min(eig(r.P)),0);
% Published Table 2 numbers are recorded separately, not used as an oracle.
end

function testControlDependentDiffusionAndObservedInputs(t)
c=mf_config; c.train.paths=5; c.train.lastStart=0.01; c.train.window=0.002;
raw=mf_collect(c.plant,c.K0,c.train,41);
x=raw.x(:,:,1); u=raw.u(:,1).';
expected=x+(c.plant.A*x+c.plant.B*u)*raw.dt+ ...
    (c.plant.C*x+c.plant.D*u).*raw.dw(:,1).';
verifyEqual(t,raw.x(:,:,2),expected,'AbsTol',1e-14);
withoutD=x+(c.plant.A*x+c.plant.B*u)*raw.dt+ ...
    (c.plant.C*x).*raw.dw(:,1).';
verifyGreaterThan(t,norm(expected-withoutD,'fro'),1e-5);
verifyEqual(t,u,-c.K0*x+raw.probe(1),'AbsTol',1e-14);
end

function testPublishedTable2IsConditionalOnTable1(t)
c=mf_config;
paper=struct('K',[8.467 -4.9231],'Upsilon',1.25+0.2010);
r=mf_reference(c.plant,c.cost,c.K0,paper);
verifyEqual(t,r.conditionalSecond.S,[-3.4935 3.5718;3.5718 -9.7025],'AbsTol',5e-5);
verifyEqual(t,r.conditionalSecond.Ks,[-0.4815 0.4923],'AbsTol',5e-5);
verifyGreaterThan(t,norm(r.S-r.conditionalSecond.S,'fro'),0.1);
end

function testFiniteDataLearnerAndNoPlantInput(t)
c=mf_config;
raw=mf_collect(c.plant,c.K0,c.train,c.seed);
d=mf_build_data(raw,c.train);
r=mf_learn(d,c.cost,c.K0,c.learn);
oracle=mf_reference(c.plant,c.cost,c.K0);
verifyEqual(t,r.dataRank1.rank,6); verifyEqual(t,r.dataRank2.rank,5);
verifyLessThan(t,norm(r.K-oracle.K)/norm(oracle.K),0.30);
verifyLessThan(t,norm(r.Ks-oracle.Ks)/norm(oracle.Ks),0.50);
verifyLessThan(t,r.history1(end).delta,c.learn.tolerance);
verifyLessThan(t,r.history2(end).delta,c.learn.tolerance);
verifyFalse(t,isfield(d,'plant'));
end

function d=emptyData
d=struct('deltaSecond',zeros(12,3),'intSecond',zeros(12,3), ...
    'intXu',zeros(12,2),'intUu',zeros(12,1), ...
    'deltaMeanOuter',zeros(12,3),'intMeanOuter',zeros(12,3), ...
    'intMeanXu',zeros(12,2));
end
