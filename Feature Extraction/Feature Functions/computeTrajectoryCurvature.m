function [curvature, distance] = computeTrajectoryCurvature(id, conn, time_limit, smooth, window, speed_thresh)
% Author: Atanu Giri
% Date: 05/19/2025
%
% computeTrajectoryCurvature - Computes mean curvature of a smoothed trajectory
%
% Input:
%   id           - trial ID
%   conn         - database connection object
%   time_limit   - (optional) cap the trajectory at this time in seconds
%   smooth       - (optional) true to smooth trajectory
%   window       - (optional) smoothing window size in samples
%   speed_thresh - (optional) threshold to invalidate curvature at low speeds
%
% Output:
%   curvature - mean curvature over the specified range

    % Default parameter values if not provided
    frame_rate = 10; % As specified for RECORD task
    if nargin < 3, time_limit = inf; end
    if nargin < 4, smooth = true; end
    if nargin < 5, window = 5; end
    if nargin < 6, speed_thresh = 1e-2; end

    curvature = NaN;

    % Database query
    query = sprintf( ...
        "SELECT id, norm_t, norm_x, norm_y, distance " + ...
        "FROM ghrelin_featuretable " + ...
        "WHERE id = %d", ...
        id);

    try
        subject_data = fetch(conn, query);

        if isempty(subject_data)
            warning('No data found for ID: %d', id);
            return;
        end
        
        % Parse norm_x, norm_y, norm_t from string arrays
        norm_t_str = regexprep(string(subject_data.norm_t), '[{}]', '');
        norm_x_str = regexprep(string(subject_data.norm_x), '[{}]', '');
        norm_y_str = regexprep(string(subject_data.norm_y), '[{}]', '');
        
        t = str2double(split(norm_t_str, ','));
        x = str2double(split(norm_x_str, ','));
        y = str2double(split(norm_y_str, ','));

        filter = t>= 2;
        t = t(filter); x = x(filter); y = y(filter);

        % Apply time_limit
        if isfinite(time_limit)
            t_filt = t <= time_limit;
            x = x(t_filt);
            y = y(t_filt);
            
            % n_keep = min(length(x), max(0, floor(time_limit * frame_rate)));
            % % t = t(1:n_keep);
            % x = x(1:n_keep);
            % y = y(1:n_keep);
        end
        
        if length(x) < 5
            warning('Not enough data points for ID %d after time_limit.', id);
            return;
        end

        % Optional smoothing
        if smooth && window > 1
            w = max(3, floor(window));
            if mod(w, 2) == 0
                w = w + 1;
            end
            x = smoothdata(x, 'movmean', w);
            y = smoothdata(y, 'movmean', w);
        end

        % Compute derivatives
        dt = 1.0 / frame_rate;
        dx = gradient(x, dt);
        dy = gradient(y, dt);
        ddx = gradient(dx, dt);
        ddy = gradient(dy, dt);

        % Speed
        speed = hypot(dx, dy);

        % Curvature formula
        numerator = abs(dx .* ddy - dy .* ddx);
        denominator = (dx.^2 + dy.^2).^(3/2);

        curvatureVals = numerator ./ denominator;

        % Set curvature to NaN where speed is too low
        curvatureVals(speed < speed_thresh) = 0;

        % Handle cases where denominator is zero
        curvatureVals(denominator == 0) = NaN;
        
        % Final output: mean curvature
        valid_curv = curvatureVals(isfinite(curvatureVals));
        if ~isempty(valid_curv)
            curvature = mean(valid_curv);
        else
            curvature = NaN;
        end

        distance = subject_data.distance;

    catch ME
        fprintf("Error computing curvature for id = %d: %s\n", id, ME.message);
        curvature = NaN;
    end
end