function varargout = masterFunForBarPlotOfFeature(feature, animalList, figname, varargin)
% Author: Atanu Giri
% Date: 12/01/2023 (Updated: 2025-05-05)
%
% This function takes a feature, optional animal list, and treatment group(s)
% as input from 'ghrelin_featuretable' and returns a bar plot for that feature.
%
% Now supports grouped treatment conditions (e.g., {'A', 'B'}) to be plotted as a single bar.
%
% Example usage:
% masterFunForBarPlotOfFeature('distance_until_limiting_time_stamp', {}, ...
%     {'Alcohol bl'}, {'Alcohol', 'Post Alcohol'});

if nargin < 2 || isempty(animalList)
    animalList = {};
end

% If no figname provided, use default
if isempty(figname)
    figname = 'Bar plot';
end

% Add '_bar' suffix
figname = sprintf('%s_bar', figname);

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

% Filter by animalList if provided
if ~isempty(animalList)
    for i = 1:numel(treatment_data)
        treatment_data{i} = treatment_data{i}(ismember(treatment_data{i}.subjectid, animalList), :);
    end
end

% Extract features and compute mean/SEM
featureForEach = cell(1, numel(treatment_data));
avFeature = zeros(1, numel(treatment_data));
stdErr = zeros(1, numel(treatment_data));

figure;
Colors = parula(numel(treatmentGroups));

for grp = 1:numel(treatment_data)
    featureForEachSession = psychometricFunValues(treatment_data{grp}, feature);
    featureForEach{grp} = mean(featureForEachSession, 2);
    avFeature(grp) = mean(featureForEach{grp});
    stdErr(grp) = std(featureForEach{grp}) / sqrt(length(featureForEach{grp}));

    bar(grp, avFeature(grp), 'FaceColor', Colors(grp, :));
    hold on;
    errorbar(grp, avFeature(grp), stdErr(grp), 'LineStyle', 'none', ...
        'LineWidth', 1.5, 'Color', 'k');
end

hold off;
xticks(1:numel(treatmentGroups));
xticklabels(cellfun(@(x) strjoin(string(x), ' + '), treatmentGroups, 'UniformOutput', false));
ylabel(sprintf('%s', feature), 'Interpreter', 'none', 'FontSize', 25);

% Return values
if nargout <= 1
    varargout{1} = featureForEach;
else
    varargout = cell(1, numel(treatment_data));
    for i = 1:numel(treatment_data)
        varargout{i} = featureForEach{i};
    end
end

% t-tests if at least two groups are provided
if numel(treatmentGroups) >= 2
    p_value = zeros(1, numel(treatment_data) - 1);
    for grp = 2:numel(treatment_data)
        [~, p_value(grp - 1)] = ttest2(featureForEach{1}, featureForEach{grp});
        text(grp, max(ylim), sprintf("p = %.4f", p_value(grp - 1)));
    end
end

% Save figure
scriptDir = fileparts(mfilename('fullpath'));
figDir = fullfile(scriptDir, 'Fig files');
if ~exist(figDir, 'dir'); mkdir(figDir); end
savefig(gcf, fullfile(figDir, figname));
end
