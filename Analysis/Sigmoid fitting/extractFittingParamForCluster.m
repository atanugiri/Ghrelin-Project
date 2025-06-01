% Author: Atanu Giri
% Date: 07/02/2024
%
% Extract fitting parameters for clustering. Possibly wrong.

function extractFittingParamForCluster(treatment, feature)

% treatment = 'P2L1 Boost'; feature = 'approachavoid'; fitType = 1;

% Connect to database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');

treatmentID = treatmentIDfun(treatment, conn);
treatmentID = strjoin(arrayfun(@num2str, treatmentID, 'UniformOutput', false), ',');
treatment_data = fetchHealthDataTable(feature, treatmentID, conn);
treatment_data = cleanBadSessionsFromTable(treatment_data, feature, treatment);

% File where the fitting results (.mat) and fit plot (pdf) will be saved
fileName = sprintf("%s_%s_fitting_param", treatment, feature);

scriptDir = fileparts(mfilename('fullpath'));
folderName = 'Mat files for cluster';
myPath = fullfile(scriptDir, folderName);
% Check if the folder exists, if not, create it
if ~exist(myPath, 'dir')
    mkdir(myPath);
end

animalList = unique(treatment_data.subjectid);

for animal = 1:length(animalList)
    animalData = treatment_data(treatment_data.subjectid == animalList(animal),:);
    sessionList = unique(animalData.referencetime);

    for session = 1:length(sessionList)
        sessionData = animalData(animalData.referencetime == sessionList(session),:);
        featureList = psychometricFunValues(sessionData, feature);
        %         fprintf('%.2f, ', featureList);
        %         fprintf('\n');

        % Check for NaN values in y
        if any(isnan(featureList))
            disp('Skipping iteration due to NaN values in y.');
            continue; % Skip the current iteration

        elseif any(isempty(featureList))
            disp('Skipping iteration due to empty values in y.');
            continue;
        end

        % Fitting
        [h, fit_params, R_squared] = sigmoid_analysis(featureList);

        title([sprintf('Animal: %s, Session: %s\nR^2 = %.3f\n', ...
            animalList(animal), sessionList(session), R_squared), ...
            sprintf('%.3f, ', fit_params)]);

        trtmntFitData{animal, session} = struct('Animal', animalList(animal), ...
            'Date', sessionList(session), 'fit_params', fit_params, 'R_squared', R_squared);


        % Save plots
        figFolderName = "Fig files for cluster";
        myPdfPath = fullfile(scriptDir, figFolderName);
        % Check if the folder exists, if not, create it
        if ~exist(myPdfPath, 'dir')
            mkdir(myPdfPath);
        end

        pdf_file = fullfile(myPdfPath, sprintf("%s.pdf", fileName));

        % Save the figure to a PDF file with a separate page for each figure
        if animal == 1 && session == 1
            exportgraphics(h, pdf_file, 'ContentType', 'vector');
        else
            exportgraphics(h, pdf_file, 'ContentType', 'vector', 'Append', true);
        end

        close(h);

    end % end of 1st session

end % end of 1st animal

% Save the trtmntFitData variable to a MAT file
save(fullfile(myPath, sprintf("%s.mat", fileName)), "trtmntFitData");

end