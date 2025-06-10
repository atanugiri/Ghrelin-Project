function curvature = computeTrajectoryCurvature(id, conn, plotFlag)
% Author: Atanu Giri
% Date: 05/19/2025
%
% computeTrajectoryCurvature - Computes mean curvature of a smoothed trajectory
% Input:
%   id       - trial ID
%   conn     - database connection object (optional)
%   plotFlag - (optional) true to plot the smoothed trajectory and curvature
% Output:
%   curvature - mean curvature over PC range (smoothed)

    % Set up DB connection if not passed in
    if nargin < 2 || isempty(conn)
        conn = database('live_database', 'postgres', '1234');
    end
    if nargin < 3
        plotFlag = false;
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

        % Speed
        speed = sqrt(dx.^2 + dy.^2);

        % Curvature formula
        curvatureVals = abs(dx .* ddy - dy .* ddx) ./ (dx.^2 + dy.^2).^(3/2);

        % Invalidate curvature where speed is too low
        curvatureVals(speed < 1e-2) = NaN;

        % Remove non-finite values (e.g., NaNs from zero-speed filtering)
        curvatureVals(~isfinite(curvatureVals)) = [];

        % Final output: mean curvature
        if ~isempty(curvatureVals)
            curvature = mean(curvatureVals);
        else
            curvature = NaN;
        end

        % Optional plot
        if plotFlag
            figure;
            % Use curvature to color the trajectory line
            cmap = jet(256);
            normCurv = rescale(curvatureVals);  % Normalize curvature to [0, 1]
            colorIdx = round(normCurv * 255) + 1;

            hold on;
            for i = 1:length(x)-1
                c = cmap(colorIdx(i), :);
                plot(x(i:i+1), y(i:i+1), '-', 'Color', c, 'LineWidth', 2);
            end
            colormap(jet);
            cb = colorbar;
            cb.Label.String = 'Curvature';
            xlabel('X (normalized)');
            ylabel('Y (normalized)');
            title(sprintf('Trajectory Colored by Curvature (ID = %d)', id));
            axis equal;
        end

    catch ME
        fprintf("Error computing curvature for id = %d: %s\n", id, ME.message);
    end
end