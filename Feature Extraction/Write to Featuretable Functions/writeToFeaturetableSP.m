% Author: Atanu Giri  
% Date: 06/01/2025  
%
function writeToFeaturetableSP(idList, conn)
% Updates ghrelin_featuretable with stop_time and num_stops for given idList

    % Ensure the columns exist (create if not)
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS stop_time FLOAT");
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS num_stops INTEGER");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        [stop_time, num_stops] = stoppingPtsFun(id, conn);
        num_stops = round(num_stops);  % Ensure integer

        if ~isnan(stop_time) && ~isnan(num_stops)
            try
                updateSQL = sprintf( ...
                    "UPDATE ghrelin_featuretable SET stop_time = %f, num_stops = %d WHERE id = %d", ...
                    stop_time, num_stops, id);
                exec(conn, updateSQL);
                fprintf("ID %d: stop_time = %.2f, num_stops = %d (updated)\n", id, stop_time, num_stops);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: stop_time or num_stops = NaN (skipped)\n", id);
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end
