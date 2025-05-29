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

for index = 1:length(idList)
    id = idList(index);
    try
        [accOutlierMoveMedian,jerkOutlierMoveMedian] = accelerationAndJerkOulierFun(id, conn);

        % Convert NaN values to NULL
        accOutlierMoveMedian = handleNaN(accOutlierMoveMedian);
        jerkOutlierMoveMedian = handleNaN(jerkOutlierMoveMedian);

        % Handle empty values
        accOutlierMoveMedian = handleEmpty(accOutlierMoveMedian);
        jerkOutlierMoveMedian = handleEmpty(jerkOutlierMoveMedian);

        % Convert NaN values to 'NULL' for text columns
        accOutlierMoveMedian = convertToString(accOutlierMoveMedian);
        jerkOutlierMoveMedian = convertToString(jerkOutlierMoveMedian);

        updateQuery = sprintf("UPDATE %s SET acc_outlier=%s, " + ...
            "jerk_outlier=%s WHERE id=%d", tableName, ...
            accOutlierMoveMedian, jerkOutlierMoveMedian, id);

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