function tests=testRepositoryEntries
tests=functiontests(localfunctions);
end

function testRegisteredEntriesExistAndHaveDistinctIds(tc)
catalog=adp_catalog();root=fileparts(fileparts(mfilename('fullpath')));
verifyEqual(tc,numel(unique(catalog.method)),height(catalog));
for k=1:height(catalog)
    verifyTrue(tc,isfile(fullfile(root,catalog.directory{k},[catalog.entryPoint{k},'.m'])));
end
selected=strcmp(catalog.method,'pinn_infinite_horizon2025');
verifyTrue(tc,catalog.runsNeuralTraining(selected));
verifyTrue(tc,ismember('Deep Learning Toolbox',catalog.requiredProducts{selected}));
end

function testDiscoveryAndEnvironmentDoNotChangeSession(tc)
beforePath=path;beforeRng=rng;beforeFolder=pwd;
evalc('catalog=demo_reproductions(); env=check_environment();');
verifyEqual(tc,catalog.method,env.methods.method);
verifyEqual(tc,path,beforePath);verifyEqual(tc,rng,beforeRng);verifyEqual(tc,pwd,beforeFolder);
end

function testInvalidModeAndExistingOutputFailBeforeTraining(tc)
beforePath=path;beforeRng=rng;beforeFolder=pwd;
verifyError(tc,@()demo_reproductions('pinn_infinite_horizon2025','typo'),'pinn:Mode');
folder=tempname;mkdir(folder);tc.addTeardown(@()rmdir(folder,'s'));
fid=fopen(fullfile(folder,'keep.txt'),'w');fprintf(fid,'preserved');fclose(fid);
verifyError(tc,@()demo_reproductions('pinn_infinite_horizon2025','smoke',folder),'pinn:ExistingRun');
verifyError(tc,@()demo_reproductions('meanfield_lqg2025',folder),'mf:PreserveRun');
verifyEqual(tc,fileread(fullfile(folder,'keep.txt')),'preserved');
verifyEqual(tc,path,beforePath);verifyEqual(tc,rng,beforeRng);verifyEqual(tc,pwd,beforeFolder);
end
