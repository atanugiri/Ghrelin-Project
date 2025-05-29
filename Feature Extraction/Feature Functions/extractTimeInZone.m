function [timeInConc9, timeInConc5, timeInConc2, timeInConc0_5, timeInCenter] = ...
    extractTimeInZone(id, conn, time_filter, plotFlag)
% Author: Atanu Giri
% Date: 05/20/2025
%
% extractTimeInZone - Computes time spent in each feeder zone.
%
% Input:
%   id          - trial ID
%   conn        - (optional) database connection object
%   time_filter - (optional) 2-element vector [t_start, t_end], defaults to [2, 20]
%   plotFlag    - (optional) true to plot trajectory, default = false
%
% Output:
%   timeInConc9, timeInConc5, timeInConc2, timeInConc0_5 - Time spent (in sec) in each feeder zone

% Set up DB connection if not passed in
if nargin < 2 || isempty(conn)
    conn = database('live_database', 'postgres', '1234');
end

% Set default time filter
if nargin < 3 || isempty(time_filter)
    t_start = 2;
    t_end = 20;
else
    t_start = time_filter(1);
    t_end = time_filter(2);
end

% Set default plot flag
if nargin < 4
    plotFlag = false;
end

% Query
query = sprintf( ...
    "SELECT g.id, norm_t, norm_x, norm_y, l.mazenumber " + ...
    "FROM ghrelin_featuretable g " + ...
    "JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id = %d" ...
    , id);

subject_data = fetch(conn, query);

try
    maze = regexprep(string(subject_data.mazenumber), 'maze\s*(\d+)', '$1');
    maze = str2double(maze);
    % Parse norm_t, norm_x, norm_y as arrays
    for colName = ["norm_t", "norm_x", "norm_y"]
        rawStr = string(subject_data.(colName));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(colName){1} = str2double(splitStr);
    end

    % Build table
    data = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
        subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    % Present Cost window: playTone to 20s
    pcFilter = data.t >= t_start & data.t <= t_end;
    t = data.t(pcFilter);
    x = data.X(pcFilter);
    y = data.Y(pcFilter);

    % Use helper to compute time in zones
    quadrants = [1, 2, 3, 4]; mazes = [2, 1, 3, 4];
    quadrant = quadrants(mazes == maze);
    edgeStruct = getMazeEdgeRegions(quadrant);
    zoneNames = {'Feeder1', 'Feeder2', 'Feeder3', 'Feeder4', 'Center'};
    timeInZone = zeros(1, 5);

    for zone = 1:5
        [xEdge, yEdge] = edgeStruct.(zoneNames{zone}){:};
        filter = x >= xEdge(1) & x <= xEdge(2) & y >= yEdge(1) & y <= yEdge(2);
        timeInZone(zone) = sum(filter)*0.1;
    end

    timeInConc9 = timeInZone(1); timeInConc5 = timeInZone(2); timeInConc2 = timeInZone(3);
    timeInConc0_5 = timeInZone(4); timeInCenter = timeInZone(5);

    % Optional plot
    if plotFlag
        figure;
        plot(x, y, '.', 'Color', 'k'); hold on;
        mazeMethods(quadrant);
        hold off;
        axis tight; axis equal;
        title(sprintf('Trajectory for ID %d (Maze %d)', id, quadrant));
    end

catch ME
    fprintf("Error in extractTimeInZone for ID %d: %s\n", id, ME.message);
    [timeInConc9, timeInConc5, timeInConc2, timeInConc0_5, timeInCenter] = deal(NaN);
end

end