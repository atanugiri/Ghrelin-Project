function barPlotWithPoints(longTbl, groupVar1, groupVar2, yLabel, titleStr)
% barPlotWithPoints
% Creates a bar plot with individual data points overlaid
% Uses a for loop for bars to allow easy color customization in Adobe Illustrator
%
% Inputs:
%   longTbl   : table with Y, Group (and optionally Dreadds)
%   groupVar1 : first grouping variable (e.g., 'Dreadds' or 'Group')
%   groupVar2 : second grouping variable (e.g., 'Group'), can be empty for single factor
%   yLabel    : string for y-axis label (default: 'Value')
%   titleStr  : string for plot title (default: '')
%
% Examples:
%   % Single factor plot
%   barPlotWithPoints(longTbl, 'Group', '', 'Normalized Frequency', 'Simple Task')
%   
%   % Two factor plot (Dreadds x Group)
%   barPlotWithPoints(longTbl, 'Dreadds', 'Group', 'Normalized Frequency', 'Food Alone')

if nargin < 2, groupVar1 = 'Group'; end
if nargin < 3, groupVar2 = ''; end
if nargin < 4 || isempty(yLabel), yLabel = 'Value'; end
if nargin < 5 || isempty(titleStr), titleStr = ''; end

% Extract data
Y = longTbl.Y;
G1 = longTbl.(groupVar1);

% Check if two-factor plot
if ~isempty(groupVar2) && ismember(groupVar2, longTbl.Properties.VariableNames)
    % Two-factor plot
    G2 = longTbl.(groupVar2);
    
    % Get unique categories
    cats1 = categories(G1);
    cats2 = categories(G2);
    nCats1 = numel(cats1);
    nCats2 = numel(cats2);
    
    % Calculate means and SEMs for each combination
    means = zeros(nCats1, nCats2);
    sems = zeros(nCats1, nCats2);
    groupData = cell(nCats1, nCats2);
    
    for i = 1:nCats1
        for j = 1:nCats2
            idx = (G1 == cats1{i}) & (G2 == cats2{j});
            groupData{i,j} = Y(idx);
            means(i,j) = mean(groupData{i,j}, 'omitnan');
            sems(i,j) = std(groupData{i,j}, 'omitnan') / sqrt(sum(~isnan(groupData{i,j})));
        end
    end
else
    % Single factor plot
    cats1 = categories(G1);
    nCats1 = numel(cats1);
    nCats2 = 1;
    cats2 = {''};
    
    means = zeros(nCats1, 1);
    sems = zeros(nCats1, 1);
    groupData = cell(nCats1, 1);
    
    for i = 1:nCats1
        idx = G1 == cats1{i};
        groupData{i} = Y(idx);
        means(i) = mean(groupData{i}, 'omitnan');
        sems(i) = std(groupData{i}, 'omitnan') / sqrt(sum(~isnan(groupData{i})));
    end
end


% Create figure
figure('Position', [100, 100, 800, 600]);
hold on;

% Plot bars using for loop (easier to customize colors in Illustrator)
barWidth = 0.7;
barSpacing = 1.2;  % spacing between individual bars
groupSpacing = 2.5;  % extra spacing between groups

if nCats2 > 1
    % Two-factor plot: grouped bars
    barCounter = 1;
    xTickPos = [];
    xTickLabels = {};
    
    for i = 1:nCats1
        groupStart = barCounter;
        for j = 1:nCats2
            % Each bar drawn separately
            bar(barCounter, means(i,j), barWidth, 'FaceColor', [0.7 0.7 0.7], ...
                'EdgeColor', 'k', 'LineWidth', 1.5);
            barCounter = barCounter + barSpacing;
        end
        % Store center position for this group
        xTickPos(i) = groupStart + (nCats2-1)*barSpacing/2;
        xTickLabels{i} = cats1{i};
        barCounter = barCounter + groupSpacing - nCats2*barSpacing;  % add spacing between groups
    end
    
    % Add error bars
    barCounter = 1;
    for i = 1:nCats1
        for j = 1:nCats2
            errorbar(barCounter, means(i,j), sems(i,j), 'k', 'LineStyle', 'none', ...
                'LineWidth', 1.5, 'CapSize', 10);
            barCounter = barCounter + barSpacing;
        end
        barCounter = barCounter + groupSpacing - nCats2*barSpacing;
    end
    
    % Add individual data points
    barCounter = 1;
    for i = 1:nCats1
        for j = 1:nCats2
            data = groupData{i,j};
            if ~isempty(data)
                % Add jitter for visibility
                xPos = barCounter + (rand(size(data)) - 0.5) * 0.15;
                scatter(xPos, data, 50, 'k', 'filled', 'MarkerFaceAlpha', 0.4);
            end
            barCounter = barCounter + barSpacing;
        end
        barCounter = barCounter + groupSpacing - nCats2*barSpacing;
    end
    
    % Create legend for second factor
    legendHandles = [];
    for j = 1:nCats2
        h = bar(NaN, NaN, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k');
        legendHandles(j) = h;
    end
    legend(legendHandles, cats2, 'Location', 'best', 'FontSize', 10);
    
else
    % Single factor plot
    for i = 1:nCats1
        bar(i, means(i), barWidth, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % Add error bars
    errorbar(1:nCats1, means, sems, 'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 10);
    
    % Add individual data points
    for i = 1:nCats1
        data = groupData{i};
        if ~isempty(data)
            xPos = i + (rand(size(data)) - 0.5) * 0.2;
            scatter(xPos, data, 50, 'k', 'filled', 'MarkerFaceAlpha', 0.4);
        end
    end
    
    xTickPos = 1:nCats1;
    xTickLabels = cats1;
end


% Formatting
set(gca, 'XTick', xTickPos, 'XTickLabel', xTickLabels, 'FontSize', 12, 'LineWidth', 1.5);
ylabel(yLabel, 'FontSize', 14, 'FontWeight', 'bold');
xlabel(groupVar1, 'FontSize', 14, 'FontWeight', 'bold');
if ~isempty(titleStr)
    title(titleStr, 'FontSize', 16, 'FontWeight', 'bold');
end

% Set y-axis limits with some padding
yMin = min(Y);
yMax = max(Y);
yRange = yMax - yMin;
ylim([yMin - 0.1*yRange, yMax + 0.15*yRange]);

% Clean background - no grid
grid off;
box off;
set(gca, 'Color', 'none');  % transparent background

hold off;
end
