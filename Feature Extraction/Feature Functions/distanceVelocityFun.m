function [distanceUntilLimitingTimeStamp,velocityUntilLimitingTimeStamp] = distanceVelocityFun(id, varargin)

% id = 265302;
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

    distanceUntilLimitingTimeStamp = 0;
    for i = 1:length(X)-1
        distanceUntilLimitingTimeStamp = distanceUntilLimitingTimeStamp + ...
            sqrt((X(i+1)-X(i))^2 + (Y(i+1)-Y(i))^2);
    end

    velocityUntilLimitingTimeStamp = distanceUntilLimitingTimeStamp/ ...
        (t(end) - t(1));

catch
    sprintf("An error occured for id = %d\n", id);
end
end