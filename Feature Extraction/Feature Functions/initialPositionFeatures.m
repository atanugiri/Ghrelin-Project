function [is_across, initially_in_center] = initialPositionFeatures(id, conn, plotFlag)
% isAcross: Determine if animal started in across-feeder zone during trial tone.
%
%   Output:
%     - is_across            : 1 if the initial position is in the across-feeder zone, 0 otherwise.
%     - initially_in_center  : 1 if the animal's initial position is in the center zone, 0 otherwise.
%
%   out = isAcross(id, conn) uses the specified database connection instead
%   of opening a new one.
%
%   [is_across, initially_in_center] = isAcross(id, conn, plotFlag) additionally 
%   plots the trajectory and maze layout if plotFlag is true. 
%   By default, plotFlag is false.
%
%   Input Arguments:
%     - id        : Trial ID to analyze.
%     - conn      : (Optional) Live database connection object.
%     - plotFlag  : (Optional, default = false) Whether to plot trajectory
%                   and shaded feeder zones.
%
%   Notes:
%     - Maze quadrant is determined based on the mazenumber using a fixed
%       mapping: [2, 1, 3, 4].
%     - The across feeder is computed from feeder IDs: 1⟷3, 2⟷4.
%     - Visualization uses trajectoryPlot and mazeMethods.
%
%   Author: Atanu Giri
%   Date  : 05/27/2025

is_across = 0;
initially_in_center = 0;

% Optional inputs
if nargin < 2 || isempty(conn)
    conn = database('live_database', 'postgres', '1234');
end
if nargin < 3 || isempty(plotFlag)
    plotFlag = false;
end

% Fetch trial data
query = sprintf( ...
    "SELECT g.id, g.norm_t, g.norm_x, g.norm_y, l.playstarttrialtone, " + ...
    "l.mazenumber, l.feeder, l.trialcontrolsettings FROM ghrelin_featuretable g " + ...
    "JOIN live_table l ON g.id = l.id WHERE g.id = %d", id);

try
    subject_data = fetch(conn, query);

    % Parse timing
    playTone = str2double(subject_data.playstarttrialtone);
    if isnan(playTone), playTone = 2; end

    % Parse norm_x, norm_y, norm_t
    for colName = ["norm_t", "norm_x", "norm_y"]
        rawStr = string(subject_data.(colName));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(colName){1} = str2double(splitStr);
    end

    data = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
        subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    pcFilter = data.t >= playTone & data.t <= 20;
    X = data.X(pcFilter);
    Y = data.Y(pcFilter);
    if isempty(X), return; end  % skip if no valid points

    % Determine quadrant
    maze = str2double(regexp(string(subject_data.mazenumber), '\d+', 'match', 'once'));
    mazeToQuadrantMap = [2, 1, 3, 4];
    quadrant = mazeToQuadrantMap(maze);

    % Determine feeder
    patterns = ["Diagonal", "Grid", "Horizontal", "Radial"];
    feederIds = [1, 2, 3, 4];
    trial_setting = string(subject_data.trialcontrolsettings);
    idx = find(arrayfun(@(p) contains(trial_setting, p, 'IgnoreCase', true), patterns), 1);
    if ~isempty(idx)
        feeder = feederIds(idx);
    else
        feeder = str2double(subject_data.feeder);
    end

    % Across-feeder edge
    acrossMap = [3, 4, 1, 2]; % This convention is same for all mazes
    acrossFeeder = acrossMap(feeder);
    edgeStruct = getMazeEdgeRegions(quadrant);
    fieldName = sprintf('Feeder%d', acrossFeeder);
    acrossFeederEdge = edgeStruct.(fieldName);
    x_edge = acrossFeederEdge{1}; y_edge = acrossFeederEdge{2};

    % Initial position in across-feeder zone?
    if X(1) >= x_edge(1) && X(1) <= x_edge(2) && ...
            Y(1) >= y_edge(1) && Y(1) <= y_edge(2)
        is_across = 1;
    end
    
    % Initial position in center?
    [x_edge_center, y_edge_center] = edgeStruct.Center{:};
    if X(1) >= x_edge_center(1) && X(1) <= x_edge_center(2) && ...
            Y(1) >= y_edge_center(1) && Y(1) <= y_edge_center(2)
        initially_in_center = 1;
    end

    % Optional plotting
    if plotFlag
        trajectoryPlot(id);
        mazeMethods(quadrant, feeder, [], true, false);
    end

catch ME
    warning("Error in isAcross (ID %d): %s", id, ME.message);
end
end