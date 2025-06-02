function writeToFeaturetableLogicalApproach(idList, conn)
% Updates ghrelin_featuretable with logical_approach, time_in_feeder, and entry_time

    % Ensure columns exist
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS logical_approach SMALLINT");
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS time_in_feeder FLOAT");
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS entry_time FLOAT");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        [logicalApproach, timeInFeeder, entryTime] = logicalApproachFun(id, conn);
        logicalApproach = round(logicalApproach);  % ensure it's 0 or 1

        if ~isnan(logicalApproach) && ~isnan(timeInFeeder) && ~isnan(entryTime)
            try
                updateSQL = sprintf(...
                    "UPDATE ghrelin_featuretable SET logical_approach = %d, " + ...
                    "time_in_feeder = %f, entry_time = %f WHERE id = %d", ...
                    logicalApproach, timeInFeeder, entryTime, id);
                exec(conn, updateSQL);
                
                fprintf("ID %d: logical_approach = %d, time_in_feeder = %.2f, " + ...
                        "entry_time = %.2f (updated)\n", ...
                        id, logicalApproach, timeInFeeder, entryTime);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: logical_approach = %s, time_in_feeder = %s, entry_time = %s (skipped)\n", ...
                id, mat2str(logicalApproach), mat2str(timeInFeeder), mat2str(entryTime));
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end