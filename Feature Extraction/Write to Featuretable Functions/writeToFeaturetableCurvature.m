% Author: Atanu Giri
% Date: 05/19/2025
%
function writeToFeaturetableCurvature(idList, conn)
% Updates ghrelin_featuretable with curvature for given idList

    % Ensure the column exists
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS curvature FLOAT");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        curvature = computeTrajectoryCurvature(id, conn, 20);

        if ~isnan(curvature)
            try
                updateSQL = sprintf(...
                    "UPDATE ghrelin_featuretable SET curvature = %f WHERE id = %d", ...
                    curvature, id);
                exec(conn, updateSQL);
                fprintf("ID %d: curvature = %.4f (updated)\n", id, curvature);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: curvature = NaN (skipped)\n", id);
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end