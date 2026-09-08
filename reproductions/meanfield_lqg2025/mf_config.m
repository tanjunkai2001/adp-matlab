function cfg = mf_config()
%MF_CONFIG Paper section 4 parameters and explicit computational choices.
% Xu, Wang, Shen, Automatica 172 (2025), 111924; arXiv:2410.15119v1.
cfg.plant.A = [0.3 0.7; -0.9 0.5];
cfg.plant.B = [0.2; 0];
cfg.plant.C = [0.05 0.03; 0.05 0.02];
cfg.plant.D = [0.05; 0.06];
cfg.cost.Q = diag([3 2]);
cfg.cost.R = 1.25;
cfg.cost.Gamma = 0.9*eye(2);
cfg.K0 = [6 -3];
cfg.initialMean = [2; 2];
cfg.initialRange = [0 4];
cfg.seed = 20260907;
cfg.train.dt = 0.001;
cfg.train.window = 0.9;
cfg.train.lastStart = 10;
cfg.train.startStride = 1; % every dt; state data extend to 10.9 seconds
cfg.train.paths = 100;
cfg.train.nFrequencies = 100;
cfg.train.frequencyRange = [-100 100];
cfg.train.repeats = 8; % independent initial states, Brownian paths and probes
cfg.learn.tolerance = 1e-4;
cfg.learn.maxIterations = 100;
cfg.learn.rankRelativeTolerance = 1e-10;
cfg.learn.maxScaledCondition = 1e10;
cfg.eval.dt = 0.002;
cfg.eval.horizon = 20; % explicitly finite, no infinite-horizon claim
cfg.eval.population = 40;
cfg.eval.repeats = 48; % independent populations; paired policy comparisons
cfg.eval.meanPaths = 100; % Algorithm 1, mean-field approximation I
cfg.eval.seed = cfg.seed + 10000;
cfg.meanSeed = cfg.seed + 20000;
cfg.paper = struct('doi','10.1016/j.automatica.2024.111924', ...
    'arxiv','2410.15119v1','pdfSha256', ...
    'a50e13845db320f9a8575b8cead71ac9be3f3a1004fa120ccbcc06a44947db6f');
end
