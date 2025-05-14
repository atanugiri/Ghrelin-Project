% Author: Atanu Giri
% Date: 05/08/2025
%
function entropyValue = trajectoryEntropyFun(id, conn, plotFlag, nBins)
% Calculates Shannon entropy of trajectory (norm_x, norm_y) after tone
% 
% Inputs:
%   id        – (int) Session ID
%   conn      – (optional) DB connection object
%   plotFlag  – (optional) true/false, default false
%   nBins     – (optional) number of bins for histcounts2, default 10
%
% Output:
%   entropyValue – Shannon entropy of spatial occupancy

    % Set defaults if not provided
    if nargin < 2 || isempty(conn)
        conn = database('live_database', 'postgres', '1234');
    end
    if nargin < 3 || isempty(plotFlag)
        plotFlag = false;
    end
    if nargin < 4 || isempty(nBins)
        nBins = 10;
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
        % Convert PGArrays to double arrays
        for varName = ["norm_t", "norm_x", "norm_y"]
            s = string(subject_data.(varName));
            s = regexprep(s, '[{}]', '');
            subject_data.(varName){1} = str2double(split(s, ','));
        end

        t = subject_data.norm_t{1};
        X = subject_data.norm_x{1};
        Y = subject_data.norm_y{1};
        toneTime = str2double(subject_data.playstarttrialtone);

        % Keep time after tone
        valid = t >= toneTime & ~isnan(X) & ~isnan(Y);
        X = X(valid);
        Y = Y(valid);

        % Compute spatial bin histogram
        counts = histcounts2(X, Y, [nBins, nBins]);
        p = counts(:) / sum(counts(:));
        p(p == 0) = [];

        % Calculate Shannon entropy
        entropyValue = -sum(p .* log2(p));

        % Optional heatmap
        if plotFlag
            figure;
            imagesc(counts');
            axis xy;
            colorbar;
            title(sprintf('2D Occupancy Heatmap (ID %d)', id));
            xlabel('X bins'); ylabel('Y bins');
        end

    catch ME
        warning("Error for ID %d: %s", id, ME.message);
        entropyValue = NaN;
    end
end