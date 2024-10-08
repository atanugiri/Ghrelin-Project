% Author: Atanu Giri
% Date: 12/01/2023
%
% This function takes 'feature', splitByGender, and treatment group as input from
% 'ghrelin_featuretable' and returns bar plot for that feature as
% an average of all animals
%
% Example usage
% masterFunForBarPlotOfFeature('distance_until_limiting_time_stamp', ...
% 'y', 'Alcohol bl', 'Alcohol')
%
%% Invokes treatmentIDfun, fetchHealthDataTable, barPlotValues, cleanBadSessionsFromTable.
%
function varargout = masterFunForBarPlotOfFeature(feature, splitByGender, varargin)

% feature = 'approachavoid';
% splitByGender = 'n';
% varargin = {'P2L1L3 Saline'};

close all;

% Connect to database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');

if numel(varargin) >= 1
    treatmentGroups = cell(1, numel(varargin));
    for i = 1:numel(varargin)
        treatmentGroups{i} = varargin{i};
    end
else
    treatmentGroups = input("Which health type do you want for treatment? ","s");
end

treatmentIDs = cell(1, numel(treatmentGroups));
for i = 1:numel(treatmentGroups)
    treatmentIDs{i} = treatmentIDfun(treatmentGroups{i}, conn);
end

% Generate the idList from the filtered data
treatmentIDs_str = cellfun(@(x) strjoin(arrayfun(@num2str, x, 'UniformOutput', ...
    false), ','), treatmentIDs, 'UniformOutput', false);
treatment_data = cell(1, numel(treatmentIDs_str));

for i = 1:numel(treatmentIDs_str)
    treatment_data{i} = fetchHealthDataTable(feature, treatmentIDs_str{i}, conn);
    treatment_data{i} = cleanBadSessionsFromTable(treatment_data{i}, feature); % Remove bad sessions
end

h = figure;
hold on;

%% Plot without splitting gender
if strcmpi(splitByGender, 'n')
    featureForEach = cell(1, numel(treatmentIDs));
    avFeature = zeros(1, numel(treatmentIDs));
    stdErr = zeros(1, numel(treatmentIDs));
    hBars = zeros(1, numel(treatmentIDs));

    for grp = 1:numel(treatmentIDs)
        [featureForEach{grp}, avFeature(grp), stdErr(grp)] = ...
            barPlotValues(treatment_data{grp}, feature);
        hBars(grp) = bar(grp, avFeature(grp));
        errorbar(grp, avFeature(grp),stdErr(grp),'LineStyle', 'none', ...
            'LineWidth', 1.5, 'CapSize', 0, 'Color','k');
    end

    legend_labels = treatmentGroups;
    legend(hBars, legend_labels, 'Location', 'best');
    ylabel(sprintf('%s', feature), 'Interpreter','none', 'FontSize', 25);

    %% Statistics
    if numel(varargin) >= 2
        p_value = zeros(1, numel(treatmentIDs) - 1);
        for grp = 2:numel(treatmentIDs)
            [~, p_value(grp-1)] = ttest2(featureForEach{1}, featureForEach{grp});
            text(grp, max(ylim), sprintf("p = %.4f", p_value(grp-1)));
        end
    end

    % Output for statistics
    varargout{1} = featureForEach;


    %% Plot with splitting gender
elseif strcmpi(splitByGender, 'y')
    featureForEachMale = cell(1, numel(treatmentIDs));
    avFeatureMale = zeros(1, numel(treatmentIDs));
    stdErrMale = zeros(1, numel(treatmentIDs));
    hBarsMale = zeros(1, numel(treatmentIDs));

    featureForEachFemale = cell(1, numel(treatmentIDs));
    avFeatureFemale = zeros(1, numel(treatmentIDs));
    stdErrFemale = zeros(1, numel(treatmentIDs));
    hBarsFemale = zeros(1, numel(treatmentIDs));

    subplot(1,2,1); % For male data
    hold on;
    subplot(1,2,2); % For female data
    hold on;

    for grp = 1:numel(treatmentIDs)
        maleData = treatment_data{grp}(strcmpi(treatment_data{grp}.gender,"male"),:);
        [featureForEachMale{grp}, avFeatureMale(grp), stdErrMale(grp)] = ...
            barPlotValues(maleData, feature);
        subplot(1,2,1);
        hBarsMale(grp) = bar(grp, avFeatureMale(grp));
        errorbar(grp, avFeatureMale(grp),stdErrMale(grp),'LineStyle', 'none', ...
            'LineWidth', 1.5, 'CapSize', 0, 'Color','k');
        title("Male", 'Interpreter','latex');
        ylabel(sprintf('%s', feature), 'Interpreter','none', 'FontSize', 25);

        femaleData = treatment_data{grp}(strcmpi(treatment_data{grp}.gender,"female"),:);
        [featureForEachFemale{grp}, avFeatureFemale(grp), stdErrFemale(grp)] = ...
            barPlotValues(femaleData, feature);
        subplot(1,2,2);
        hBarsFemale(grp) = bar(grp, avFeatureFemale(grp));
        errorbar(grp, avFeatureFemale(grp),stdErrFemale(grp),'LineStyle', 'none', ...
            'LineWidth', 1.5, 'CapSize', 0, 'Color','k');
        title("Female", 'Interpreter','latex');

    end

    % Add legends
    legend_labels = treatmentGroups;
    legend(hBarsFemale, legend_labels, 'Location', 'best');

    % Link axes to ensure the same scale
    linkaxes([subplot(1,2,1), subplot(1,2,2)], 'y');

    %% Statistics
    if numel(varargin) >= 2
        p_value_male = zeros(1, numel(treatmentIDs) - 1);
        for grp = 2:numel(treatmentIDs)
            [~, p_value_male(grp-1)] = ttest2(featureForEachMale{1}, featureForEachMale{grp});
            subplot(1,2,1);
            text(grp, max(ylim), sprintf("p = %.4f", p_value_male(grp-1)));
        end

        p_value_female = zeros(1, numel(treatmentIDs) - 1);
        for grp = 2:numel(treatmentIDs)
            [~, p_value_female(grp-1)] = ttest2(featureForEachFemale{1}, featureForEachFemale{grp});
            subplot(1,2,2);
            text(grp, max(ylim), sprintf("p = %.4f", p_value_female(grp-1)));
        end
    end

    % Output for statistics
    varargout{1} = featureForEachMale;
    varargout{2} = featureForEachFemale;
end

hold off;

% Save figure
if strcmpi(splitByGender, 'n')
    figname = sprintf('%s_%s_bar',[legend_labels{:}],string(feature));
else
    figname = sprintf('%s_%s_MvF_bar',[legend_labels{:}],string(feature));
end

% Figure name
scriptDir = fileparts(mfilename('fullpath'));
folderName = 'Fig files';
myPath = fullfile(scriptDir, folderName);
% Check if the folder exists, if not, create it
if ~exist(myPath, 'dir')
    mkdir(myPath);
end

savefig(gcf, fullfile(myPath, figname));

end
