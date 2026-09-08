function data = mf_window_moments(m,dt,cfg)
%MF_WINDOW_MOMENTS Window empirical moments AFTER combining all MC paths.
% In particular, never average batchwise mean outer products.
mx=m.mean; mu=m.meanInput;
meanOuter=[mx(:,1).^2,mx(:,1).*mx(:,2),mx(:,2).^2];
meanXu=mx.*mu;
width=round(cfg.window/dt);
last=round(cfg.lastStart/dt)+1;
starts=(1:cfg.startStride:last).';
ends=starts+width;
assert(width>=1 && max(ends)<=size(m.second,1), ...
    'mf:Window','A complete observation interval is required.');
data.deltaSecond=m.second(ends,:)-m.second(starts,:);
data.intSecond=windows(m.second,starts,ends,dt);
data.intXu=windows(m.xu,starts,ends,dt);
data.intUu=windows(m.uu,starts,ends,dt);
data.deltaMeanOuter=meanOuter(ends,:)-meanOuter(starts,:);
data.intMeanOuter=windows(meanOuter,starts,ends,dt);
data.intMeanXu=windows(meanXu,starts,ends,dt);
m.meanOuter=meanOuter;
data.moments=m;
data.windowStarts=m.t(starts).';
data.windowEnds=m.t(ends).';
data.quadrature='Left endpoint time sums consistent with the recorded EM grid.';
end
function out=windows(values,starts,ends,dt)
accum=[zeros(1,size(values,2));cumsum(values(1:end-1,:),1)*dt];
out=accum(ends,:)-accum(starts,:);
end
