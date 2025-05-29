% Author: Atanu Giri
% Date: 12/25/2023

function [stoppingPts_method1, stoppingPts_method2, stoppingPts_method3, stoppingPts_method4, ...
    stoppingPts_method5, stoppingPts_method6] = stoppingPtsFun(id, varargin)
% This function returns the total stoptime in trajectory using 6 methods.
% Optional: Provide a database connection and/or enable plotting (plotFlag = true) for method 6.

% Default settings
plotFlag = false;
conn = [];

% Check optional inputs
for i = 1:numel(varargin)
    if islogical(varargin{i})
        plotFlag = varargin{i};
    elseif isobject(varargin{i}) && isa(varargin{i}, 'database')
        conn = varargin{i};
    end
end

% Make connection if not provided
if isempty(conn)
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
end

% Combined query from both tables
query = sprintf( ...
    "SELECT g.id, g.distance, norm_t, norm_x, norm_y, " + ...
    "l.playstarttrialtone FROM ghrelin_featuretable g " + ...
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

    limitingTimeIndex = 20;

    % Create coordinate table
    data = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
        subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    % Present cost (PC) range: playTone–20 sec
    pcFilter = data.t >= playTone & data.t <= limitingTimeIndex;
    t = data.t(pcFilter);
    X = data.X(pcFilter);
    Y = data.Y(pcFilter);

    % Define methods
    windowSize = [5,5,10,10,20,30];
    xBoxWidth = [0.01,0.02,0.01,0.02,0.1,0.1];
    yBoxWidth = [0.01,0.02,0.01,0.02,0.1,0.1];
    stoppingPts = zeros(1, numel(windowSize));
    bulbIndexes = cell(1, numel(windowSize));

    % Scan array for stopping points
    for method = 1:numel(windowSize)
        bulbIndexes{method} = false(numel(X), 1);
        for k = 2:numel(X) - windowSize(method)
            xWindow = X(k:k + windowSize(method) - 1);
            yWindow = Y(k:k + windowSize(method) - 1);
            if range(xWindow) < xBoxWidth(method) && range(yWindow) < yBoxWidth(method)
                bulbIndexes{method}(k:k + windowSize(method) - 1) = true;
            end
        end
        stoppingPts(method) = sum(bulbIndexes{method}) / subject_data.distance;

        % Optional plot for method 6
        if plotFlag && method == 6
            scatter(X(bulbIndexes{method}), Y(bulbIndexes{method}), 15, 'r', 'filled');
        end
    end

    stoppingPts_method1 = stoppingPts(1);
    stoppingPts_method2 = stoppingPts(2);
    stoppingPts_method3 = stoppingPts(3);
    stoppingPts_method4 = stoppingPts(4);
    stoppingPts_method5 = stoppingPts(5);
    stoppingPts_method6 = stoppingPts(6);
catch
    fprintf("An error occurred for ID = %d\n", id);
    stoppingPts_method1 = NaN;
    stoppingPts_method2 = NaN;
    stoppingPts_method3 = NaN;
    stoppingPts_method4 = NaN;
    stoppingPts_method5 = NaN;
    stoppingPts_method6 = NaN;
end
end