% Author: Atanu Giri
% Date: 05/12/2025
%
% This function calculates the featureForEach and related information based
% on each animal and each session.
%
function [featureForEach, avFeature, stdErr, animalName, dateList, trialCt] = getPsychometricBySession(dataTable, feature)

animalList = unique(dataTable.subjectid);
featureForEach = [];
animalName = [];
dateList = [];
trialCt = [];
rowToUpdate = 0;

for animal = 1:length(animalList)
    animalData =  dataTable(dataTable.subjectid == animalList(animal), :);
    sessionList = unique(animalData.referencetime);

    featureForEach = [featureForEach; zeros(length(sessionList), 4)];
    animalName = [animalName; repelem(animalList(animal), length(sessionList), 1)];
    dateList = [dateList; sessionList];

    for session = 1:length(sessionList)
        sessionData = animalData(animalData.referencetime == sessionList(session), :);
        rowToUpdate = rowToUpdate + 1;

        for conc = 1:4
            feederToFetch = 5 - conc;
            dataFilter = sessionData.realFeederId == feederToFetch;
            featureArray = sessionData.(feature)(dataFilter, :);
            featureArray = featureArray(isfinite(featureArray));
            featureForEach(rowToUpdate, conc) = mean(featureArray);
            trialCt(rowToUpdate, conc) = length(featureArray);
        end
    end
end

% Remove any rows with NaNs
invalidRows = any(isnan(featureForEach), 2);
featureForEach(invalidRows, :) = [];
animalName(invalidRows, :) = [];
dateList(invalidRows, :) = [];
trialCt(invalidRows, :) = [];

% Calculate mean and SEM across sessions
avFeature = mean(featureForEach, 1);
stdErr = std(featureForEach, 0, 1) ./ sqrt(size(featureForEach, 1));

end