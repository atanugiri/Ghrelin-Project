function [stopTime, numStops] = stoppingPtsFun(id, conn, time_filter, ...
    plotFlag, windowSize, xBoxWidth, yBoxWidth)
% Author: Atanu Giri
% Date: 06/01/2025
%
% stoppingPtsFun - Computes total stop time and number of stopping points
%
% Input:
%   id          - trial ID
%   conn        - (optional) database connection object
%   time_filter - (optional) 2-element vector [t_start, t_end], default = [2, 20]
%   plotFlag    - (optional) true to plot trajectory, default = false
%   windowSize  - (optional) number of points in moving window, default = 30
%   xBoxWidth   - (optional) spatial threshold for X range, default = 0.1
%   yBoxWidth   - (optional) spatial threshold for Y range, default = 0.1
%
% Output:
%   stopTime    - Total stop time in seconds
%   numStops    - Number of distinct stopping points (center of window)

% Handle default connection
if nargin < 2 || isempty(conn)
    conn = database('live_database', 'postgres', '1234');
end

% Default time window
if nargin < 3 || isempty(time_filter)
    t_start = 2;
    t_end = 20;
else
    t_start = time_filter(1);
    t_end = time_filter(2);
end

% Default plot flag
if nargin < 4 || isempty(plotFlag)
    plotFlag = false;
end

% Optional method params
if nargin < 5 || isempty(windowSize), windowSize = 30; end
if nargin < 6 || isempty(xBoxWidth), xBoxWidth = 0.1; end
if nargin < 7 || isempty(yBoxWidth), yBoxWidth = 0.1; end

% Initialize outputs
stopTime = NaN;
numStops = NaN;

% Fetch trajectory data
query = sprintf( ...
    "SELECT g.id, norm_t, norm_x, norm_y, l.mazenumber " + ...
    "FROM ghrelin_featuretable g " + ...
    "JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id = %d", id);

try
    subject_data = fetch(conn, query);

    maze = regexprep(string(subject_data.mazenumber), 'maze\s*(\d+)', '$1');
    maze = str2double(maze);

    % Parse norm_t, norm_x, norm_y into arrays
    for colName = ["norm_t", "norm_x", "norm_y"]
        rawStr = string(subject_data.(colName));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(colName){1} = str2double(splitStr);
    end

    % Build table and filter by time
    data = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
        subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    % Remove NaNs
    valid = ~isnan(data.t) & ~isnan(data.X) & ~isnan(data.Y);
    data = data(valid, :);

    % Filter to present cost (PC) range
    pcFilter = data.t >= t_start & data.t <= t_end;
    t = data.t(pcFilter);
    X = data.X(pcFilter);
    Y = data.Y(pcFilter);

    % Find stopping points by center of small windows
    n = numel(X);
    bulbIndexes = false(n, 1);
    for k = 1:n - windowSize
        xWindow = X(k:k + windowSize - 1);
        yWindow = Y(k:k + windowSize - 1);
        if range(xWindow) < xBoxWidth && range(yWindow) < yBoxWidth
            centerIdx = k + floor(windowSize / 2);
            bulbIndexes(centerIdx) = true;
        end
    end

    numStops = sum(bulbIndexes);
    dt = median(diff(t));
    stopTime = numStops * dt;

    % Optional plotting
    if plotFlag
        trajectoryPlot(id);
        hold on;
        scatter(X(bulbIndexes), Y(bulbIndexes), 15, 'r', 'filled');
        quadrants = [1, 2, 3, 4]; mazes = [2, 1, 3, 4];
        quadrant = quadrants(mazes == maze);
        mazeMethods(quadrant, [], [], [], false);
        hold off;
    end

catch e
    fprintf("An error occurred for ID = %d: %s\n", id, e.message);
end
end