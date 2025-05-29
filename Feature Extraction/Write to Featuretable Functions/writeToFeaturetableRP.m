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

for index = 1:length(idList)
    id = idList(index);
    try
        [rotationPts_method1, rotationPts_method2, rotationPts_method3, ...
            rotationPts_method4] = rotationPtFun(id, conn);
        % Convert NaN values to NULL
        rotationPts_method1 = handleNaN(rotationPts_method1);
        rotationPts_method2 = handleNaN(rotationPts_method2);
        rotationPts_method3 = handleNaN(rotationPts_method3);
        rotationPts_method4 = handleNaN(rotationPts_method4);

        % Handle empty values
        rotationPts_method1 = handleEmpty(rotationPts_method1);
        rotationPts_method2 = handleEmpty(rotationPts_method2);
        rotationPts_method3 = handleEmpty(rotationPts_method3);
        rotationPts_method4 = handleEmpty(rotationPts_method4);


        % Convert NaN values to 'NULL' for text columns
        rotationPts_method1 = convertToString(rotationPts_method1);
        rotationPts_method2 = convertToString(rotationPts_method2);
        rotationPts_method3 = convertToString(rotationPts_method3);
        rotationPts_method4 = convertToString(rotationPts_method4);


        updateQuery = sprintf("UPDATE %s SET rotationpts_per_unittravel_method1=%s, " + ...
            "rotationpts_per_unittravel_method2=%s, rotationpts_per_unittravel_method3=%s, " + ...
            "rotationpts_per_unittravel=%s WHERE id=%d", ...
            tableName, rotationPts_method1, rotationPts_method2, ...
            rotationPts_method3, rotationPts_method4, id);

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