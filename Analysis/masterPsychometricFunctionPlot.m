% masterPsychometricFunctionPlot - Plots psychometric functions for one or more treatment groups.
%
% This function generates and saves a psychometric plot (mean ± SEM) across four concentrations
% for each specified treatment group. The standard error can be computed per session or per trial.
% It also returns session-level feature matrices for downstream statistical analysis.
%
% Syntax:
%   featureData = masterPsychometricFunctionPlot(feature)
%   [T1, T2, ...] = masterPsychometricFunctionPlot(feature, animalList, figname, semMethod, group1, group2, ...)
%
% Inputs:
%   feature     - (char/string) Name of the feature column to analyze (e.g., 'approach_rate')
%   animalList  - (optional, numeric/cell) List of subject IDs to include. Default: all animals
%   figname     - (optional, char/string) Name used when saving the figure. Default: 'Psych plot_psych'
%   semMethod   - (optional, char/string) 'session' (default) or 'trial'; determines SEM computation method
%   group1, group2, ... - One or more treatment group(s); each can be a string or a cell array of group names
%
% Outputs:
%   If one output:
%       featureData - Cell array, one entry per group, each containing [nSessions x 4] matrix of feature values
%   If multiple outputs:
%       T1, T2, ... - Separate feature matrices [nSessions x 4] for each group
%
% Notes:
%   - The x-axis of the plot corresponds to 4 concentrations (from low to high), represented by feeders 4 to 1.
%   - Uses helper functions: treatmentIDfun, fetchHealthDataTable, cleanBadSessionsFromTable,
%     getPsychometricBySession, getPsychometricByTrial.
%   - Saves the figure as .fig to 'Fig files' directory in the script's folder.
%
% Example:
%   [T1, T2] = masterPsychometricFunctionPlot('approach_rate', [], [], 'trial', {'P2L1 Saline'}, {'P2L1 Ghrelin'});
%
% Author: Atanu Giri
% Date: 05/12/2025
%
function varargout = masterPsychometricFunctionPlot(feature, animalList, ...
    figname, semMethod, varargin)

% Set default animalList if not provided
if nargin < 2 || isempty(animalList)
    animalList = {};
end

% If no figname provided, use default
if isempty(figname)
    figname = 'Psych plot';
end

% Add '_psych' suffix
figname = sprintf('%s_psych', figname);

% SEM method
if nargin < 4 || isempty(semMethod)
    semMethod = 'session';
end

treatmentGroups = varargin;
treatmentIDs = cell(1, numel(treatmentGroups));

parfor i = 1:numel(treatmentGroups)
    % Connect to database
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');

    % Allow grouping of multiple treatment labels
    group_i = treatmentGroups{i};
    if ischar(group_i) || isstring(group_i)
        group_i = {group_i};  % wrap string in a cell
    end

    ids = [];
    for j = 1:numel(group_i)
        ids = [ids; treatmentIDfun(group_i{j}, conn)];
    end
    treatmentIDs{i} = ids;

    close(conn);
end

% Convert to comma-separated strings for SQL query
treatmentIDs_str = cellfun(@(x) strjoin(arrayfun(@num2str, x, 'UniformOutput', false), ','), ...
    treatmentIDs, 'UniformOutput', false);

treatment_data = cell(1, numel(treatmentGroups));

% L1 and L3 task in L1L3 will naturally have 20 trials
trtGroupsToExclude = {'P2L1L3 Baseline L1','P2L1L3 Baseline L3', ...
    'P2L1L3 BL for comb boost and alc L1', 'P2L1L3 BL for comb boost and alc L3', ...
    'P2L1L3 Boost and alcohol L1', 'P2L1L3 Boost and alcohol L3', ...
    'P2L1L3 Post alcohol L1', 'P2L1L3 Post alcohol L3'};

parfor i = 1:numel(treatment_data)
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');

    treatment_data{i} = fetchHealthDataTable(feature, treatmentIDs_str{i}, conn);
    flatGroups = treatmentGroups{i};
    if iscell(flatGroups)
        flatGroups = string(flatGroups);
    else
        flatGroups = string({flatGroups});
    end

    if all(~ismember(flatGroups, trtGroupsToExclude))
        treatment_data{i} = cleanBadSessionsFromTable(treatment_data{i}, feature);
    end

    close(conn);
end

% Filter treatment_data if animalList is provided
if ~isempty(animalList)
    for i = 1:numel(treatment_data)
        treatment_data{i} = treatment_data{i}(ismember(treatment_data{i}.subjectid, animalList), :);
    end
end

% Extract psychometric plot values
featureForEach = cell(1, numel(treatment_data));
avFeature = cell(1, numel(treatment_data));
stdErr = cell(1, numel(treatment_data));

% Plot figure
x = 1:4;
figure;
Colors = lines(numel(treatment_data));

for grp = 1:numel(treatment_data)

    if strcmpi(semMethod, 'session')
        [featureForEach{grp}, avFeature{grp}, stdErr{grp}, ~, ~, ~] = ...
            getPsychometricBySession(treatment_data{grp}, feature);
    elseif strcmpi(semMethod, 'trial')
        [featureForEach{grp}, avFeature{grp}, stdErr{grp}] = ...
            getPsychometricByTrial(treatment_data{grp}, feature);
    else
        error('semMethod must be either "session" or "trial"');
    end

    if iscell(treatmentGroups{grp})
        legendLabel = strjoin(treatmentGroups{grp}, ' + ');
    else
        legendLabel = treatmentGroups{grp};
    end
    plot(x, avFeature{grp}, 'LineWidth', 2, 'Color', Colors(grp,:), ...
        'DisplayName', legendLabel);
    hold on;
    errorbar(x, avFeature{grp},stdErr{grp},'LineStyle', 'none', ...
        'LineWidth', 1.5, 'Color','k','HandleVisibility', 'off');
end

hold off;
legend('show', 'Interpreter', 'none');
ylabel(sprintf('%s', feature), 'Interpreter','none', 'FontSize', 25);
xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);
xticks(1:4);
label = {'0.5','2','5','9'};
set(gca,'xticklabel',label,'FontSize',15);

% Return output
if nargout <= 1
    % Return a single cell array if only one output is requested
    varargout{1} = featureForEach;
else
    varargout = cell(1, numel(treatment_data));
    % Return separate outputs for each group if multiple outputs are requested
    for i = 1:numel(treatment_data)
        varargout{i} = featureForEach{i};
    end
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