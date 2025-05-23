% Author: Atanu Giri
% Date: 12/07/2023

function [normT, normX, normY] = extractNormalizedCoordinate(id, varargin)

% Default output
normT = [];
normX = [];
normY = [];

% Open DB connection if not passed in
if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
else
    conn =  varargin{1};
end

query = sprintf("SELECT id, coordinatetimes2, xcoordinates2, ycoordinates2 FROM live_table WHERE id = %d", id);

try
    subject_data = fetch(conn, query);

    % Handle PostgreSQL arrays
    for column = size(subject_data,2) - 2:size(subject_data,2)
        strData = cellfun(@(x) string(x), subject_data.(column));
        regData = arrayfun(@(x) regexprep(x,'{|}',''), strData);
        splitData = arrayfun(@(x) split(x, ','), regData, 'UniformOutput', false);
        subject_data.(column) = cellfun(@(x) str2double(x), splitData, 'UniformOutput', false);
    end

    rawData = table(subject_data.coordinatetimes2{1}, subject_data.xcoordinates2{1}, ...
        subject_data.ycoordinates2{1}, 'VariableNames',{'t','X','Y'});

    % Remove invalid entries
    validIdx = all(isfinite(rawData{:,:}), 2);
    cleanedData = rawData(validIdx, :);

    if isempty(cleanedData)
        fprintf("No valid coordinate data for ID %d\n", id);
        return;
    end

    normT = cleanedData.t;

    % Coordinate normalization
    [normX, normY] = coordinateNormalization(cleanedData.X, cleanedData.Y, id, conn);

catch ME
    fprintf("An error occurred for ID %d: %s\n", id, ME.message);
    % normT, normX, normY remain empty
end

end