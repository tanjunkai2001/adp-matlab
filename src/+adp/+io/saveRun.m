function runDir = saveRun(runResult, outputRoot, runId)
%SAVERUN Save a new run atomically, refusing to overwrite an existing run.
% The caller may subsequently seal this directory with adp.io.sealRun.
if nargin < 3 || isempty(runId)
    runId = ['run-',char(datetime('now','TimeZone','UTC', ...
        'Format',"yyyyMMdd'T'HHmmssSSS'Z'"))];
end
outputRoot = char(outputRoot);
runId = char(runId);
if isempty(regexp(runId,'^[A-Za-z0-9][A-Za-z0-9_-]*$','once'))
    error('adp:io:InvalidRunId','runId must contain only letters, digits, underscores and hyphens.');
end
if ~isfolder(outputRoot)
    [ok,message] = mkdir(outputRoot);
    if ~ok, error('adp:io:CannotCreateOutput','%s',message); end
end
runDir = fullfile(outputRoot,runId);
if isfolder(runDir) || isfile(runDir)
    error('adp:io:RunExists','Refusing to overwrite an existing run: %s',runDir);
end
stagingDir = tempname(outputRoot);
[ok,message] = mkdir(stagingDir);
if ~ok, error('adp:io:CannotCreateOutput','%s',message); end
stagingCleanup = onCleanup(@() cleanupStaging(stagingDir)); %#ok<NASGU>
result = runResult;
save(fullfile(stagingDir,'result.mat'),'result','-v7');
writeJson(fullfile(stagingDir,'config.json'),runResult.config);
writeJson(fullfile(stagingDir,'environment.json'),runResult.environment);
writeJson(fullfile(stagingDir,'source_version.json'),runResult.sourceVersion);
summary = rmfield(runResult.metrics,'finalClosedLoopPoles');
summary.polesReal = real(runResult.metrics.finalClosedLoopPoles);
summary.polesImag = imag(runResult.metrics.finalClosedLoopPoles);
summary.status = runResult.learning.status;
summary.iterations = runResult.learning.iterations;
writeJson(fullfile(stagingDir,'summary.json'),summary);
diagnostics = struct('status',runResult.learning.status, ...
    'iterations',runResult.learning.iterations,'fits',{{}});
diagnostics.fits = cellfun(@(entry) entry.fit, ...
    runResult.learning.history,'UniformOutput',false);
writeJson(fullfile(stagingDir,'diagnostics.json'),diagnostics);
if isfolder(runDir) || isfile(runDir)
    error('adp:io:RunExists','Destination appeared while saving; refusing overwrite: %s',runDir);
end
[ok,message] = movefile(stagingDir,runDir);
if ~ok, error('adp:io:CannotCommitRun','%s',message); end
end

function cleanupStaging(stagingDir)
% Only this call's temporary staging folder is eligible for cleanup.
if isfolder(stagingDir), rmdir(stagingDir,'s'); end
end

function writeJson(filePath,value)
encoded = jsonencode(value,'PrettyPrint',true);
[fid,message] = fopen(filePath,'w','n','UTF-8');
if fid < 0, error('adp:io:CannotWriteJson','%s',message); end
fileCleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
written = fprintf(fid,'%s\n',encoded);
if written < 0, error('adp:io:CannotWriteJson','Failed writing %s.',filePath); end
end
