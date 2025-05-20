function curvature = computeTrajectoryCurvature(id, conn)
% Author: Atanu Giri
% Date: 05/19/2025
%
% computeTrajectoryCurvature - Computes mean curvature of a smoothed trajectory
% Input:
%   id   - trial ID
%   conn - database connection object (optional)
% Output:
%   curvature - mean curvature over PC range (smoothed)

    % Set up DB connection if not passed in
    if nargin < 2 || isempty(conn)
        datasource = 'live_database';
        conn = database(datasource, 'postgres', '1234');
    end

    curvature = NaN;  % Default output in case of error

    % Query
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
        pcFilter = data.t >= playTone & data.t <= 20;
        t = data.t(pcFilter);
        x = data.X(pcFilter);
        y = data.Y(pcFilter);

        % Smooth the coordinates
        x = smoothdata(x, 'movmean', 5);
        y = smoothdata(y, 'movmean', 5);

        % Compute derivatives
        dx = gradient(x);
        dy = gradient(y);
        ddx = gradient(dx);
        ddy = gradient(dy);

        % Curvature formula
        curvatureVals = abs(dx .* ddy - dy .* ddx) ./ (dx.^2 + dy.^2).^(3/2);
        curvatureVals(~isfinite(curvatureVals)) = 0;  % handle NaNs/Infs

        curvature = mean(curvatureVals);

    catch ME
        fprintf("Error computing curvature for id = %d: %s\n", id, ME.message);
    end
end