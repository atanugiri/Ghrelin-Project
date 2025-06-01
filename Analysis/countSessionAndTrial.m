% Author: Atanu Giri
% Date: 01/31/2025
%
function trialCt = countSessionAndTrial(feature, trtGroup, animalList, conn)

if nargin < 4
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
end

treatmentIDs = treatmentIDfun(trtGroup, conn);
treatmentIDs_str = strjoin(arrayfun(@num2str, treatmentIDs, 'UniformOutput', false), ',');

% Fetch data
treatment_data = fetchHealthDataTable(feature, treatmentIDs_str, conn);
treatment_data = cleanBadSessionsFromTable(treatment_data, feature, trtGroup);

% Filter treatment_data by animalList
treatment_data = treatment_data(ismember(treatment_data.subjectid, animalList), :);
[~, ~, trialCt] = getPsychometricBySession(treatment_data, feature, animalList);