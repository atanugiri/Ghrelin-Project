% Author: Atanu Giri
% Date: 07/08/2024
%
% This function takes 'feature', splitByGender('y' or 'n') and treatment
% group/s as input from and returns box plot for that feature as
% an average of all sessions
%
% Example usage
% masterBoxPlot('approachavoid','y','P2L1 Saline','P2L1 Ghrelin')
%
%% Invokes treatmentIDfun, fetchHealthDataTable, psychometricFunValues,
%% cleanBadSessionsFromTable.
%
function varargout = masterFunForBoxPlot(feature, splitByGender, varargin)

% feature = 'approachavoid';
% splitByGender = 'y';
% varargin = {'P2L1 BL for comb boost and alc', 'P2A Boost and alcohol'};

% Connect to database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');

treatmentGroups = varargin;
treatmentIDs = cell(1, numel(treatmentGroups));

for i = 1:numel(treatmentGroups)
    treatmentIDs{i} = treatmentIDfun(treatmentGroups{i}, conn);
end

% Generate the idList from the filtered data
treatmentIDs_str = cellfun(@(x) strjoin(arrayfun(@num2str, x, 'UniformOutput', ...
    false), ','), treatmentIDs, 'UniformOutput', false);
treatment_data = cell(1, numel(treatmentIDs_str));

% L1 and L3 task in L1L3 will naturally have 20 trials
trtGroupsToExclude = {'P2L1L3 BL for comb boost and alc L1', ...
    'P2L1L3 BL for comb boost and alc L3','P2L1L3 Boost and alcohol L1', ...
    'P2L1L3 Boost and alcohol L3', 'P2L1L3 Post alcohol L1', ...
    'P2L1L3 Post alcohol L3'};

for i = 1:numel(treatmentIDs_str)
    treatment_data{i} = fetchHealthDataTable(feature, treatmentIDs_str{i}, conn);
    if ~ismember(treatmentGroups{i}, trtGroupsToExclude)
        treatment_data{i} = cleanBadSessionsFromTable(treatment_data{i}, feature); % Remove bad sessions
    end
end

% Plotting
x = 1:4;
figure;
hold on;
Colors = lines(numel(treatment_data));

% Desired spacing
d = 0.4;

% Initialize a matrix to hold the positions
positions = zeros(numel(treatment_data), length(x));

% Loop through each treatment group
for t = 1:numel(treatment_data)
    % Calculate positions for each concentration for this treatment group
    positions(t, :) = x + ((2*t - (numel(treatment_data) + 1)) ...
        / (numel(treatment_data) + 1)) * d;
end

% Array to store handles for the legend
legendHandles = gobjects(numel(treatment_data), 1);

%% Plot without splitting gender
if strcmpi(splitByGender, 'n')
    featureForEach = cell(1, numel(treatment_data));

    for grp = 1:numel(treatment_data)
        featureForEach{grp} = psychometricFunValues(treatment_data{grp}, feature);

        % Create box plot for each concentration
        for conc = 1:4
            data = featureForEach{grp}(:, conc);
            h = boxplot(data, 'Positions', positions(grp,conc), 'Colors', Colors(grp,:), ...
                'Widths', 0.15, 'Symbol', '');

            % Scatter individual data points
%             scatter(positions(grp, conc) * ones(size(data)), data, 25, Colors(grp,:), ...
%                 'filled', 'jitter', 'on', 'jitterAmount', 0.05);

            % Store the handle for the legend (only one handle per group)
            if conc == 1
                legendHandles(grp) = h(1); % Save the handle of the first box plot in each group
            end
        end

    end

    legend_labels = treatmentGroups;
    legend(legendHandles, legend_labels, 'Location', 'best');
    ylabel(sprintf('%s', feature), 'Interpreter','none', 'FontSize', 25);
    xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);

    xticks(x);
    label = {'0.5','2','5','9'};
    set(gca,'xticklabel',label,'FontSize',15);

    % Output for statistics
    varargout{1} = featureForEach;

    %% Plot with splitting gender
elseif strcmpi(splitByGender, 'y')
    featureForEachMale = cell(1, numel(treatment_data));
    featureForEachFemale = cell(1, numel(treatment_data));

    for grp = 1:numel(treatment_data)
        maleData = treatment_data{grp}(strcmpi(treatment_data{grp}.gender,"male"),:);
        featureForEachMale{grp} = psychometricFunValues(maleData, feature);
        subplot(1,2,1);
        hold on;

        % Create box plot for each concentration
        for conc = 1:4
            data = featureForEachMale{grp}(:, conc);
            boxplot(data, 'Positions', positions(grp,conc), 'Colors', Colors(grp,:), ...
                'Widths', 0.15, 'Symbol', '');

            % Scatter individual data points
%             scatter(positions(grp, conc) * ones(size(data)), data, 25, Colors(grp,:), ...
%                 'filled', 'jitter', 'on', 'jitterAmount', 0.05);
        end

        if grp == 1
            title("Male", 'Interpreter','latex', 'FontSize', 25);
            ylabel(sprintf('%s', feature), 'Interpreter','none');
            xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);
        end

        femaleData = treatment_data{grp}(strcmpi(treatment_data{grp}.gender,"female"),:);
        featureForEachFemale{grp} = psychometricFunValues(femaleData, feature);
        subplot(1,2,2);
        hold on;

        % Create box plot for each concentration
        for conc = 1:4
            data = featureForEachFemale{grp}(:, conc);
            h = boxplot(data, 'Positions', positions(grp,conc), 'Colors', Colors(grp,:), ...
                'Widths', 0.15, 'Symbol', '');
            % Scatter individual data points
%             scatter(positions(grp, conc) * ones(size(data)), data, 50, Colors(grp,:), ...
%                 'filled', 'jitter', 'on', 'jitterAmount', 0.05);

            % Store the handle for the legend (only one handle per group)
            if conc == 1
                legendHandles(grp) = h(1); % Save the handle of the first box plot in each group
            end
        end

        if grp == 1
            title("Female", 'Interpreter','latex','FontSize',25);
            xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);
        end

    end

    for i = 1:2
        subplot(1,2,i);
        xticks(1:4);
        label = {'0.5','2','5','9'};
        set(gca,'xticklabel',label,'FontSize',15);
    end

    % Add legends
    legend_labels = treatmentGroups;
    legend(legendHandles, legend_labels, 'Location', 'best');

    % Link axes to ensure the same scale
    linkaxes([subplot(1,2,1), subplot(1,2,2)], 'y');

    % Output for statistics
    varargout{1} = featureForEachMale;
    varargout{2} = featureForEachFemale;

end

hold off;

% Figure name
if strcmpi(splitByGender, 'n')
    figname = sprintf('%s_%s_boxplot',[legend_labels{:}],string(feature));
else
    figname = sprintf('%s_%s_MvF_boxplot',[legend_labels{:}],string(feature));
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

end