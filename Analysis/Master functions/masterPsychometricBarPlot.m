% masterPsychometricBarPlot - Plots summary bar graphs for one or more treatment groups or ID lists.
%
% This function computes and plots mean ± SEM of a given feature across specified concentrations,
% for each group. Groups can be defined using treatment group names, combined group labels, or raw
% trial ID lists. It supports flexible input and filtering, and the results can be returned for 
% downstream statistics.
%
% Syntax:
%   values = masterPsychometricBarPlot(feature)
%   [V1, V2, ...] = masterPsychometricBarPlot(feature, animalList, figname, semMethod, ...
%                      concentrationSubset, distanceRange, group1, group2, ...)
%
% Inputs:
%   feature            - (char/string) Name of the feature to analyze (e.g., 'timein_conc9')
%   animalList         - (optional) Cell or numeric array of subject IDs to include. Default: all
%   figname            - (optional) String used for saving the figure. Default: 'Psych_bar_plot_bar'
%   semMethod          - (optional) 'session' (default) or 'trial'; defines SEM calculation method
%   concentrationSubset- (optional) Vector of indices [1–4] specifying concentrations to include. Default: [1 2 3 4]
%   distanceRange      - (optional) 2-element numeric vector [min, max] to filter trials by distance. Default: [-Inf, Inf]
%   group1, group2, ... 
%                     - Each group can be:
%                         • A single treatment group name (string)
%                         • A cell array of treatment group names (merged into one)
%                         • A numeric array of trial IDs (raw idList)
%
% Outputs:
%   If one output:
%       values - 1xN cell array of pooled feature values (across selected concentrations) per group
%   If multiple outputs:
%       V1, V2, ... - Separate arrays of pooled values for each group
%
% Notes:
%   - Uses `masterPsychometricFunctionPlot` internally for data extraction and filtering.
%   - Each bar in the plot represents the average value across the selected concentrations.
%   - Group labels are automatically generated. For raw ID lists, they are named 'group 1', 'group 2', etc.
%   - Saves the figure as `.fig` in the 'Fig files' directory next to the script.
%
% Examples:
%   % Bar plot for two treatment groups
%   [V1, V2] = masterPsychometricBarPlot('timein_conc9', [], 'conc9_bar', 'trial', [4], [], ...
%                  'P2L1 Ghrelin', 'P2L1 Saline');
%
%   % Combine groups into one and compare
%   [V1, V2] = masterPsychometricBarPlot('timein_conc9', [], 'conc9_bar', 'session', 1:4, [], ...
%                  {'P2L1 Ghrelin', 'P2L1L3 Ghrelin'}, 'P2L1 Saline');
%
%   % Use raw trial IDs as input
%   [V1, V2] = masterPsychometricBarPlot('timein_conc9', [], 'conc9_bar', 'trial', [4], [], ...
%                  {idList1}, {idList2});
%
% Author: Atanu Giri
% Date: 05/14/2025
%
function varargout = masterPsychometricBarPlot(feature, animalList, ...
    figname, semMethod, concentrationSubset, distanceRange, varargin)

% Set defaults
if nargin < 2 || isempty(animalList), animalList = {}; end
if nargin < 3 || isempty(figname), figname = 'Psych_bar_plot'; end
figname = sprintf('%s_bar', figname);
if nargin < 4 || isempty(semMethod), semMethod = 'session'; end
if nargin < 5 || isempty(concentrationSubset), concentrationSubset = 1:4; end
if nargin < 6 || isempty(distanceRange), distanceRange = [-Inf, Inf]; end

% Call master function
featureForEach = masterPsychometricFunctionPlot( ...
    feature, animalList, figname, semMethod, distanceRange, varargin{:});

% Number of groups
numGroups = numel(featureForEach);

% Pre-allocate
avFeature = zeros(1, numGroups);
stdErr = zeros(1, numGroups);
pooledValues = cell(1, numGroups);

% Compute group means and SEMs
for i = 1:numGroups
    data_i = featureForEach{i};  % 1x4 cell
    values = [];
    for j = concentrationSubset
        if j <= numel(data_i)
            values = [values; data_i{j}(:)];
        end
    end
    flat = values(:);
    avFeature(i) = mean(flat);
    stdErr(i) = std(flat) / sqrt(numel(flat));
    pooledValues{i} = flat;
end

% Create labels (allow raw ID lists)
groupLabels = cell(1, numGroups);
for i = 1:numGroups
    group_i = varargin{i};
    if isnumeric(group_i)
        groupLabels{i} = sprintf('group %d', i);
    else
        if ischar(group_i) || isstring(group_i)
            group_i = {char(group_i)};
        end
        groupLabels{i} = strjoin(string(group_i), ' + ');
    end
end

% Plotting
x = 1:numGroups;
Colors = lines(numGroups);

figure; hold on;
for i = 1:numGroups
    bar(x(i), avFeature(i), 'FaceColor', Colors(i,:), ...
        'EdgeColor', 'k', 'DisplayName', groupLabels{i});
    errorbar(x(i), avFeature(i), stdErr(i), ...
        'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'HandleVisibility', 'off');
end

xticks(x);
xticklabels(groupLabels);
xlabel('Treatment Group', 'FontSize', 25);
ylabel(feature, 'Interpreter','none', 'FontSize', 25);
set(gca, 'FontSize', 15);
legend('show', 'Interpreter', 'none');

% Save figure
scriptDir = fileparts(mfilename('fullpath'));
figDir = fullfile(scriptDir, 'Fig files');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
savefig(gcf, fullfile(figDir, figname));

% Output
if nargout <= 1
    varargout{1} = pooledValues;
else
    varargout = pooledValues;
end
end