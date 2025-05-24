function h = trajectoryScatterPlotRaw(id, figHandle, color)
% Author: Atanu Giri
% Date: 05/23/2025
%
% trajectoryScatterPlot(id, figHandle, color)
%
% id         - trial ID (required)
% figHandle  - optional figure handle to plot into (default = new figure)
% color      - optional RGB triplet or color name (default = black)

% Connect to database
datasource = 'live_database';
conn = database(datasource, 'postgres', '1234');

% Defaults
if nargin < 3 || isempty(color)
    color = 'k';  % black
end
if nargin < 2
    figHandle = [];
end

% Combined query from both tables
query = sprintf("SELECT id, xcoordinates2, ycoordinates2 FROM live_table " + ...
    "WHERE id = %d", id);
subject_data = fetch(conn, query);

try
    % Parse xcoordinates2, ycoordinates2 as numeric arrays
    for colName = ["xcoordinates2", "ycoordinates2"]
        rawStr = string(subject_data.(colName));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(colName){1} = str2double(splitStr);
    end

    % Create coordinate table
    data = table(subject_data.xcoordinates2{1}, ...
                 subject_data.ycoordinates2{1}, 'VariableNames', {'X', 'Y'});

    x = data.X;
    y = data.Y;

    % Create or reuse figure
    if isempty(figHandle)
        h = figure;
    else
        h = figHandle;
        figure(h);
    end
    ax = gca;

    hold(ax, 'on');

    % Plot present cost range as scatter
    scatter(ax, x, y, 30, 'MarkerFaceColor', color, ...
        'MarkerEdgeColor', 'k', 'DisplayName', sprintf('ID %d', id));

    % Label axes
    xlabel(ax, 'x (Normalized)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel(ax, 'y (Normalized)', 'Interpreter', 'latex', 'FontSize', 14);
    axis tight; axis equal;

    % Show legend
    legend(ax, 'show', 'Location', 'best', 'Interpreter', 'latex');

catch
    fprintf("An error occurred for id = %d\n", id);
    h = [];
end
end