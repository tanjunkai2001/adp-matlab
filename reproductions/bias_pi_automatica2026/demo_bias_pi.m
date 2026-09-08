function varargout=demo_bias_pi(outputDirectory,cfg)
%DEMO_BIAS_PI Run one explicitly selected nonlinear Bias-PI example.
%   demo_bias_pi(outputDirectory,struct('example','pendulum'))
%   demo_bias_pi(outputDirectory,struct('example','arm'))
if nargin<1, outputDirectory=[]; end
if nargin<2, cfg=struct; end
if ~isfield(cfg,'example'), cfg.example='pendulum'; end
example=cfg.example; cfg=rmfield(cfg,'example');
if isempty(outputDirectory)
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputDirectory=fullfile(root,'runs',['bias-pi-',char(example),'-', ...
        char(datetime('now','Format','yyyyMMdd-HHmmss-SSS'))]);
end
switch example
    case 'pendulum', entry=@demo_bias_pi_pendulum;
    case 'arm', entry=@demo_bias_pi_arm;
    otherwise, error('biaspi:Example','Use pendulum or arm.');
end
if nargout==0, entry(outputDirectory,cfg);
else, [varargout{1:nargout}]=entry(outputDirectory,cfg); end
end
