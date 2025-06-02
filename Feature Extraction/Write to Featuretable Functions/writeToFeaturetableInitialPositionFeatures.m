function writeToFeaturetableInitialPositionFeatures(idList, conn)
% Updates ghrelin_featuretable with is_across and initially_in_center for given idList

    % Ensure columns exist
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS is_across SMALLINT");
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS initially_in_center SMALLINT");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        [is_across, initially_in_center] = initialPositionFeatures(id, conn);

        if ~isnan(is_across) && ~isnan(initially_in_center)
            try
                updateSQL = sprintf(...
                    "UPDATE ghrelin_featuretable SET is_across = %d, " + ...
                    "initially_in_center = %d WHERE id = %d", ...
                    is_across, initially_in_center, id);
                exec(conn, updateSQL);
                fprintf("ID %d: is_across = %d, initially_in_center = %d (updated)\n", ...
                    id, is_across, initially_in_center);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: is_across = %s, initially_in_center = %s (skipped)\n", ...
                id, mat2str(is_across), mat2str(initially_in_center));
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end