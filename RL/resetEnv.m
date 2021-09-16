% Copyright 2021 The MathWorks, Inc.
function in = resetEnv(in)
%     in = in.setVariable('theta0', pi);
    angle = pi/4*(rand - 0.5);
    in = in.setVariable('phi0', angle);
end