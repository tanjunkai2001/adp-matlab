function V=boat_value(net,S)
%BOAT_VALUE S=[remaining time; x; y; budget]. Hard terminal condition Eq.(7).
% The network learns the correction to max(phi-z,g); no optimal labels.
if isstruct(net) && strcmp(net.kind,'author_checkpoint')
    % Published model has four sine hidden layers and a soft terminal loss.
    V=(S-[0;-.5;0;7.38])./[1;2.5;2;7.48];
    for k=1:5
        V=fullyconnect(V,net.weights{k},net.biases{k});
        if k<5,V=sin(30*V);end
    end
    V=50*V+.5;
    return
end
scale=[2;2.5;2;7.48];center=[0;-.5;0;7.38];
input=(S-center)./scale;
[g,l]=boat_geometry(S(2:3,:));
V=max(l-S(4,:),g)+S(1,:).*forward(net,input);
end
