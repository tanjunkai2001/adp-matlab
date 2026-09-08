function varargout = demo_reproductions(method,varargin)
%DEMO_REPRODUCTIONS List or run one explicit paper-method entry point.
%   catalog=demo_reproductions() lists methods WITHOUT running any demo.
%   demo_reproductions('meanfield_lqg2025',outputDirectory,cfg) forwards
%   arguments to that method's native entry. See docs/IMPLEMENTED_API.md.
%   PINN selections run actual training. No method is run by default.
root=fileparts(mfilename('fullpath'));
allMethods=adp_catalog();
if nargin==0
    catalog=allMethods(:,{'method','entryPoint','runsNeuralTraining'});
    disp(catalog);
    if nargout>0, varargout{1}=catalog; end
    return
end
if isstring(method) && isscalar(method), method=char(method); end
if ~ischar(method) || size(method,1)~=1
    error('adp:entry:Method','Use one method ID from demo_reproductions().');
end
oldPath=path; oldRng=rng; oldFolder=pwd;
restore=onCleanup(@()restoreSession(oldPath,oldRng,oldFolder)); %#ok<NASGU>
selected=find(strcmp(allMethods.method,method),1);
if isempty(selected)
    error('adp:entry:UnknownMethod','Unknown method ID: %s.',method);
end
if strcmp(method,'baseline'), addpath(root,fullfile(root,'src'));
else, addpath(fullfile(root,allMethods.directory{selected})); end
entry=str2func(allMethods.entryPoint{selected});
if nargout==0
    entry(varargin{:});
else
    [varargout{1:nargout}]=entry(varargin{:});
end
end

function restoreSession(oldPath,oldRng,oldFolder)
path(oldPath); rng(oldRng);
if ~strcmp(pwd,oldFolder), cd(oldFolder); end
end
