function h = trajectoryPlot(id, varargin)
% Author: Atanu Giri
% Date: 11/19/2022 (Modified: 05/16/2025)
%
% trajectoryPlot(id, feederSize, zoneSize, highlightOffer, highlightCenter, figHandle, color)
%
% id              - trial id (required)
% feederSize      - size of the feeder zone (default = 0.25)
% zoneSize        - size of the central zone (default = 0.5)
% highlightOffer  - whether to highlight the offer zone (default = true)
% highlightCenter - whether to highlight the central zone (default = true)
% figHandle       - optional existing figure handle for overlay
% color           - optional RGB triplet or color name for trajectory

% Connect to database
datasource = 'live_database';
conn = database(datasource, 'postgres', '1234');

% Set defaults
feederSize = 0.25;
zoneSize = 0.5;
highlightOffer = true;
highlightCenter = true;
figHandle = [];
color = [];

% Handle varargin inputs
if ~isempty(varargin) && (ischar(varargin{end}) || isstring(varargin{end}) || (isnumeric(varargin{end}) && numel(varargin{end}) == 3))
    color = varargin{end};
    varargin(end) = [];
end

if ~isempty(varargin) && isgraphics(varargin{end})
    figHandle = varargin{end};
    varargin(end) = [];
end

if numel(varargin) >= 1, feederSize = varargin{1}; end
if numel(varargin) >= 2, zoneSize = varargin{2}; end
if numel(varargin) >= 3, highlightOffer = varargin{3}; end
if numel(varargin) >= 4, highlightCenter = varargin{4}; end

% Query trial data
query = sprintf("SELECT id, norm_t, norm_x, norm_y FROM ghrelin_featuretable WHERE id = %d", id);
subject_data = fetch(conn, query);

liveTableQuery = sprintf([
    "SELECT id, subjectid, trialname, referencetime, playstarttrialtone, " + ...
    "mazenumber, feeder, trialcontrolsettings FROM live_table WHERE id = %d"
], id);
liveTableData = fetch(conn, liveTableQuery);

subject_data = innerjoin(liveTableData, subject_data, 'Keys', 'id');

try
    % Process fields
    subject_data.playstarttrialtone = str2double(subject_data.playstarttrialtone);
    if isnan(subject_data.playstarttrialtone)
        subject_data.playstarttrialtone = 2;
    end
    subject_data.feeder = str2double(subject_data.feeder);
    subject_data.trialcontrolsettings = string(subject_data.trialcontrolsettings);

    % Determine real feeder from pattern
    patterns = ["Diagonal", "Grid", "Horizontal", "Radial"];
    feederIds = [1, 2, 3, 4];
    feeder = subject_data.feeder;
    for i = 1:numel(patterns)
        if contains(subject_data.trialcontrolsettings, patterns(i), 'IgnoreCase', true)
            feeder = feederIds(i);
            break;
        end
    end

    % Normalize maze label
    subject_data.mazenumber = char(lower(strrep(subject_data.mazenumber, ' ', '')));
    maze = {'maze2','maze1','maze3','maze4'};
    mazeIndex = find(ismember(maze, subject_data.mazenumber));

    % Convert PGArrays to double arrays
    for column = size(subject_data, 2) - 2 : size(subject_data, 2)
        rawStr = string(subject_data.(column));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(column){1} = str2double(splitStr);
    end

    % Extract coordinate table
    cleanedData = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
        subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    % Filter for after tone
    toneFilter = cleanedData.t >= subject_data.playstarttrialtone;
    xNormalized = cleanedData.X(toneFilter);
    yNormalized = cleanedData.Y(toneFilter);

    % Filter for present cost range (2–15 sec)
    pcFilter = cleanedData.t >= 2 & cleanedData.t <= 15;
    xPC = cleanedData.X(pcFilter);
    yPC = cleanedData.Y(pcFilter);

    % Create or reuse figure
    if isempty(figHandle)
        h = figure;
    else
        h = figHandle;
    end
    ax = gca;
    hold(ax, 'on');

    % Assign color if not provided
    if isempty(color)
        rng(id);  % consistent color per id
        color = rand(1, 3);
    end

    % Plot trajectory and label for legend
    p1 = plot(ax, xPC, yPC, '-', ...
        'Color', color, ...
        'LineWidth', 2, ...
        'DisplayName', sprintf('ID %d', id));

    % Plot start and end markers (not shown in legend)
    plot(ax, xPC(1), yPC(1), '.', 'Color', color, 'MarkerSize', 25, 'HandleVisibility', 'off');
    plot(ax, xPC(end), yPC(end), '.', 'Color', color, 'MarkerSize', 25, 'HandleVisibility', 'off');

    % Axis limits per maze
    figureLimit = {
        {[-0.2 1.2], [-0.2 1.2]},
        {[-1.2 0.2], [-0.2 1.2]},
        {[-1.2 0.2], [-1.2 0.2]},
        {[-0.2 1.2], [-1.2 0.2]}
    };
    xlim(ax, figureLimit{mazeIndex}{1});
    ylim(ax, figureLimit{mazeIndex}{2});

    % Only draw maze background and base legend on first call
    if isempty(figHandle)
        mazeMethods(mazeIndex, feederSize, zoneSize, feeder, highlightOffer, highlightCenter);

        xlabel(ax, 'x(Normalized)', 'Interpreter', 'latex', 'FontSize', 14);
        ylabel(ax, 'y(Normalized)', 'Interpreter', 'latex', 'FontSize', 14);
        sgtitle(sprintf('Trajectory Plot'), 'FontWeight', 'bold');
    end

    % Always update legend to reflect all added IDs
    legend(ax, 'show', 'Location', 'best', 'Interpreter', 'latex');

catch
    fprintf("An error occurred for id = %d\n", id);
    h = [];
end
end