% Author: Atanu Giri
% Date: 05/27/2025
%
function writeToFeaturetableIsAcross(idList, conn)
% Updates ghrelin_featuretable with is_across for given idList

    % Ensure the column exists
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS is_across SMALLINT");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        out = isAcross(id, conn);

        if ~isnan(out)
            try
                updateSQL = sprintf(...
                    "UPDATE ghrelin_featuretable SET is_across = %d WHERE id = %d", ...
                    out, id);
                exec(conn, updateSQL);
                fprintf("ID %d: out = %.1f (updated)\n", id, out);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: out = NaN (skipped)\n", id);
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end