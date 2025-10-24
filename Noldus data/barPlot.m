% Author: Atanu Giri
% Date: 03/27/2025
%
% Bar plot without and with normalization
%
function barPlot(normType, colsToPlot, titleStr, varargin)

if ~ismember(normType, [1, 2, 3])
    error('normType must be 1 (none), 2 (z-score), or 3 (min-max)');
end

% Get labels
labels = readtable(varargin{1}).Properties.VariableNames;

data = []; % Placeholder in case of multiple files

for i = 1:numel(varargin)
    tempData = readmatrix(varargin{i});
    tempData = normalizeData(tempData, normType);

    % Concatenate data
    data = [data; tempData];
end

% Filter data and labels for desired groups to plot
if ~isempty(colsToPlot)
    data = data(:,colsToPlot);
    labels = labels(colsToPlot);
end

counts = sum(~isnan(data), 1);         % Number of non-NaN entries per column
means = mean(data, 1, "omitmissing");              % Mean ignoring NaNs
sems = std(data, 0, 1, "omitmissing") ./ sqrt(counts);  % SEM per column

% Check label length vs. number of bars
if length(labels) ~= length(means)
    warning('Number of labels does not match number of columns in data.');
end

% Plot
figure;
hold on;

for i = 1:length(means)
    % Draw each bar separately
    bar(i, means(i), 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k'); 
end

% Add error bars
errorbar(1:length(means), means, sems, 'k.', 'LineWidth', 1.5);

% Overlay individual data points with jitter
for col = 1:size(data, 2)
    colData = data(:, col);
    colData = colData(~isnan(colData));  % Remove NaNs
    jitterX = col + 0.1 * (rand(size(colData)) - 0.5);  % Add horizontal jitter
    scatter(jitterX, colData, 20, 'k', 'filled');
end

xticks(1:length(means));
xticklabels(strrep(labels, '_', ' '));
ylabel('Mean Value');
subTitleStr = {"Not normalized", "Z-score normalized", "Min-max normalized"};
title(sprintf('%s (%s)', titleStr, subTitleStr{normType}), 'Interpreter', 'none');
hold off;

% Set ylim (optional)
% switch normType
%     case 1
%         ylim([0, 120]);
%     case 2
%         ylim([-2, 1.5]);
%     case 3
%         ylim([0, 0.8]);
% end

% Save figure
savefig(gcf, sprintf('%s (%s).fig', titleStr, subTitleStr{normType}));

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

% Write normalized data to Excel
outputFile = sprintf('%s.xlsx', titleStr);
dataTable = array2table(data, 'VariableNames', matlab.lang.makeValidName(labels));
writetable(dataTable, outputFile, 'Sheet', 'NormalizedData');

end