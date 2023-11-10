% clear; clc;
datasource = 'live_database';
conn = database(datasource,'postgres','1234');
dateQuery = "SELECT id, referencetime FROM live_table ORDER BY id";
allDates = fetch(conn, dateQuery);
allDates.referencetime = datetime(allDates.referencetime, 'Format', 'MM/dd/yyyy');
startDate = datetime('09/12/2023', 'InputFormat', 'MM/dd/yyyy');
endDate = datetime('10/31/2023', 'InputFormat', 'MM/dd/yyyy');
endDate = endDate + days(1);

dataInRange = allDates(allDates.referencetime >= startDate & allDates.referencetime <= endDate, :);
idList = dataInRange.id;

tableName = 'ghrelin_featuretable';

%% Add new columns example
% alterQuery = "ALTER TABLE ghrelin_featuretable " + ...
%     "ADD COLUMN entry_time text, " + ...
%     "ADD COLUMN exit_time text, " + ...
%     "ADD COLUMN logical_approach text, " + ...
%     "ADD COLUMN logical_approach_2s text";
% exec(conn, alterQuery);

for index = 1:length(idList)
    id = idList(index);
    try
        [entryTime, exitTime, logicalApproach, logicalApproach2s] = entryExitTimeStamp(id);

        % Convert NaN values to 'NULL' for text columns
        entryTime = num2str(entryTime);
        exitTime = num2str(exitTime);
        logicalApproach = num2str(logicalApproach);
        logicalApproach2s = num2str(logicalApproach2s);

        entryTime = strrep(entryTime, 'NaN', 'NULL');
        exitTime = strrep(exitTime, 'NaN', 'NULL');

        updateQuery = sprintf("UPDATE %s SET entry_time=%s, exit_time=%s, " + ...
            "logical_approach=%s, logical_approach_2s=%s WHERE id=%d", tableName, ...
            entryTimeValue, exitTimeValue, logicalApproach, logicalApproach2s, id);

        exec(conn, updateQuery);

    catch
        fprintf("Calculation error in %d\n", id);
        continue;
    end
end
