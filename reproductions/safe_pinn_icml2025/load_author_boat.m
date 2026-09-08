function [net,parity]=load_author_boat(weightFile)
%LOAD_AUTHOR_BOAT Import the separately supplied author checkpoint tensors.
% All inference, physical derivatives and closed-loop evaluation run in MATLAB.
s=load(weightFile);net=struct('kind','author_checkpoint','epoch',s.checkpoint_epoch);
for k=1:5
    net.weights{k}=s.(sprintf('W%d',k));net.biases{k}=s.(sprintf('b%d',k));
end
[V,p]=dlfeval(@valueGradient,net,dlarray(s.golden_inputs,'CB'));
parity=struct('valueMaxAbsError',max(abs(V-s.golden_value_double),[],'all'), ...
    'gradientMaxAbsError',max(abs(p-s.golden_gradient_double),[],'all'), ...
    'float32ValueDifference',max(abs(V-double(s.golden_value_single)),[],'all'), ...
    'float32GradientDifference',max(abs(p-double(s.golden_gradient_single)),[],'all'), ...
    'goldenSamples',size(s.golden_inputs,2),'checkpointEpoch',s.checkpoint_epoch);
assert(parity.valueMaxAbsError<1e-9 && parity.gradientMaxAbsError<1e-8, ...
    'boat:CheckpointParity','MATLAB import disagrees with independent PyTorch values/derivatives.');
end
function [V,p]=valueGradient(net,S)
v=boat_value(net,S);p=dlgradient(sum(v,'all'),S);V=extractdata(v);p=extractdata(p);
end
