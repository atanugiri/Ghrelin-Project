% Author: Atanu Giri
% Date: 05/12/2025
%
% This function calculates the featureForEach and related information based
% on each trial.
%
function [featureForEach, avFeature, stdErr] = getPsychometricByTrial(dataTable, feature)

featureForEach = cell(1, 4);  % For possible post-hoc stats if needed
avFeature = zeros(1, 4);
stdErr = zeros(1, 4);

for conc = 1:4
    feederToFetch = 5 - conc;
    validRows = dataTable.realFeederId == feederToFetch & isfinite(dataTable.(feature));
    featureArray = dataTable.(feature)(validRows);

    featureForEach{conc} = featureArray;
    avFeature(conc) = mean(featureArray);
    stdErr(conc) = std(featureArray) / sqrt(length(featureArray));
end

end