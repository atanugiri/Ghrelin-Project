% Author: Atanu Giri
% Date: 12/11/2023

function overlayPsychometricFunctions(varargin)
%
% This function plots overlaid psychometric plot for variable numbers of
% input plots.
%

% varargin = {'P2L1 Saline_distance_until_limiting_time_stamp_old.fig', ...
%     'P2L1 Ghrelin_distance_until_limiting_time_stamp_old.fig', ...
%     'Sal toyrat_distance_until_limiting_time_stamp_old.fig', ...
%     'Ghr toyrat_distance_until_limiting_time_stamp_old.fig', ...
%     'Sal toystick_distance_until_limiting_time_stamp_old', ...
%     'Ghr toystick_distance_until_limiting_time_stamp_old'};

% Create a new figure for the combined plot
figFinal = figure();
set(gcf, 'Windowstyle', 'docked');
ax = axes(figFinal);

% Define a set of unique colors
colors = lines(numel(varargin));

legendEntries = {}; % Initialize legend entries

for i = 1:numel(varargin)
    % Load the figure and get the handles of the axes and children
    fig = openfig(varargin{i});
    figAx = gca(fig);
    figAxChildren = get(figAx, 'Children');

    % Change the color of the line plots
    for j = 1:numel(figAxChildren)
        if strcmp(figAxChildren(j).Type, 'line')
            set(figAxChildren(j), 'Color', colors(i, :));
            legendEntries = [legendEntries, figAxChildren(j).DisplayName];

        elseif strcmp(figAxChildren(j).Type, 'errorbar')
            set(figAxChildren(j), 'Color', colors(i, :));
            legendEntries = [legendEntries, figAxChildren(j).DisplayName];
        end
    end

    % Copy the children (objects) from the axes to the combined axes
    copyobj(figAxChildren, ax);

    % Extract legend entries from the subplot
    legendEntries = [legendEntries, get(figAx, 'Legend').String];

    % Close the current figure
    close(fig);
end

% Add legend to the final overlaid plot
legend(ax, legendEntries);

% Retrieve x and y labels from one of the figures and apply to the overlaid plot
fig = openfig(varargin{1});
figAx = gca(fig);
xLabel = get(figAx.XLabel, 'String');
yLabel = get(figAx.YLabel, 'String');

xlabel(ax, xLabel);
ylabel(ax, yLabel, 'Interpreter','none');

% Close the temporary figure
close(fig);

myPath = "/Users/atanugiri/Downloads/Saline Ghrelin Project/Analysis/Fig files";
str = varargin{1};
startIndex = regexp(str, '_', 'once');
filename = str(startIndex:end);
% savefig(figFinal, fullfile(myPath, sprintf('overlaidPlot%s',filename)));
end