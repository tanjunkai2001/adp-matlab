function results = run_all_tests(mode)
%RUN_ALL_TESTS Existing local tests, with no PINN training entry invoked.
%   catalog=run_all_tests('list') discovers/counts tests without running them.
%   results=run_all_tests() executes the discovered suites and rejects any
%   failed/incomplete result. A method with no test file is explicitly listed.
%   Koopman/mean-field/TAC tests include their small numerical scenarios.
if nargin<1, mode='run'; end
if isstring(mode) && isscalar(mode), mode=char(mode); end
if ~ischar(mode) || ~ismember(mode,{'run','list'})
    error('adp:test:Mode','Mode must be run or list.');
end
root=fileparts(mfilename('fullpath'));
oldPath=path; oldRng=rng; oldFolder=pwd;
restore=onCleanup(@()restoreSession(oldPath,oldRng,oldFolder)); %#ok<NASGU>
methods=adp_catalog(); groups=methods.method;
files=cell(numel(groups),1); counts=zeros(numel(groups),1);
suite=[];
addpath(root,fullfile(root,'src'));
for j=1:numel(groups)
    if j==1, folder=fullfile(root,'tests');
    else, folder=fullfile(root,methods.directory{j});
    end
    if ~isfolder(folder)
        error('adp:test:MissingFolder','Expected method folder is absent: %s.',folder);
    end
    addpath(folder);
    listing=dir(fullfile(folder,'test*.m'));
    [~,order]=sort({listing.name}); listing=listing(order);
    files{j}=strjoin({listing.name},', ');
    for k=1:numel(listing)
        selected=matlab.unittest.TestSuite.fromFile(fullfile(folder,listing(k).name));
        counts(j)=counts(j)+numel(selected);
        if isempty(suite), suite=selected;
        else, suite=[suite,selected]; %#ok<AGROW>
        end
    end
end
catalog=table(groups,files,counts, ...
    'VariableNames',{'method','testFiles','discoveredTests'});
disp(catalog);
if strcmp(mode,'list')
    results=catalog;
    return
end
fprintf('Running %d discovered tests. No PINN training entry is called.\n',numel(suite));
results=run(suite);
disp(table(results));
assert(all([results.Passed]),'adp:test:Failure', ...
    'At least one discovered test failed or was incomplete. Inspect the displayed results.');
end

function restoreSession(oldPath,oldRng,oldFolder)
path(oldPath); rng(oldRng);
if ~strcmp(pwd,oldFolder), cd(oldFolder); end
end
