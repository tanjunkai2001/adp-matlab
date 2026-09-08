function results = run_tests()
%RUN_TESTS Run deterministic numerical and persistence contracts.
root = fileparts(mfilename('fullpath'));
oldPath = path;
pathCleanup = onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(root,fullfile(root,'src'));
results = runtests(fullfile(root,'tests'));
disp(table(results));
assert(all([results.Passed]),'adp:test:Failure', ...
    'At least one test failed or was incomplete. Inspect the test results.');
end
