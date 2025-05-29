% clear; clc;
datasource = 'live_database';
conn = database(datasource,'postgres','1234');
dateQuery = "SELECT id, referencetime FROM live_table ORDER BY id";
allDates = fetch(conn, dateQuery);
allDates.referencetime = datetime(allDates.referencetime, 'Format', 'MM/dd/yyyy');
startDate = datetime('09/12/2023', 'InputFormat', 'MM/dd/yyyy');
endDate = datetime('12/11/2023', 'InputFormat', 'MM/dd/yyyy');
endDate = endDate + days(1);

dataInRange = allDates(allDates.referencetime >= startDate & allDates.referencetime <= endDate, :);
idList = dataInRange.id;

tableName = 'ghrelin_featuretable';

% idList = strjoin(arrayfun(@num2str, idList, 'UniformOutput', false), ',');
% ftq = sprintf("SELECT * FROM ghrelin_featuretable WHERE id IN (%s) ORDER BY id;", idList);

%% Add new columns example
% alterQuery = "ALTER TABLE ghrelin_featuretable " + ...
%     "ADD COLUMN entry_time text, " + ...
%     "ADD COLUMN logical_approach text, " + ...
%     "ADD COLUMN logical_approach_2s text";
% exec(conn, alterQuery);

for index = 1:length(idList)
    id = idList(index);
    try
        [logicalApproach, timeInFeeder, entryTime] = logicalApproachFun(id, conn);

        % Convert NaN values to NULL
        logicalApproach = handleNaN(logicalApproach);
        timeInFeeder = handleNaN(timeInFeeder);
        entryTime = handleNaN(entryTime);

        % Handle empty values
        logicalApproach = handleEmpty(logicalApproach);
        timeInFeeder = handleEmpty(timeInFeeder);
        entryTime = handleEmpty(entryTime);

        % Convert NaN values to 'NULL' for text columns
        logicalApproach = convertToString(logicalApproach);
        timeInFeeder = convertToString(timeInFeeder);
        entryTime = convertToString(entryTime);

        updateQuery = sprintf("UPDATE %s SET logical_approach=%s, " + ...
            "time_in_feeder=%s, entry_time=%s WHERE id=%d", tableName, ...
            logicalApproach, timeInFeeder, entryTime, id);

        exec(conn, updateQuery);

    catch ME
        fprintf("Calculation error in %d: %s\n", id, ME.message);
        continue;
    end
end

function value = handleNaN(value)
    if isnan(value)
        value = 'NULL';
    end
end

function value = handleEmpty(value)
    if isempty(value)
        value = 'NULL';
    end
end

function value = convertToString(value)
    % Convert to numeric if not NaN or empty
    if all(~isnan(value)) && all(~isempty(value))
        value = num2str(value); % Convert to string for uniformity
    end
end