% Author: Atanu Giri
% Date: 03/24/2024
%
% This function takes feature, splitByGender, and treatment group name/s as
% input and overlays the psychometric function plots per session.
%
% Example usage:
% individualPsychometricPlotOverlay("approachavoid", 'n', "P2L1 Ghrelin")

%% Invokes treatmentIDfun, fetchHealthDataTable, psychometricFunValues

function individualPsychometricPlotOverlay(feature, splitByGender, trtmntGrp)

% feature = 'approachavoid'; splitByGender = 'n';
% trtmntGrp = 'P2L1 BL for comb boost and alc';

% Connect to database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');

treatmentIDs = treatmentIDfun(trtmntGrp, conn);

% Generate the idList from the filtered data
treatmentIDs_str = strjoin(arrayfun(@num2str, treatmentIDs, 'UniformOutput', false), ',');
    
treatment_data = fetchHealthDataTable(feature, treatmentIDs_str, conn);

% L1 and L3 task in L1L3 will naturally have 20 trials
trtGroupsToExclude = {'P2L1L3 BL for comb boost and alc L1', ...
    'P2L1L3 BL for comb boost and alc L3','P2L1L3 Boost and alcohol L1', ...
    'P2L1L3 Boost and alcohol L3', 'P2L1L3 Post alcohol L1', ...
    'P2L1L3 Post alcohol L3'};

if ~ismember(trtmntGrp,trtGroupsToExclude)
    treatment_data = cleanBadSessionsFromTable(treatment_data, feature); % Remove bad sessions
end

% Plotting
x = 1:4;
figure;
hold on;

if strcmpi(splitByGender, 'n')
    [totalSessions, validSessions] = treatrmentGroupPlot(treatment_data);
    text(min(xlim), max(ylim), sprintf('n = %s', num2str(totalSessions)));
    fprintf('Total sessions = %d\n', totalSessions);
    fprintf('Valid sessions = %d\n', validSessions);

    % Add x ticklabel
    ylabel(sprintf('%s', feature), 'Interpreter','none');
    xticks(1:4);
    label = {'0.5','2','5','9'};
    set(gca,'xticklabel',label,'FontSize',15);

elseif strcmpi(splitByGender, 'y')
        maleData = treatment_data(lower(treatment_data.gender) == 'male', :);
        femaleData = treatment_data(lower(treatment_data.gender) == 'female', :);

        genderData = {maleData, femaleData};
        totalSessions = zeros(1,2);
        validSessions = zeros(1,2);

        for gender = 1:numel(genderData)
            subplot(1,2,gender);
            hold on;

            [totalSessions(gender), validSessions(gender)] = ...
                treatrmentGroupPlot(genderData{gender});
            fprintf('Total sessions = %d\n', totalSessions(gender));
            fprintf('Valid sessions = %d\n', validSessions(gender));

            if gender == 1
                title("Male", 'Interpreter','latex','FontSize',25);
                ylabel(sprintf('%s', feature), 'Interpreter','none');
            elseif gender == 2
                title("Female", 'Interpreter','latex','FontSize',25);
            end

            text(min(xlim), max(ylim), sprintf('n = %s', num2str(totalSessions(gender))));

            xticks(1:4);
            label = {'0.5','2','5','9'};
            set(gca,'xticklabel',label,'FontSize',15);
        end

end

% Add legends
legend(gca, trtmntGrp, 'Location', 'best');
hold off;

% Figure name
if strcmpi(splitByGender, 'n')
    figname = sprintf('%s_%s_indiv_psych',trtmntGrp,string(feature));
else
    figname = sprintf('%s_%s_MvF_indiv_psych',trtmntGrp,string(feature));
end

% Save figure
scriptDir = fileparts(mfilename('fullpath'));
folderName = 'Fig files';
myPath = fullfile(scriptDir, folderName);
% Check if the folder exists, if not, create it
if ~exist(myPath, 'dir')
    mkdir(myPath);
end

savefig(gcf, fullfile(myPath, figname));



%% Description of treatrmentGroupPlot
    function [totalSessions, validSessions] = treatrmentGroupPlot(currentGrpData)

        totalSessions = 0; % total sessions counter
        validSessions = 0; % valid sessions counter

        animalList = unique(currentGrpData.subjectid);

        for animal = 1:length(animalList)
            animalData = currentGrpData(currentGrpData.subjectid == animalList(animal),:);
            sessionList = unique(animalData.referencetime);
            totalSessions = totalSessions + numel(sessionList); % total sessions counter

            %% Reduce the number of plots for clarity if needed (comment out if not needed)
            maxSessPlot = 1;
            if numel(sessionList) > maxSessPlot
                rng(42); % Set the random number generator to default settings for reproducibility
                randomIdx = randperm(numel(sessionList));
                sessionList = sessionList(randomIdx(1:maxSessPlot));
            end

            for session = 1:length(sessionList)
                sessionData = animalData(animalData.referencetime == sessionList(session),:);
                %                     fprintf('%d trials in session\n', height(sessionData));

                try
                    featureList = psychometricFunValues(sessionData, feature);

                    plot(x, featureList, 'LineWidth', 1, 'Color', 'b');
                    validSessions = validSessions + 1;
                catch
                    fprintf('Something wrong :( \n')
                end

            end % end of 1st session

        end % end of 1st animal

    end

end