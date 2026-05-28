% masterPsychometricFunctionPlot - Plots psychometric functions for one or more treatment groups or ID lists.
%
% This function generates and saves a psychometric plot (mean ± SEM) across four concentrations
% for each specified group. Groups can be defined using pre-defined treatment labels or directly 
% by raw lists of trial IDs. The standard error can be computed per session or per trial.
% It also returns session-level feature matrices for downstream statistical analysis.
%
% Syntax:
%   featureData = masterPsychometricFunctionPlot(feature)
%   [T1, T2, ...] = masterPsychometricFunctionPlot(feature, animalList, figname, semMethod, ...
%                       distanceRange, group1, group2, ...)
%
% Inputs:
%   feature        - (char/string) Name of the feature column to analyze (e.g., 'approachavoid')
%   animalList     - (optional) Cell array or numeric array of subject IDs to include. Default: all animals
%   figname        - (optional) String used to save the figure. Default: 'Psych plot_psych'
%   semMethod      - (optional) 'session' (default) or 'trial'; determines SEM computation method
%   distanceRange  - (optional) 2-element numeric vector [min, max] to filter by distance. Default: [-Inf, Inf]
%   group1, group2, ... 
%                  - Each group can be:
%                       • A treatment group name (char/string)
%                       • A cell array of group names (to merge multiple)
%                       • A numeric array of trial IDs (raw idList)
%
% Outputs:
%   If one output:
%       featureData - 1xN cell array, each cell is a 1x4 cell array of session-level values per concentration
%   If multiple outputs:
%       T1, T2, ... - Separate 1x4 cell arrays for each group
%
% Notes:
%   - The x-axis represents 4 concentrations (from low to high), mapped to feeders 4 to 1.
%   - The function applies session cleanup only for known treatment groups (not raw ID lists).
%   - Helper functions used: treatmentIDfun, fetchHealthDataTable, cleanBadSessionsFromTable,
%     getPsychometricBySession, getPsychometricByTrial
%   - The resulting plot is saved as a `.fig` file inside the 'Fig files' folder located next to the script.
%
% Examples:
%   % Compare two named treatment groups
%   [T1, T2] = masterPsychometricFunctionPlot('approach_rate', [], [], 'trial', [], ...
%                   'P2L1 Saline', 'P2L1 Ghrelin');
%
%   % Combine two groups into one and compare with another
%   [T1, T2] = masterPsychometricFunctionPlot('approach_rate', [], [], 'session', [], ...
%                   {'P2L1 Saline', 'P2L1L3 Saline'}, 'P2L1 Ghrelin');
%
%   % Compare raw trial ID list with a treatment group
%   [T1, T2] = masterPsychometricFunctionPlot('approach_rate', [], 'figure1', 'trial', [5, 100], ...
%                   [101,102,103], 'P2L1 Ghrelin');
%
% Author: Atanu Giri
% Date: 05/12/2025
%
function varargout = masterPsychometricFunctionPlot(feature, animalList, ...
    figname, semMethod, distanceRange, varargin)

% Default for animalList
if nargin < 2 || isempty(animalList)
    animalList = {};
end

% Default for figname
if nargin < 3 || isempty(figname)
    figname = 'Psych plot';
end
figname = sprintf('%s_psych', figname);

% Default for semMethod
if nargin < 4 || isempty(semMethod)
    semMethod = 'session';
end

% Default for distanceRange
if nargin < 5 || isempty(distanceRange)
    distanceRange = [-Inf, Inf];
end

% Group input
treatmentGroups = varargin;
treatmentIDs = cell(1, numel(treatmentGroups));
groupLabels = cell(1, numel(treatmentGroups));
isCustomIDList = false(1, numel(treatmentGroups));

for i = 1:numel(treatmentGroups)
    databaseName = 'live_database';
    username = 'atanugiri';
    password = '';
    host = 'localhost';
    port = 5432;

    conn = postgresql(username, password, ...
        'Server', host, ...
        'DatabaseName', databaseName, ...
        'PortNumber', port);
    inputGroup = treatmentGroups{i};

    if isnumeric(inputGroup)
        % Raw ID list
        ids = inputGroup(:);  % Ensure column vector
        groupLabels{i} = sprintf('group %d', i);
        isCustomIDList(i) = true;
    else
        % Convert to cellstr if single group
        if ischar(inputGroup) || isstring(inputGroup)
            inputGroup = {char(inputGroup)};
        end

        ids = [];
        for j = 1:numel(inputGroup)
            ids = [ids; treatmentIDfun(inputGroup{j}, conn)];
        end
        groupLabels{i} = strjoin(inputGroup, ' + ');
    end

    treatmentIDs{i} = ids;
    close(conn);
end

% Prepare output containers
treatment_data = cell(1, numel(treatmentGroups));

for i = 1:numel(treatment_data)
    databaseName = 'live_database';
    username = 'atanugiri';
    password = '';
    host = 'localhost';
    port = 5432;

    conn = postgresql(username, password, ...
        'Server', host, ...
        'DatabaseName', databaseName, ...
        'PortNumber', port);
    treatment_data{i} = fetchHealthDataTable(feature, treatmentIDs{i}, conn, distanceRange);

    % Clean sessions only if not custom ID list
    if ~isCustomIDList(i)
        treatment_data{i} = cleanBadSessionsFromTable(treatment_data{i}, feature, treatmentGroups{i});
    end

    close(conn);
end

% Filter by animalList
if ~isempty(animalList)
    for i = 1:numel(treatment_data)
        treatment_data{i} = treatment_data{i}(ismember(treatment_data{i}.subjectid, animalList), :);
    end
end

% Prepare plotting
featureForEach = cell(1, numel(treatment_data));
avFeature = cell(1, numel(treatment_data));
stdErr = cell(1, numel(treatment_data));

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

    plot(x, avFeature{grp}, 'LineWidth', 2, 'Color', Colors(grp,:), ...
        'DisplayName', groupLabels{grp});
    hold on;
    errorbar(x, avFeature{grp}, stdErr{grp}, 'LineStyle', 'none', ...
        'LineWidth', 1.5, 'Color', 'k', 'HandleVisibility', 'off');
end

hold off;
legend('show', 'Interpreter', 'none');
ylabel(sprintf('%s', feature), 'Interpreter','none', 'FontSize', 25);
xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);
xticks(1:4);
set(gca,'xticklabel', {'0.5','2','5','9'}, 'FontSize', 15);

% Return output
if nargout <= 1
    varargout{1} = featureForEach;
else
    varargout = cell(1, numel(treatment_data));
    for i = 1:numel(treatment_data)
        varargout{i} = featureForEach{i};
    end
end

% Save figure
scriptDir = fileparts(mfilename('fullpath'));
figDir = fullfile(scriptDir, 'Fig files');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
savefig(gcf, fullfile(figDir, figname));
end