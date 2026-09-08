function tests = testPersistenceContracts
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.baseline = demo_integral_pi(struct('saveOutputs',false));
end

function testMissingManifestHasExplicitFailure(testCase)
[runDir,sourceRoot] = fixture(testCase);
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:MissingManifest');
end

function testMalformedManifestAndUnsupportedSchema(testCase)
[runDir,sourceRoot] = fixture(testCase);
adp.io.sealRun(runDir,sourceRoot);
manifestPath = fullfile(runDir,'manifest.json'); original = fileread(manifestPath);
writeText(manifestPath,'{ not valid JSON');
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:InvalidManifest');
record = jsondecode(original); record.schema_version = '999.0';
writeText(manifestPath,jsonencode(record));
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:UnsupportedSchema');
record = rmfield(record,'schema_version'); writeText(manifestPath,jsonencode(record));
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:InvalidManifest');
end

function testManifestRecordsRequireUniqueSafePathsAndCorrectSizes(testCase)
[runDir,sourceRoot] = fixture(testCase);
original = adp.io.sealRun(runDir,sourceRoot);
manifestPath = fullfile(runDir,'manifest.json');
duplicate = original; duplicate.artifacts(end+1) = duplicate.artifacts(1);
writeText(manifestPath,jsonencode(duplicate));
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:InvalidManifest');
for unsafe = {'../outside.txt','/tmp/outside.txt','sub/../config.json','C:\\outside.txt'}
    record = original; record.artifacts(1).path = unsafe{1};
    writeText(manifestPath,jsonencode(record));
    verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:InvalidManifest');
end
record = original; record.artifacts(1).bytes = record.artifacts(1).bytes+1;
writeText(manifestPath,jsonencode(record));
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:SizeMismatch');
end

function testRequiredArtifactsCannotBeRemovedFromManifest(testCase)
[runDir,sourceRoot] = fixture(testCase);
record = adp.io.sealRun(runDir,sourceRoot);
delete(fullfile(runDir,'summary.json'));
record.artifacts(strcmp({record.artifacts.path},'summary.json')) = [];
writeText(fullfile(runDir,'manifest.json'),jsonencode(record));
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:MissingArtifact');
end

function testDeletedSourceAddedSourceAndVersionBytesDetected(testCase)
[runDir,sourceRoot] = fixture(testCase);
writeText(fullfile(runDir,'source_version.json'),'{"referenceVersion":"0.2.0"}');
adp.io.sealRun(runDir,sourceRoot);
writeText(fullfile(runDir,'source_version.json'),'{"referenceVersion":"0.2.1"}');
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:HashMismatch');
writeText(fullfile(runDir,'source_version.json'),'{"referenceVersion":"0.2.0"}');
writeText(fullfile(sourceRoot,'new.m'),'function y=new(x), y=x; end');
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:FileSetChanged');
delete(fullfile(sourceRoot,'new.m')); delete(fullfile(sourceRoot,'identity.m'));
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:MissingArtifact');
end

function testSealRejectsMissingInputsAndSource(testCase)
[runDir,sourceRoot] = fixture(testCase);
delete(fullfile(runDir,'config.json'));
verifyError(testCase,@() adp.io.sealRun(runDir,sourceRoot),'adp:io:MissingArtifact');
writeText(fullfile(runDir,'config.json'),'{}');
delete(fullfile(sourceRoot,'identity.m'));
verifyError(testCase,@() adp.io.sealRun(runDir,sourceRoot),'adp:io:MissingSource');
verifyFalse(testCase,isfile(fullfile(runDir,'manifest.json')));
end

function testSourceSymlinkCannotHideInExcludedRuns(testCase)
[runDir,sourceRoot] = fixture(testCase);
adp.io.sealRun(runDir,sourceRoot);
mkdir(fullfile(sourceRoot,'runs'));
target = fullfile(sourceRoot,'runs','helper.m');
writeText(target,'function y=helper(x), y=x+1; end');
makeSymbolicLink(fullfile(sourceRoot,'alias.m'),target);
verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:UnsupportedSymlink');
[newRun,newSource] = fixture(testCase);
makeSymbolicLink(fullfile(newSource,'alias.m'),fullfile(newSource,'identity.m'));
verifyError(testCase,@() adp.io.sealRun(newRun,newSource),'adp:io:UnsupportedSymlink');
end

