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