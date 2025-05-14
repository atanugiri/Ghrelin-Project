% Author: Atanu Giri
% Date: 05/08/2025
%
function writeToFeaturetableEntropy(idList, conn)
% Updates ghrelin_featuretable with trajectory_entropy for given idList

    % Ensure the column exists
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS trajectory_entropy FLOAT");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        entropy = trajectoryEntropyFun(id, conn, [], 25);

        if ~isnan(entropy)
            try
                updateSQL = sprintf(...
                    "UPDATE ghrelin_featuretable SET trajectory_entropy = %f WHERE id = %d", ...
                    entropy, id);
                exec(conn, updateSQL);
                fprintf("ID %d: entropy = %.4f (updated)\n", id, entropy);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: entropy = NaN (skipped)\n", id);
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end