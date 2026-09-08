function tests = testRunManifest
    tests = functiontests(localfunctions);
end

function testKnownSHA256(testCase)
    [runDir,~] = fixture(testCase);
    path = fullfile(runDir,'abc.txt');
    writeText(path,'abc');
    verifyEqual(testCase,adp.io.fileHash(path), ...
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
end

function testRoundTripAndNoOverwrite(testCase)
    [runDir,sourceRoot] = fixture(testCase);
    adp.io.sealRun(runDir,sourceRoot);
    report = adp.io.verifyRun(runDir,sourceRoot);
    verifyEqual(testCase,report.status,'artifact_identity_pass');
    verifyEqual(testCase,report.artifact_count,3);
    verifyError(testCase,@() adp.io.sealRun(runDir,sourceRoot),'adp:io:AlreadySealed');
end

function testDetectArtifactAndSourceMutation(testCase)
    [runDir,sourceRoot] = fixture(testCase);
    adp.io.sealRun(runDir,sourceRoot);
    writeText(fullfile(runDir,'config.json'),'{"changed":true}');
    verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:HashMismatch');
    writeText(fullfile(runDir,'config.json'),'{}');
    writeText(fullfile(sourceRoot,'identity.m'),'function y=identity(x), y=x+1; end');
    verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:HashMismatch');
end

function testDetectAddedFile(testCase)
    [runDir,sourceRoot] = fixture(testCase);
    adp.io.sealRun(runDir,sourceRoot);
    writeText(fullfile(runDir,'extra.txt'),'new artifact');
    verifyError(testCase,@() adp.io.verifyRun(runDir,sourceRoot),'adp:io:FileSetChanged');
end

function [runDir,sourceRoot] = fixture(testCase)
    root = tempname;
    mkdir(root);
    testCase.addTeardown(@() rmdir(root,'s'));
    runDir = fullfile(root,'run'); mkdir(runDir);
    sourceRoot = fullfile(root,'source'); mkdir(sourceRoot);
    writeText(fullfile(runDir,'config.json'),'{}');
    writeText(fullfile(runDir,'summary.json'),'{}');
    result = 1; save(fullfile(runDir,'result.mat'),'result');
    writeText(fullfile(sourceRoot,'identity.m'),'function y=identity(x), y=x; end');
end

function writeText(path,text)
    fid = fopen(path,'w');
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s',text);
end
