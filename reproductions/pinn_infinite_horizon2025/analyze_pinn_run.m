function report = analyze_pinn_run(runDir)
%ANALYZE_PINN_RUN Common-grid diagnostics and an independent local LQR baseline.
% This only evaluates frozen checkpoints. It does not tune or retrain a model.
s=load(fullfile(runDir,'result.mat'),'result');result=s.result;
report=struct('runDirectory',runDir,'evaluation','same 41-point-per-axis grid across horizons', ...
    'costScope','integrated cost over the saved 8-second simulation horizon, not infinite-horizon cost');
for k=1:numel(result.experiments)
    experiment=result.experiments{k};rows=[];
    for j=1:numel(experiment.stages)
        stage=experiment.stages{j};cfg=stage.config;
        axisPoints=linspace(-cfg.evaluationDomain,cfg.evaluationDomain,41);
        if cfg.stateDimension==1,x=axisPoints;else
            [a,b]=ndgrid(axisPoints,axisPoints);x=[a(:)';b(:)'];
        end
        [v,dv]=dlfeval(@differentiateValue,stage.network,dlarray([x;zeros(1,size(x,2))],'CB'),cfg);
        v=extractdata(v);dv=extractdata(dv);[f,g,q]=pinn_problem(cfg.problem,x);
        u=-sum(g.*dv(1:end-1,:),1)/(2*cfg.R);
        r=sum(f.*dv(1:end-1,:),1)+q-cfg.R*u.^2;
        rows=[rows;cfg.totalHorizon,mean(r.^2),max(abs(r)),min(v),max(abs(u))]; %#ok<AGROW>
        columns=[cellstr("x"+(1:cfg.stateDimension)),{'value','input','steadyHJBResidual'}];
        writetable(array2table([x',v',u',r'],'VariableNames',columns), ...
            fullfile(runDir,sprintf('%s_T%g_common_grid.csv',cfg.problem,cfg.totalHorizon)));
        writeJson(fullfile(runDir,sprintf('%s_T%g_config.json',cfg.problem,cfg.totalHorizon)),cfg);
    end
    report.(experiment.problem).commonGrid=array2table(rows,'VariableNames', ...
        {'horizon','steadyMSE','steadyMaxAbs','minimumValue','maxAbsInput'});
    writetable(report.(experiment.problem).commonGrid,fullfile(runDir,[experiment.problem '_horizon_comparison.csv']));
    % Plot training curves with a verified logarithmic axis.
    fig=figure('Visible','off','Color','w','Position',[100,100,900,560]);
    tiledlayout(2,2);nexttile;hold on;
    for j=1:numel(experiment.stages)
        stage=experiment.stages{j};plot(stage.history(:,1),stage.history(:,2), ...
            'DisplayName',sprintf('T=%g',stage.config.totalHorizon));
    end
    set(gca,'YScale','log');xlabel('Adam update');ylabel('Training MSE');grid on;legend('Location','best');
    nexttile;semilogy(rows(:,1),rows(:,2),'o-');xlabel('Total horizon');ylabel('Steady HJB MSE (grid)');grid on;
    last=experiment.stages{end};nexttile;hold on;
    for j=1:numel(last.evaluation.closedLoop),r=last.evaluation.closedLoop{j};plot(r.time,vecnorm(r.state,2,2));end
    xlabel('Time (s)');ylabel('State norm');grid on;nexttile;hold on;
    for j=1:numel(last.evaluation.closedLoop),r=last.evaluation.closedLoop{j};plot(r.time,r.accumulatedCost);end
    xlabel('Time (s)');ylabel('Accumulated cost');grid on;
    sgtitle([strrep(experiment.problem,'_',' ') ' : trained HJB neural network']);
    exportgraphics(fig,fullfile(runDir,[experiment.problem '_analysis.png']),'Resolution',160);close(fig);
    if strcmp(experiment.problem,'pendulum')
        cfg=last.config;mass=1/3;ell=2/3;J=(4/3)*mass*ell^2;
        a=mass*9.8*ell/J;d=0.2/J;b=1/J;
        p12=(-a+sqrt(a^2+b^2))/b^2;
        p22=(-d+sqrt(d^2+b^2*(2*p12+1)))/b^2;
        p11=d*p12+a*p22+b^2*p12*p22;P=[p11,p12;p12,p22];K=b*[p12,p22];
        A=[0,1;-a,-d];B=[0;b];report.pendulum.localLQRAREMax=max(abs(A'*P+P*A-P*(B*B')*P+eye(2)),[],'all');
        report.pendulum.localLQRGain=K;comparison=[];
        for j=1:size(cfg.initialStates,2)
            x0=cfg.initialStates(:,j);
            [~,z]=ode45(@(~,z) baselineRHS(z,K,cfg),[0,cfg.simulationHorizon],[x0;0],odeset('RelTol',1e-9,'AbsTol',1e-11));
            learned=last.evaluation.closedLoop{j};
            comparison=[comparison;j,x0',learned.integratedCost,z(end,end),learned.finalNorm,norm(z(end,1:2))]; %#ok<AGROW>
        end
        tableOut=array2table(comparison,'VariableNames',{'trajectory','x1_initial','x2_initial','PINNCost','localLQRCost','PINNFinalNorm','localLQRFinalNorm'});
        writetable(tableOut,fullfile(runDir,'pendulum_closedloop_comparison.csv'));
        report.pendulum.closedLoopComparison=table2struct(tableOut);
    end
    report.(experiment.problem).commonGrid=table2struct(report.(experiment.problem).commonGrid);
end
writeJson(fullfile(runDir,'analysis_summary.json'),report);
save(fullfile(runDir,'analysis.mat'),'report');
end
function [v,dv]=differentiateValue(net,xt,cfg)
v=pinn_value(net,xt,cfg);dv=dlgradient(sum(v,'all'),xt);
end
function dz=baselineRHS(z,K,cfg)
x=z(1:2);u=-K*x;[f,g,q]=pinn_problem(cfg.problem,x);dz=[f+g*u;q+cfg.R*u^2];
end
function writeJson(file,value)
fid=fopen(file,'w');closer=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true)); %#ok<NASGU>
end
