% Author: Atanu Giri
% Date: 12/08/2023

function writeToFeaturetableDistanceVelocity(idList, conn)
% Updates ghrelin_featuretable with distance and velocity values

% Ensure the columns exist (if not already present)
exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS distance FLOAT");
exec(conn, "ALTER TABLE ghrelin_featuretable ADD COLUMN IF NOT EXISTS velocity FLOAT");

nUpdated = 0;
failedIDs = [];

for i = 1:length(idList)
    id = idList(i);

    try
        [dist, vel] = distanceVelocityFun(id, conn);

        distStr = 'NULL';
        if ~isempty(dist) && isfinite(dist)
            distStr = num2str(dist, '%.6f');
        end

        velStr = 'NULL';
        if ~isempty(vel) && isfinite(vel)
            velStr = num2str(vel, '%.6f');
        end

        updateSQL = sprintf( ...
            "UPDATE ghrelin_featuretable SET distance = %s, velocity = %s WHERE id = %d", ...
            distStr, velStr, id);

        exec(conn, updateSQL);
        fprintf("ID %d: dist = %s, vel = %s (updated)\n", id, distStr, velStr);
        nUpdated = nUpdated + 1;

    catch e
        fprintf("ID %d: Failed to update: %s\n", id, e.message);
        failedIDs(end+1) = id;
    end

    if mod(i, 100) == 0
        fprintf("... %d of %d processed\n", i, length(idList));
    end
end

fprintf("Successfully updated %d rows.\n", nUpdated);

if ~isempty(failedIDs)
    fprintf("%d IDs failed. See failed_distance_velocity_ids.csv\n", numel(failedIDs));
    writematrix(failedIDs, 'failed_distance_ids.csv');
end
end