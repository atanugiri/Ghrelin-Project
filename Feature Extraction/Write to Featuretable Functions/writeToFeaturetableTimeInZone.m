% Author: Atanu Giri
% Date: 05/20/2025
%
function writeToFeaturetableTimeInZone(idList, conn)
% Updates ghrelin_featuretable with time spent in each feeder zone
% For all IDs in idList using extractTimeInZone()

    % Ensure required columns exist
    exec(conn, ...
        "ALTER TABLE ghrelin_featuretable " + ...
        "ADD COLUMN IF NOT EXISTS timein_conc9 FLOAT, " + ...
        "ADD COLUMN IF NOT EXISTS timein_conc5 FLOAT, " + ...
        "ADD COLUMN IF NOT EXISTS timein_conc2 FLOAT, " + ...
        "ADD COLUMN IF NOT EXISTS timein_conc0_5 FLOAT, " + ...
        "ADD COLUMN IF NOT EXISTS timein_all_conc FLOAT" ...
        );

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);

        try
            [t9, t5, t2, t0_5, t_all] = extractTimeInZone(id, conn);

            if any(isnan([t9, t5, t2, t0_5, t_all]))
                fprintf("ID %d: one or more NaN values — skipped\n", id);
                continue;
            end

            updateSQL = sprintf( ...
                "UPDATE ghrelin_featuretable SET " + ...
                "timein_conc9 = %f, timein_conc5 = %f, " + ...
                "timein_conc2 = %f, timein_conc0_5 = %f, " + ...
                "timein_all_conc = %f WHERE id = %d", ...
                t9, t5, t2, t0_5, t_all, id);

            exec(conn, updateSQL);
            fprintf("ID %d: time = [%.2f, %.2f, %.2f, %.2f, %.2f] (updated)\n", id, t9, t5, t2, t0_5, t_all);
            nUpdated = nUpdated + 1;

        catch e
            warning("ID %d: update failed — %s", id, e.message);
        end
    end

    fprintf("Successfully updated %d rows with time-in-zone data.\n", nUpdated);
end