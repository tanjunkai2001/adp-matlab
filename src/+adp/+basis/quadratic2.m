function [phi, dphi] = quadratic2(x)
%QUADRATIC2 Two-state quadratic features with an explicit cross-term factor.
% x is 2-by-N. phi is 3-by-N; dphi(:,:,k) is 3-by-2.
% V(x)=W'*phi(x), W=[P11;P12;P22], P=[W(1),W(2);W(2),W(3)].
validateattributes(x, {'double'}, {'real','finite','2d','nrows',2}, ...
    mfilename, 'x');
phi = [x(1,:).^2; 2*x(1,:).*x(2,:); x(2,:).^2];
if nargout > 1
    dphi = zeros(3,2,size(x,2));
    for k = 1:size(x,2)
        dphi(:,:,k) = [2*x(1,k),0; 2*x(2,k),2*x(1,k); 0,2*x(2,k)];
    end
end
end