function testFailedSaveLeavesNoPartialRunOrStaging(testCase)
root = temporaryDirectory(testCase);
writeText(fullfile(root,'keep.txt'),'existing data');
result = testCase.TestData.baseline;
result.config.nonserializable = @sin;
failure = '';
try, adp.io.saveRun(result,root,'broken'); catch exception, failure = exception.identifier; end
verifyNotEmpty(testCase,failure);
verifyFalse(testCase,isfolder(fullfile(root,'broken')));
listing = dir(root); names = setdiff({listing.name},{'.','..'});
verifyEqual(testCase,names,{'keep.txt'});
verifyEqual(testCase,fileread(fullfile(root,'keep.txt')),'existing data');
end

function testRunIdAndExistingFileAreNeverOverwritten(testCase)
root = temporaryDirectory(testCase); result = testCase.TestData.baseline;
for invalid = {'../escape','has/slash','.','C:\\escape'}
    verifyError(testCase,@() adp.io.saveRun(result,root,invalid{1}),'adp:io:InvalidRunId');
end
writeText(fullfile(root,'existing-run'),'keep');
verifyError(testCase,@() adp.io.saveRun(result,root,'existing-run'),'adp:io:RunExists');
verifyEqual(testCase,fileread(fullfile(root,'existing-run')),'keep');
end

function testBinaryHashAcrossChunkBoundaryAndMissingFile(testCase)
root = temporaryDirectory(testCase);
file = fullfile(root,'binary.dat');
fid = fopen(file,'wb');
fwrite(fid,uint8(mod(0:1048592,256)),'uint8'); fclose(fid);
% Independent Python hashlib SHA-256 reference for bytes 0..255 repeated.
verifyEqual(testCase,adp.io.fileHash(file), ...
    '198fe22858bf90dd34cba065bf3e3d4680918f930e94ce51807b9b3055f2eb1e');
verifyError(testCase,@() adp.io.fileHash(fullfile(root,'missing.dat')),'adp:io:ReadFailed');
end

function testCrossCwdPreservesPathRandomStateAndVersion(testCase)
root = temporaryDirectory(testCase);
oldCwd = pwd; oldPath = path; oldRng = rng;
cleanup = onCleanup(@() restoreSession(oldCwd,oldPath,oldRng)); %#ok<NASGU>
cd(root); rng(9182,'twister'); beforeRng = rng; beforePath = path;
[result,runDir] = demo_integral_pi(struct('saveOutputs',true, ...
    'outputRoot',fullfile(root,'new-location'),'runId','cross-cwd'));
verifyEqual(testCase,pwd,root);
verifyEqual(testCase,path,beforePath);
verifyEqual(testCase,rng,beforeRng);
verifyTrue(testCase,isfile(fullfile(runDir,'manifest.json')));
verifyEqual(testCase,result.sourceVersion.referenceVersion,'0.2.0');
source = jsondecode(fileread(fullfile(runDir,'source_version.json')));
verifyEqual(testCase,source.referenceVersion,'0.2.0');
manifest = jsondecode(fileread(fullfile(runDir,'manifest.json')));
verifyEqual(testCase,manifest.schema_version,'1.0');
end

function [runDir,sourceRoot] = fixture(testCase)
root = temporaryDirectory(testCase);
runDir = fullfile(root,'run'); mkdir(runDir);
sourceRoot = fullfile(root,'source'); mkdir(sourceRoot);
writeText(fullfile(runDir,'config.json'),'{}');
writeText(fullfile(runDir,'summary.json'),'{}');
result = 1; save(fullfile(runDir,'result.mat'),'result');
writeText(fullfile(sourceRoot,'identity.m'),'function y=identity(x), y=x; end');
end

function root = temporaryDirectory(testCase)
root = tempname; mkdir(root);
testCase.addTeardown(@() rmdir(root,'s'));
end

function writeText(file,text)
fid = fopen(file,'w'); cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',text);
end

function restoreSession(oldCwd,oldPath,oldRng)
cd(oldCwd); path(oldPath); rng(oldRng);
end

function makeSymbolicLink(link,target)
java.nio.file.Files.createSymbolicLink(java.io.File(link).toPath(), ...
    java.io.File(target).toPath(),javaArray('java.nio.file.attribute.FileAttribute',0));
end
