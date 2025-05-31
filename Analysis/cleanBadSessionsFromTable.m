% Author: Atanu Giri
% Date: 05/13/2024
%
% Delete the bad sessions (where number of trials < 40 and there is a 
% nan entry at any concentration)
%
function Data = cleanBadSessionsFromTable(Data, feature)

% initiate id array to delete
deleteIDs = [];

animalList = unique(Data.subjectid);

for animal = 1:length(animalList)
    animalData = Data(Data.subjectid == animalList(animal),:);
    sessionList = unique(animalData.referencetime);

    for session = 1:length(sessionList)
        sessionData = animalData(animalData.referencetime == sessionList(session),:);

        if height(sessionData) < 40
            deleteIDs = [deleteIDs; sessionData.id]; % Exclude session
            continue;
        end

        if strcmpi(feature, 'approachavoid')
            featureList = getPsychometricByTrial(sessionData, feature);

            % If all of approach rate = 0, sensor not working.
            if all(featureList == 0)
                deleteIDs = [deleteIDs; sessionData.id]; % Exclude session
                continue;
            end
        end

    end % end of 1st session

end % end of 1st animal

Data(ismember(Data.id, deleteIDs), :) = [];

end