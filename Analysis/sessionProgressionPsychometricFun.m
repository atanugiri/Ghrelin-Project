% Author: Atanu Giri
% Date: 01/26/2025
%
% 'feature' can be any column from ghrelin_featuretable.
% Example usage:
% featureForEach = sessionProgressionPsychometricFun('approachavoid', ...
% 'P2A Boost and alcohol', 'n')
%
% OR
%
% animalList = {'aladdin', 'jafar', 'jimi', 'jr', 'mike', 'scar', 'sully'};
% featureForEach = sessionProgressionPsychometricFun('approachavoid', ...
% 'P2A Boost and alcohol', 'n', animalList)
%
function varargout = sessionProgressionPsychometricFun(feature, ...
treatmentGroup, combineSections, animalList)

% feature = 'entry_time'; treatmentGroup = 'P2A Boost and alcohol'; 
% combineSections = 'y'; animalList = {};

if nargin < 4
    animalList = {};
end

% Connect to database
datasource = 'live_database';
conn = database(datasource, 'postgres', '1234');

treatmentIDs = treatmentIDfun(treatmentGroup, conn);

% Generate the idList from the filtered data
treatmentIDs_str = strjoin(arrayfun(@num2str, treatmentIDs, 'UniformOutput', false), ',');
treatment_data = fetchHealthDataTable(feature, treatmentIDs_str, conn);
treatment_data = cleanBadSessionsFromTable(treatment_data, feature, treatmentGroup);

% Filter treatment_data if animalList is provided
if ~isempty(animalList)
    treatment_data = treatment_data(ismember(treatment_data.subjectid, animalList), :);
end

[featureForEach, stdErr, trialCt] = getPsychometricBySession(treatment_data, feature);

% Special for 'P2A Boost and alcohol'
if strcmpi(treatmentGroup, 'P2A Boost and alcohol') & ~strcmpi(feature, 'entry_time')
    validSessions = trialCt(:,1) > 80;
    featureForEach = featureForEach(validSessions, :);
    stdErr = stdErr(validSessions, :);

    % Remove the first row as the animals were introduced to alcohol
    % for the first time
    featureForEach(1, :) = [];
    stdErr(1, :) = [];
end

if strcmpi(combineSections, 'y')
    % Calculate the approximate size of each section
    numUniqueDates = size(featureForEach, 1);
    sectionSize = floor(numUniqueDates / 3);
    numEarlyDates = sectionSize;
    numLateDates = sectionSize;
    numMiddleDates = numUniqueDates - (numEarlyDates + numLateDates);

    % Partition the dates into 3 sections
    earlyDates = 1:numEarlyDates;
    middleDates = numEarlyDates + 1:numEarlyDates + numMiddleDates;
    lateDates = numEarlyDates + numMiddleDates + 1:numUniqueDates;

    dateFilter = {earlyDates, middleDates, lateDates};
    sessionSectionData = cell(1, 3);
    avgSectionData = zeros(3,4);  % 3 section x 4 conc
    stdErrSectionData = zeros(3,4);

for section = 1:numel(dateFilter)
    sessionSectionData{section} = featureForEach(dateFilter{section}, :);
    avgSectionData(section,:) = mean(sessionSectionData{section});
    stdErrSectionData(section,:) = std(sessionSectionData{section}) ./ ...
        size(sessionSectionData{section}, 1);
end
end

% Return output and select data to plot
if strcmpi(combineSections, 'y')
    dataToPlot = avgSectionData;
    stdErrToPlot = stdErrSectionData;
    
    if nargout <= 1
        varargout{1} = sessionSectionData;
    else
        varargout = cell(1, numel(sessionSectionData));
        % Return separate outputs for each cell
        for i = 1:min(nargout, 3) % Ensure it doesn't exceed the number of cells
            varargout{i} = sessionSectionData{i};
        end
    end

else
    dataToPlot = featureForEach;
    stdErrToPlot = stdErr;
    varargout{1} = featureForEach;
end

% Plot Psychometric function
x = 1:4;
figure;
Colors = parula(size(dataToPlot,1));

for session = 1:size(dataToPlot,1)
    % Plot sessions
    plot(x, dataToPlot(session,:), '.-', 'LineWidth', 2, 'Color', Colors(session, :), ...
        'DisplayName',sprintf('Session_%d', session));
    hold on;
    errorbar(x, dataToPlot(session,:), stdErrToPlot(session,:),'LineStyle', 'none', ...
        'LineWidth', 1.5, 'Color','k', 'HandleVisibility', 'off');
end

hold off;
% Add label and legend
xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);
ylabel(sprintf('%s', feature), 'Interpreter','none', 'FontSize', 25);
xticks(1:4);
label = {'0.5','2','5','9'};
set(gca,'xticklabel',label,'FontSize',15);
legend('show', 'Interpreter', 'none');

title(sprintf('%s', treatmentGroup), 'Interpreter','latex','FontSize',25);