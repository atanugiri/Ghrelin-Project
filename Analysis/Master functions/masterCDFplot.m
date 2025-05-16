% Author: Atanu Giri
% Date: 03/19/2024
%
% This function takes 'feature', splitByGender and treatment group/s as 
% input from and returns CDF plot for that feature as an average 
% of all animals
%
% Example usage
% masterCDFplot('distance_until_limiting_time_stamp','y','P2L1 Saline','P2L1 Ghrelin')

function masterCDFplot(feature, splitByGender, varargin)

% feature = 'distance_until_limiting_time_stamp';
% splitByGender = 'y';
% varargin = {'Alcohol bl','P2L1 Ghrelin','Alcohol','Ghr alcohol'};

% Connect to database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');

treatmentGroups = cell(1, numel(varargin));
for i = 1:numel(varargin)
    treatmentGroups{i} = varargin{i};
end

% Generate the idList from the filtered data
treatmentIDs = cell(1, numel(treatmentGroups));
for i = 1:numel(treatmentGroups)
    treatmentIDs{i} = treatmentIDfun(treatmentGroups{i}, conn);
end

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

figure;
hold on;
Colors = parula(numel(treatmentIDs));

%% Plot without splitting gender
if strcmpi(splitByGender, 'n')
    for grp = 1:length(treatment_data)
        l(grp) = cdfplot(treatment_data{grp}.(feature));
        set(l(grp),'Color', Colors(grp,:));
        set(l(grp), 'LineWidth', 2);
    end

    legend(l, treatmentGroups, 'Location', 'best');
    xlabel(sprintf('%s', feature), "Interpreter","none",'FontSize',25);
    ylabel("F(x)", "Interpreter","none",'FontSize',25);

    % Statistics
    p_value = zeros(1, length(treatment_data)-1);
    for grp = 1:length(p_value)
        [~, p_value(grp)] = kstest2(treatment_data{1}.(feature), ...
            treatment_data{grp+1}.(feature));
    end
    
    % Print statistics
    for grp = 1:length(p_value)
        text(min(xlim), max(ylim)*(1 - 0.1*grp), sprintf('p-value: %.4e', ...
            p_value(grp)), 'FontSize', 10, 'Color', 'r', 'HorizontalAlignment', 'center');
    end

elseif strcmpi(splitByGender, 'y')
    subplot(1,2,1); % For male data
    hold on;
    subplot(1,2,2); % For female data
    hold on;

    % Store data for statistics
    maleData = cell(1, numel(treatmentGroups));
    femaleData = cell(1, numel(treatmentGroups));

    for grp = 1:numel(treatmentIDs)
        maleData{grp} = treatment_data{grp}(strcmpi(treatment_data{grp}.gender,"male"),:);
        subplot(1,2,1);
        l_m(grp) = cdfplot(maleData{grp}.(feature));
        set(l_m(grp),'Color', Colors(grp,:));
        set(l_m(grp), 'LineWidth', 2);
        
        xlabel(sprintf('%s', feature), "Interpreter","none",'FontSize',25);
        ylabel("F(x)", "Interpreter","none",'FontSize',25);
        title("Male", 'Interpreter','latex', 'FontSize', 25);

        femaleData{grp} = treatment_data{grp}(strcmpi(treatment_data{grp}.gender,"female"),:);
        subplot(1,2,2);
        l_f(grp) = cdfplot(femaleData{grp}.(feature));
        set(l_f(grp),'Color', Colors(grp,:));
        set(l_f(grp), 'LineWidth', 2);
        xlabel(sprintf('%s', feature), "Interpreter","none",'FontSize',25);
        title("Female", 'Interpreter','latex','FontSize',25);
    end

    % Add legends
    legend(l_f, treatmentGroups, 'Location', 'best');

    % Statistics
    p_value_male = zeros(1, length(treatment_data)-1);
    p_value_female = zeros(1, length(treatment_data)-1);

    for grp = 1:length(p_value_male)
        [~, p_value_male(grp)] = kstest2(maleData{1}.(feature), maleData{grp+1}.(feature));
        [~, p_value_female(grp)] = kstest2(femaleData{1}.(feature), femaleData{grp+1}.(feature));
    end
    
    % Print statistics
    for grp = 1:length(p_value_male)
        subplot(1,2,1);
        text(min(xlim), max(ylim)*(1 - 0.1*grp), sprintf('p-value: %.4e', ...
            p_value_male(grp)), 'FontSize', 10, 'Color', 'r', 'HorizontalAlignment', 'center');

        subplot(1,2,2);
        text(min(xlim), max(ylim)*(1 - 0.1*grp), sprintf('p-value: %.4e', ...
            p_value_female(grp)), 'FontSize', 10, 'Color', 'r', 'HorizontalAlignment', 'center');
    end
end

hold off;

% Figure name
if strcmpi(splitByGender, 'n')
    figname = sprintf('%s_%s_CDF',[treatmentGroups{:}],string(feature));
else
    figname = sprintf('%s_%s_MvF_CDF',[treatmentGroups{:}],string(feature));
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