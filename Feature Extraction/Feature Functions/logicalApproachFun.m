function [logicalApproach, timeInFeeder, entryTime] = logicalApproachFun(id, conn, plotFlag)
% logicalApproachFun: Evaluate whether the subject approached the feeder zone during the PC period.
%
%   [logicalApproach, timeInFeeder, entryTime] = logicalApproachFun(id, conn, plotFlag)
%
%   This function analyzes a subject's trajectory in a given trial to determine:
%     - Whether the subject entered the feeder zone during the present cost (PC) window
%     - How long the subject stayed within the feeder zone
%     - The time elapsed between PC onset and the subject's first entry
%
%   Inputs:
%     - id        : Trial ID
%     - conn      : (Optional) Database connection object (default connects to 'live_database')
%     - plotFlag  : (Optional) Logical flag to show trajectory and maze layout (default = false)
%
%   Outputs:
%     - logicalApproach : 1 if feeder was entered during PC period, 0 otherwise
%     - timeInFeeder    : Total time (in seconds) spent inside the feeder zone (based on 10Hz sampling)
%     - entryTime       : Time from PC onset to first feeder entry (0 if already inside; [] if never entered)
%
%   Notes:
%     - Maze orientation is inferred from the mazenumber via quadrant mapping.
%     - Feeder identity is inferred from trial control settings or feeder column.
%     - Uses normalized spatial coordinates (0–1 or extended if rotated).
%
%   Example:
%     [a, t, et] = logicalApproachFun(24501, [], true);
%
%   Author: Atanu Giri
%   Date  : 05/29/2025

% Optional inputs
if nargin < 3 || isempty(plotFlag)
    plotFlag = false;
end
if nargin < 2 || isempty(conn)
    conn = database('live_database', 'postgres', '1234');
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
    T = data.t(pcFilter);
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

    edgeStruct = getMazeEdgeRegions(quadrant);
    fieldName = sprintf('Feeder%d', feeder);
    [x_edge, y_edge] = edgeStruct.(fieldName){:};

    % logicalApproach
    filter = X >= x_edge(1) & X <= x_edge(2) & ...
        Y >= y_edge(1) & Y <= y_edge(2);
    if any(filter)
        logicalApproach = 1;
    else
        logicalApproach = 0;
    end

    % timeInFeeder
    timeInFeeder = sum(filter)*0.1;

    % Entrytime
    if logicalApproach == 0
        entryTime = [];  % never entered feeder zone
    else
        % Check if the first position is already in the feeder zone
        if X(1) >= x_edge(1) && X(1) <= x_edge(2) && ...
                Y(1) >= y_edge(1) && Y(1) <= y_edge(2)
            entryTime = 0;
        else
            % Otherwise find the first time it enters
            entryTime = NaN;  % fallback in case the logic fails
            for i = 1:length(X)
                if X(i) >= x_edge(1) && X(i) <= x_edge(2) && ...
                        Y(i) >= y_edge(1) && Y(i) <= y_edge(2)
                    entryTime = T(i) - T(1);
                    break;
                end
            end
        end
    end

    % Optional plotting
    if plotFlag
        trajectoryPlot(id);
        mazeMethods(quadrant, feeder, [], true, false);
    end

catch ME
    warning("Error in isAcross (ID %d): %s", id, ME.message);
end