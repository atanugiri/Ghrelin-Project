% clear; clc;
datasource = 'live_database';
conn = database(datasource,'postgres','1234');
dateQuery = "SELECT id, referencetime FROM live_table ORDER BY id";
allDates = fetch(conn, dateQuery);
allDates.referencetime = datetime(allDates.referencetime, 'Format', 'MM/dd/yyyy');
startDate = datetime('09/12/2023', 'InputFormat', 'MM/dd/yyyy');
endDate = datetime('09/30/2023', 'InputFormat', 'MM/dd/yyyy');
endDate = endDate + days(1);

dataInRange = allDates(allDates.referencetime >= startDate & allDates.referencetime <= endDate, :);
idList = dataInRange.id;

tableName = 'ghrelin_featuretable';

for index = 1:length(idList)
    id = idList(index);
    try
        [stoppingPts_method1, stoppingPts_method2, stoppingPts_method3, stoppingPts_method4, ...
            stoppingPts_method5, stoppingPts_method6] = stoppingPtsFun(id, conn);

        % Convert NaN values to NULL
        stoppingPts_method1 = handleNaN(stoppingPts_method1);
        stoppingPts_method2 = handleNaN(stoppingPts_method2);
        stoppingPts_method3 = handleNaN(stoppingPts_method3);
        stoppingPts_method4 = handleNaN(stoppingPts_method4);
        stoppingPts_method5 = handleNaN(stoppingPts_method5);
        stoppingPts_method6 = handleNaN(stoppingPts_method6);


        % Handle empty values
        stoppingPts_method1 = handleEmpty(stoppingPts_method1);
        stoppingPts_method2 = handleEmpty(stoppingPts_method2);
        stoppingPts_method3 = handleEmpty(stoppingPts_method3);
        stoppingPts_method4 = handleEmpty(stoppingPts_method4);
        stoppingPts_method5 = handleEmpty(stoppingPts_method5);
        stoppingPts_method6 = handleEmpty(stoppingPts_method6);


        % Convert NaN values to 'NULL' for text columns
        stoppingPts_method1 = convertToString(stoppingPts_method1);
        stoppingPts_method2 = convertToString(stoppingPts_method2);
        stoppingPts_method3 = convertToString(stoppingPts_method3);
        stoppingPts_method4 = convertToString(stoppingPts_method4);
        stoppingPts_method5 = convertToString(stoppingPts_method5);
        stoppingPts_method6 = convertToString(stoppingPts_method6);


        updateQuery = sprintf("UPDATE %s SET stoppingpts_per_unittravel_method1=%s, " + ...
            "stoppingpts_per_unittravel_method2=%s, stoppingpts_per_unittravel_method3=%s, " + ...
            "stoppingpts_per_unittravel_method4=%s, stoppingpts_per_unittravel_method5=%s, " + ...
            "stoppingpts_per_unittravel=%s WHERE id=%d", ...
            tableName, stoppingPts_method1, stoppingPts_method2, stoppingPts_method3, ...
            stoppingPts_method4, stoppingPts_method5, stoppingPts_method6, id);

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