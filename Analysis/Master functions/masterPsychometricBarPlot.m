% masterPsychometricBarPlot
%
% This function generates a bar plot showing the average of a psychometric
% feature across specified sucrose concentrations for each treatment group.
% It calls masterPsychometricFunctionPlot to fetch and organize the data,
% then aggregates across the selected concentrations to compute group-level
% mean and standard error.
%
% Inputs:
%   - feature:            Name of the feature column in the database (e.g., 'time_in_center_50')
%   - animalList:         (Optional) List of subject IDs to include. Use [] to include all animals.
%   - figname:            (Optional) Name for the saved figure (without extension)
%   - semMethod:          Method for calculating standard error ('session' or 'trial')
%   - concentrationSubset:(Optional) Indices of concentrations to include (e.g., [1 2] for 0.5% and 2%)
%   - varargin:           One or more treatment group(s), each as a string or cell array of strings
%
% Outputs:
%   - varargout:          Cell array(s) of raw feature values returned from masterPsychometricFunctionPlot
%
% Example usage:
%   [T1, T2] = masterPsychometricBarPlot('time_in_center_50', [], ...
%       'NCCB_bar', 'trial', [1 2 4], {'P2L1 Saline'}, {'P2L1 Ghrelin'});
%
% Notes:
%   - The function saves the figure as a .fig file in the 'Fig files' directory.
%   - The bar height represents the mean of all values pooled across the selected concentrations.
%   - Error bars represent the standard error of the mean (SEM).
%
% Dependencies:
%   - Requires masterPsychometricFunctionPlot.m to be in the same path.
%
% Author: Atanu Giri
% Date: 05/14/2025
%
function varargout = masterPsychometricBarPlot(feature, animalList, ...
    figname, semMethod, concentrationSubset, distanceThreshold, varargin)

% Set defaults
if nargin < 2 || isempty(animalList)
    animalList = {};
end
if nargin < 3 || isempty(figname)
    figname = 'Psych_bar_plot';
end
figname = sprintf('%s_bar', figname);

if nargin < 4 || isempty(semMethod)
    semMethod = 'session';
end
if nargin < 5 || isempty(concentrationSubset)
    concentrationSubset = 1:4;
end
if nargin < 6 || isempty(distanceThreshold)
    distanceThreshold = -Inf;
end

% Call master function and get all outputs
featureForEach = masterPsychometricFunctionPlot( ...
    feature, animalList, figname, semMethod, distanceThreshold, varargin{:});

% Now compute group averages and SEM across selected concentrations
numGroups = numel(featureForEach);
avFeature = zeros(1, numGroups);
stdErr = zeros(1, numGroups);

for i = 1:numGroups
    data_i = featureForEach{i};  % 1x4 cell
    values = [];
    for j = concentrationSubset
        if j <= numel(data_i)
            data_j = data_i{j};
            values = [values; data_j(:)];
        end
    end
    flat = values(:);
    avFeature(i) = mean(flat);
    stdErr(i) = std(flat) / sqrt(numel(flat));
end

% Plotting
x = 1:numGroups;
barWidth = 0.5;
Colors = lines(numGroups);

figure; hold on;
for i = 1:numGroups
    bar(x(i), avFeature(i), barWidth, ...
        'FaceColor', Colors(i,:), 'EdgeColor', 'k', ...
        'DisplayName', strjoin(string(varargin{i}), ' + '));
    errorbar(x(i), avFeature(i), stdErr(i), ...
        'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'HandleVisibility', 'off');
end

xticks(x);
xticklabels(cellfun(@(g) strjoin(string(g), ' + '), varargin, 'UniformOutput', false));
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

% Return pooled values per group (used for stats/bar height)
pooledValues = cell(1, numGroups);
for i = 1:numGroups
    data_i = featureForEach{i};
    values = [];
    for j = concentrationSubset
        if j <= numel(data_i)
            values = [values; data_i{j}(:)];
        end
    end
    pooledValues{i} = values;
end

% Assign output
if nargout <= 1
    varargout{1} = pooledValues;
else
    varargout = pooledValues;
end
end