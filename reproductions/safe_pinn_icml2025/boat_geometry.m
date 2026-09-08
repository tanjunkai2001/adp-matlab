function [g,l]=boat_geometry(X)
%BOAT_GEOMETRY Paper Appendix B.1, goal (1.5,0) and two circular obstacles.
g=max(.4-sqrt((X(1,:)+.5).^2+(X(2,:)-.5).^2), ...
    .5-sqrt((X(1,:)+1).^2+(X(2,:)+1.2).^2));
l=sqrt((X(1,:)-1.5).^2+X(2,:).^2);
end
