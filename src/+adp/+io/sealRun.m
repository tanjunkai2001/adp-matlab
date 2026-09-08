function manifest = sealRun(runDir, sourceRoot)
%SEALRUN Save SHA-256 identities of run artifacts and MATLAB source files.
% Requires the standard MATLAB JVM. Run files are immutable after sealing.
% Source hashes cover .m files only; data/config files in RUNDir are all hashed.
    runDir = char(runDir);
    sourceRoot = char(sourceRoot);
    if ~isfolder(runDir) || ~isfolder(sourceRoot)
        error('adp:io:MissingDirectory','Run and source directories must exist.');
    end
    target = fullfile(runDir,'manifest.json');
    if isfile(target)
        error('adp:io:AlreadySealed','Refusing to replace an existing manifest.');
    end
    required = {'config.json','result.mat','summary.json'};
    for k = 1:numel(required)
        if ~isfile(fullfile(runDir,required{k}))
            error('adp:io:MissingArtifact','Missing artifact: %s',required{k});
        end
    end
    manifest.schema_version = '1.0';
    manifest.created_utc = char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
    manifest.matlab_release = version('-release');
    manifest.platform = computer;
    manifest.scope = 'Byte identity of run artifacts and MATLAB source; not numerical or scientific validity.';
    manifest.artifacts = fileRecords(runDir,false);
    manifest.matlab_sources = fileRecords(sourceRoot,true);
    if isempty(manifest.matlab_sources)
        error('adp:io:MissingSource','No MATLAB source files found.');
    end
    fid = fopen(target,'w');
    if fid < 0, error('adp:io:WriteFailed','Cannot write manifest.'); end
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s\n',jsonencode(manifest,PrettyPrint=true));
end

function records = fileRecords(root, sourceOnly)
    root = char(java.io.File(root).getCanonicalPath());
    files = dir(fullfile(root,'**','*'));
    records = struct('path',{},'sha256',{},'bytes',{});
    for k = 1:numel(files)
        full = fullfile(files(k).folder,files(k).name);
        % Select by the visible path, never a symbolic link's target path.
        relative = full(numel(root)+2:end);
        relative = strrep(relative,filesep,'/');
        if sourceOnly && (strcmp(relative,'runs') || startsWith(relative,'runs/'))
            continue;
        end
        [~,~,ext] = fileparts(full);
        if java.nio.file.Files.isSymbolicLink(java.io.File(full).toPath()) && ...
                (~sourceOnly || files(k).isdir || strcmpi(ext,'.m'))
            error('adp:io:UnsupportedSymlink','Tracked files and source directories must not be symbolic links: %s.',relative);
        end
        if files(k).isdir, continue; end
        if sourceOnly
            if ~strcmpi(ext,'.m'), continue; end
        elseif strcmp(relative,'manifest.json')
            continue;
        end
        entry.path = relative;
        entry.sha256 = adp.io.fileHash(full);
        entry.bytes = files(k).bytes;
        records(end+1) = entry; %#ok<AGROW>
    end
    if ~isempty(records)
        [~,order] = sort({records.path}); records = records(order);
    end
end
