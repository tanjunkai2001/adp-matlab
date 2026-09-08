function report = verifyRun(runDir, sourceRoot)
%VERIFYRUN Verify sealed byte identities; throw if any required file changed.
% Also rejects newly added run artifacts/source .m files (excluding runs/).
% The manifest is an unsigned reference, not proof of author authenticity.
    if ~isfolder(runDir) || ~isfolder(sourceRoot)
        error('adp:io:MissingDirectory','Run and source directories must exist.');
    end
    manifestPath = fullfile(runDir,'manifest.json');
    if ~isfile(manifestPath)
        error('adp:io:MissingManifest','The run has no manifest.json.');
    end
    try
        record = jsondecode(fileread(manifestPath));
    catch exception
        failure = MException('adp:io:InvalidManifest','Manifest is not readable JSON.');
        throw(addCause(failure,exception));
    end
    if ~isstruct(record) || ~isscalar(record) || ...
            ~all(isfield(record,{'schema_version','artifacts','matlab_sources'})) || ...
            ~ischar(record.schema_version) || ~isrow(record.schema_version)
        error('adp:io:InvalidManifest','Manifest metadata is missing or malformed.');
    end
    if ~strcmp(record.schema_version,'1.0')
        error('adp:io:UnsupportedSchema','Unsupported manifest schema: %s.',record.schema_version);
    end
    required = {'config.json','result.mat','summary.json'};
    for k = 1:numel(required)
        if ~isfile(fullfile(runDir,required{k}))
            error('adp:io:MissingArtifact','Missing required run artifact: %s.',required{k});
        end
    end
    validateRecords(record.artifacts,false);
    validateRecords(record.matlab_sources,true);
    if ~all(ismember(required,{record.artifacts.path}))
        error('adp:io:InvalidManifest','Manifest omits a required run artifact.');
    end
    checkRecords(runDir,record.artifacts,false);
    checkRecords(sourceRoot,record.matlab_sources,true);
    report.status = 'artifact_identity_pass';
    report.artifact_count = numel(record.artifacts);
    report.source_count = numel(record.matlab_sources);
    report.manifest_schema = record.schema_version;
    report.manifest_authenticated = false;
    report.scope = 'Identity under an unsigned supplied manifest; no numerical recomputation or authenticity proof.';
end

function validateRecords(records,sourceOnly)
    if ~isstruct(records) || isempty(records) || ~isvector(records) || ...
            ~all(isfield(records,{'path','sha256','bytes'}))
        error('adp:io:InvalidManifest','Manifest file records are empty or malformed.');
    end
    for k = 1:numel(records)
        entry = records(k);
        if ~ischar(entry.path) || ~isrow(entry.path) || isempty(entry.path) || ...
                contains(entry.path,'\') || contains(entry.path,':') || ...
                any(entry.path==char(0))
            error('adp:io:InvalidManifest','Each path must be a nonempty portable relative path.');
        end
        parts = strsplit(entry.path,'/','CollapseDelimiters',false);
        if any(ismember(parts,{'','.','..'})) || strcmp(entry.path,'manifest.json')
            error('adp:io:InvalidManifest','Invalid or self-referential manifest path: %s.',entry.path);
        end
        if sourceOnly
            [~,~,extension] = fileparts(entry.path);
            if ~strcmpi(extension,'.m') || startsWith(entry.path,'runs/')
                error('adp:io:InvalidManifest','Source records must name MATLAB sources outside runs/.');
            end
        end
        if ~ischar(entry.sha256) || ~isrow(entry.sha256) || ...
                isempty(regexp(entry.sha256,'^[0-9a-fA-F]{64}$','once')) || ...
                ~isnumeric(entry.bytes) || ~isscalar(entry.bytes) || ...
                ~isreal(entry.bytes) || ~isfinite(entry.bytes) || ...
                entry.bytes<0 || fix(entry.bytes)~=entry.bytes
            error('adp:io:InvalidManifest','Invalid hash or byte count for %s.',entry.path);
        end
    end
    if numel(unique({records.path})) ~= numel(records)
        error('adp:io:InvalidManifest','Duplicate file paths in manifest.');
    end
end

function checkRecords(root, records, sourceOnly)
    canonicalRoot = char(java.io.File(root).getCanonicalPath());
    expected = string({records.path});
    for k = 1:numel(records)
        file = fullfile(root,strrep(records(k).path,'/',filesep));
        if ~isfile(file)
            error('adp:io:MissingArtifact','Missing sealed file: %s',file);
        end
        canonical = char(java.io.File(file).getCanonicalPath());
        if java.nio.file.Files.isSymbolicLink(java.io.File(file).toPath())
            error('adp:io:UnsupportedSymlink','Tracked file must not be a symbolic link: %s.',records(k).path);
        end
        if ~startsWith(canonical,[canonicalRoot,filesep])
            error('adp:io:InvalidManifest','Recorded path resolves outside its root: %s.',records(k).path);
        end
        if ~strcmp(adp.io.fileHash(file),lower(records(k).sha256))
            error('adp:io:HashMismatch','Changed sealed file: %s',file);
        end
        info = dir(file);
        if info.bytes ~= records(k).bytes
            error('adp:io:SizeMismatch','Declared byte count does not match %s.',file);
        end
    end
    root = char(java.io.File(root).getCanonicalPath());
    listing = dir(fullfile(root,'**','*'));
    actual = strings(0,1);
    for k = 1:numel(listing)
        file = fullfile(listing(k).folder,listing(k).name);
        relative = strrep(file(numel(root)+2:end),filesep,'/');
        if sourceOnly && (strcmp(relative,'runs') || startsWith(relative,'runs/'))
            continue;
        end
        [~,~,ext] = fileparts(file);
        if java.nio.file.Files.isSymbolicLink(java.io.File(file).toPath()) && ...
                (~sourceOnly || listing(k).isdir || strcmpi(ext,'.m'))
            error('adp:io:UnsupportedSymlink','Tracked files and source directories must not be symbolic links: %s.',relative);
        end
        if listing(k).isdir, continue; end
        if sourceOnly
            if ~strcmpi(ext,'.m'), continue; end
        elseif strcmp(relative,'manifest.json')
            continue;
        end
        actual(end+1,1) = string(relative); %#ok<AGROW>
    end
    if ~isequal(sort(actual(:)),sort(expected(:)))
        error('adp:io:FileSetChanged','Sealed file inventory has changed.');
    end
end
