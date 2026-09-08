function [f,g,q,oracle] = pinn_problem(name,x)
%PINN_PROBLEM Known dynamics and cost in Fotiadis/Vamvoudakis (2025), sec. 6.
% x is n-by-batch. R=1 in the executed cases. Oracle never enters training.
oracle = struct('value',[],'control',[]);
switch string(name)
    case "scalar_lqr"
        f = 0*x; g = 0*x+1; q = x.^2;
        oracle.value = x.^2; oracle.control = -x;
    case "pendulum"
        M=1/3; ell=2/3; inertia=(4/3)*M*ell^2; damping=0.2;
        f=[x(2,:);(-M*9.8*ell*sin(x(1,:))-damping*x(2,:))/inertia];
        g=[0*x(1,:);0*x(1,:)+1/inertia];
        q=sum(x.^2,1);
    case {"quartic_paper","quartic_corrected"}
        a=x(1,:); b=x(2,:);
        f=[-a+b+2*b.^3; -0.5*(a+b)+0.5*b.*(1+2*b.^2).*sin(a).^2];
        g=[0*a;sin(a)];
        coefficient=1+double(string(name)=="quartic_corrected");
        q=a.^2+b.^2+coefficient*b.^4;
        % Claimed oracle only solves the corrected-cost problem (coefficient=2).
        if string(name)=="quartic_corrected"
            oracle.value=0.5*a.^2+b.^2+b.^4;
            oracle.control=-sin(a).*(b+2*b.^3);
        end
    otherwise
        error('pinn:UnknownProblem','Unknown problem %s.',name);
end
end
