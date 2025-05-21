function h = trajectoryPlot(id, figHandle, color)
% Author: Atanu Giri
% Date: 05/19/2025 (Modified)
%
% trajectoryPlot(id, figHandle, color)
%
% id         - trial ID (required)
% figHandle  - optional figure handle to plot into (default = new figure)
% color      - optional RGB triplet or color name (default = unique per ID)

% Connect to database
datasource = 'live_database';
conn = database(datasource, 'postgres', '1234');

% Defaults
if nargin < 3
    color = [];
end
if nargin < 2
    figHandle = [];
end

% Combined query from both tables
query = sprintf( ...
    "SELECT g.id, norm_t, norm_x, norm_y, l.playstarttrialtone " + ...
    "FROM ghrelin_featuretable g " + ...
    "JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id = %d", ...
    id);
subject_data = fetch(conn, query);

try
    % Parse playstarttrialtone
    playTone = str2double(subject_data.playstarttrialtone);
    if isnan(playTone)
        playTone = 2;
    end

    % Parse norm_t, norm_x, norm_y as numeric arrays
    for colName = ["norm_t", "norm_x", "norm_y"]
        rawStr = string(subject_data.(colName));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(colName){1} = str2double(splitStr);
    end

    % Create coordinate table
    data = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
                 subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    % Full data (optional)
    X = data.X;
    Y = data.Y;

    % Present cost (PC) range: 2–15 sec
    pcFilter = data.t >= playTone & data.t <= 20;
    x = data.X(pcFilter);
    y = data.Y(pcFilter);

    % Create or reuse figure
    if isempty(figHandle)
        h = figure;
    else
        h = figHandle;
        figure(h);  % bring to front
    end
    ax = gca;

    % Assign color if not provided
    if isempty(color)
        rng(id);  % consistent color per id
        color = rand(1, 3);
    end

    hold(ax, 'on');

    % Plot present cost range (2–15 s)
    plot(ax, x, y, '-', ...
        'Color', color, ...
        'LineWidth', 2, ...
        'DisplayName', sprintf('ID %d', id));

    % Optional: uncomment to plot the full trajectory
    % plot(ax, X, Y, '-', ...
    %     'Color', color, ...
    %     'LineWidth', 1);

    % Plot start (green) and end (red) markers for present cost range
    plot(ax, x(1), y(1), 'o', 'MarkerSize', 8, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'g', 'HandleVisibility', 'off');
    plot(ax, x(end), y(end), 'o', 'MarkerSize', 8, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
    axis(ax, 'tight');
    axis(ax, 'equal');

    % Label axes
    xlabel(ax, 'x (Normalized)', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel(ax, 'y (Normalized)', 'Interpreter', 'latex', 'FontSize', 14);

    % Show legend (if using DisplayName in any plot)
    legend(ax, 'show', 'Location', 'best', 'Interpreter', 'latex');

catch
    fprintf("An error occurred for id = %d\n", id);
    h = [];
end
end