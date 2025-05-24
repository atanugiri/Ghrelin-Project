% Author: Atanu Giri
% Date: 05/23/2025
% distanceVelocityFun - Computes total distance and average velocity within a time window
% 
% Syntax:
%   [distance, velocity] = distanceVelocityFun(id)
%   [distance, velocity] = distanceVelocityFun(id, conn)
%
% Inputs:
%   id   - Trial ID to extract trajectory data
%   conn - (Optional) Database connection object
%
% Outputs:
%   distance - Total trajectory distance from tone to 20s
%   velocity - Average velocity in the same interval

function [distanceUntilLimitingTimeStamp,velocityUntilLimitingTimeStamp] = distanceVelocityFun(id, varargin)

if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
else
    conn =  varargin{1};
end

% Fetch data with JOIN
query = sprintf( ...
    "SELECT g.id, g.norm_t, g.norm_x, g.norm_y, l.playstarttrialtone " + ...
    "FROM ghrelin_featuretable g " + ...
    "JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id = %d", ...
    id);

subject_data = fetch(conn, query);

try
    toneTime = str2double(subject_data.playstarttrialtone);
    if isnan(toneTime)
        toneTime = 2;
    end

    % Convert PGArrays to double arrays
    for varName = ["norm_t", "norm_x", "norm_y"]
        s = string(subject_data.(varName));
        s = regexprep(s, '[{}]', '');
        subject_data.(varName){1} = str2double(split(s, ','));
    end

    t = subject_data.norm_t{1};
    X = subject_data.norm_x{1};
    Y = subject_data.norm_y{1};

    valid = t >= toneTime & t <= 20;
    X = X(valid);
    Y = Y(valid);
    t = t(valid);

    % Edge case checks
    if numel(t) < 2
        distanceUntilLimitingTimeStamp = NaN;
        velocityUntilLimitingTimeStamp = NaN;
        warning("ID %d has insufficient time points after tone", id);
        return;
    end

    % Vectorized distance calculation
    dx = diff(X);
    dy = diff(Y);
    distanceUntilLimitingTimeStamp = sum(hypot(dx, dy));
    velocityUntilLimitingTimeStamp = distanceUntilLimitingTimeStamp/ ...
        (t(end) - t(1));

catch ME
    warning("Error processing ID %d: %s", id, ME.message);
    distanceUntilLimitingTimeStamp = NaN;
    velocityUntilLimitingTimeStamp = NaN;
end
end