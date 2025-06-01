% Author: Atanu Giri  
% Date: 06/01/2025  
%
function writeToFeaturetableAccJerk(idList, conn)
% Updates ghrelin_featuretable with acc_outlier and jerk_outlier for given idList

    % Ensure the columns exist (create if not)
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS acc_outlier FLOAT");
    exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS jerk_outlier FLOAT");

    nUpdated = 0;

    for i = 1:length(idList)
        id = idList(i);
        [accOutlier, jerkOutlier] = accelerationAndJerkOulierFun(id, conn, false);

        if ~isnan(accOutlier) && ~isnan(jerkOutlier)
            try
                updateSQL = sprintf( ...
                    "UPDATE ghrelin_featuretable SET acc_outlier = %f, jerk_outlier = %f WHERE id = %d", ...
                    accOutlier, jerkOutlier, id);
                exec(conn, updateSQL);
                fprintf("ID %d: acc = %.2f, jerk = %.2f (updated)\n", id, accOutlier, jerkOutlier);
                nUpdated = nUpdated + 1;
            catch e
                warning("Failed to update ID %d: %s", id, e.message);
            end
        else
            fprintf("ID %d: acc or jerk = NaN (skipped)\n", id);
        end
    end

    fprintf("Successfully updated %d rows.\n", nUpdated);
end
