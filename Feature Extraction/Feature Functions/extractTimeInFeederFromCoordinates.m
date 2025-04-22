% Author: Atanu Giri
% Date: 01/19/2025
%
function [timeInConc9, timeInConc5, timeInConc2, timeInConc0_5] = ...
    extractTimeInFeederFromCoordinates(X, Y, maze)
if maze == 1
    filter9 = X >= -1.05 & X <= -0.75 & Y >= 0.75 & Y <= 1.05;
    timeInConc9 = sum(filter9)*0.1; % Time step in 0.1 s
    filter5 = X >= -1.05 & X <= -0.75 & Y >= -0.05 & Y <= 0.25;
    timeInConc5 = sum(filter5)*0.1;
    filter2 = X >= -0.25 & X <= 0.05 & Y >= -0.05 & Y <= 0.25;
    timeInConc2 = sum(filter2)*0.1;
    filter0_5 = X >= -0.25 & X <= 0.05 & Y >= 0.75 & Y <= 1.05;
    timeInConc0_5 = sum(filter0_5)*0.1;

elseif maze == 2
    filter9 = X >= 0.75 & X <= 1.05 & Y >= -0.05 & Y <= 0.25;
    timeInConc9 = sum(filter9)*0.1;
    filter5 = X >= -0.05 & X <= 0.25 & Y >= -0.05 & Y <= 0.25;
    timeInConc5 = sum(filter5)*0.1;
    filter2 = X >= -0.05 & X <= 0.25 & Y >= 0.75 & Y <= 1.05;
    timeInConc2 = sum(filter2)*0.1;
    filter0_5 = X >= 0.75 & X <= 1.05 & Y >= 0.75 & Y <= 1.05;
    timeInConc0_5 = sum(filter0_5)*0.1;

elseif maze == 3
    filter9 = X >= -0.25 & X <= 0.05 & Y >= -1.05 & Y <= -0.75;
    timeInConc9 = sum(filter9)*0.1;
    filter5 = X >= -1.05 & X <= -0.75 & Y >= -1.05 & Y <= -0.75;
    timeInConc5 = sum(filter5)*0.1;
    filter2 = X >= -1.05 & X <= -0.75 & Y >= -0.25 & Y <= 0.05;
    timeInConc2 = sum(filter2)*0.1;
    filter0_5 = X >= -0.25 & X <= 0.05 & Y >= -0.25 & Y <= 0.05;
    timeInConc0_5 = sum(filter0_5)*0.1;

elseif maze == 4
    filter9 = X >= -0.05 & X <= 0.25 & Y >= -0.25 & Y <= 0.05;
    timeInConc9 = sum(filter9)*0.1;
    filter5 = X >= 0.75 & X <= 1.05 & Y >= -0.25 & Y <= 0.05;
    timeInConc5 = sum(filter5)*0.1;
    filter2 = X >= 0.75 & X <= 1.05 & Y >= -1.05 & Y <= -0.75;
    timeInConc2 = sum(filter2)*0.1;
    filter0_5 = X >= -0.05 & X <= 0.25 & Y >= -1.05 & Y <= -0.75;
    timeInConc0_5 = sum(filter0_5)*0.1;

end