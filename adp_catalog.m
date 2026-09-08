function catalog=adp_catalog()
%ADP_CATALOG Read the single method registry used by demos and test discovery.
root=fileparts(mfilename('fullpath'));
registry=jsondecode(fileread(fullfile(root,'registry','reproductions.json')));
methods=registry.methods; n=numel(methods)+1;
ids=cell(n,1); entries=ids; directories=ids; required=ids; optional=ids;
training=false(n,1);
ids{1}=registry.baseline.id; entries{1}=registry.baseline.entry_point;
directories{1}=''; required{1}={'MATLAB'}; optional{1}={};
for k=1:numel(methods)
    if iscell(methods), item=methods{k}; else, item=methods(k); end
    j=k+1;
    ids{j}=item.id; entries{j}=item.entry_point; directories{j}=item.directory;
    training(j)=item.runs_neural_training;
    required{j}=cellstr(string(item.required_products));
    optional{j}=cellstr(string(item.optional_products));
end
catalog=table(ids,entries,directories,training,required,optional, ...
    'VariableNames',{'method','entryPoint','directory','runsNeuralTraining', ...
    'requiredProducts','optionalProducts'});
end
