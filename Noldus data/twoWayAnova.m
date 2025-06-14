% Author: Atanu Giri
% Date: 03/12/2025
%
% This function takes mutiple nx6 table of behavioral task and performs
% 1-way or 2-way ANOVA. User can specify if they want to perform analysis
% on whole dataset or a particular treatment group.
%
% Example usage
% [p, tbl, stats] = twoWayAnova(1, "FA + Controls.csv", "LA + Controls.csv", "TA + Controls.csv");
% [p, tbl, stats] = twoWayAnova(2, "FL + Controls.csv", "TL + Controls.csv",
% "EM (time in open - time in closed).csv");
%
function [p, tbl, stats] = twoWayAnova(normType, saveToExcel, fileName, varargin)

data = [];
g2 = []; % Simple vs Complex

% Get labels
g1_names = readtable(varargin{1}).Properties.VariableNames;

for i = 1:numel(varargin)
    tempData = readmatrix(varargin{i});

    tempData = normalizeData(tempData, normType);

    % Ask the user whether the dataset is 'simple' (1) or 'complex' (2)
    taskType = input(sprintf('Enter task type for dataset %d (1 = Simple, 2 = Complex): ', i));

    % Validate input
    while ~ismember(taskType, [1, 2])
        taskType = input('Invalid input. Enter 1 for Simple or 2 for Complex: ');
    end

    % Store task type for each row of the dataset
    g2 = [g2; repmat(taskType, size(tempData))];

    % Concatenate data
    data = [data; tempData];
end

% Create labels
g1 = repmat(g1_names,size(data, 1),1); % Health groups

% User input for analysis whole dataset or specific treatment group
comparison = input('Do you want to compare specific treatment groups? ("yes" or "no"): ');

if strcmpi(comparison, 'yes')
    % User input for specific treatment groups. Provide a number of list of
    % numbers. e.g. grp1idx = 1 or [1,3].
    T1idx = input('First treatment group index: ');
    T2idx = input('Second treatment group index: ');

    % Extract treatment data
    T1data = data(:,T1idx); T2data = data(:,T2idx);

    % Extract treatment label
    g1_label_T1 = g1(:,T1idx); g1_label_T2 = g1(:,T2idx);
    g2_label_T1 = g2(:,T1idx); g2_label_T2 = g2(:,T2idx);

    % Prepare data for ANOVA
    Y = [T1data(:); T2data(:)];
    g1label = [g1_label_T1(:); g1_label_T2(:)];
    g2label = [g2_label_T1(:); g2_label_T2(:)];

    g1 = categorical(g1label); g2 = categorical(g2label);

else
    Y = data(:); g1 = g1(:); g2 = g2(:);
    g1 = categorical(g1); g2 = categorical(g2);
end

% Remove nan indexes
idx = isfinite(Y);
Y = Y(idx); g1 = g1(idx); g2 = g2(idx);

% Save to Excel
if saveToExcel
    % Create table for Y, g1, g2
    dataTable = table(Y, g1, g2, 'VariableNames', {'Y', 'Treatment', 'Complexity'});
    writetable(dataTable, [fileName, '.xlsx']);
    disp('Data saved to Excel.');
end

if length(unique(g2)) > 1
    % Perform 2-way ANOVA
    [p, tbl, stats] = anovan(Y, {g1, g2}, 'model', 'interaction', 'varnames', {'treatment', 'complexity'});
else
    % Perform 1-way ANOVA
    [p, tbl, stats] = anovan(Y, {g1}, 'varnames', {'treatment'});
end

%% Description of normalizeData
function normData = normalizeData(tempData, normType)
    switch normType
        case 2  % Z-score
            refCol = tempData(:, 1);
            refMean = mean(refCol, 'omitnan');
            refStd = std(refCol, 'omitnan');
            normData = (tempData - refMean) ./ refStd;
        case 3  % Min-max
            refMin = min(tempData(:));
            refMax = max(tempData(:));
            normData = (tempData - refMin) ./ (refMax - refMin);
        otherwise
            normData = tempData;
    end
end

end