% Author: Atanu Giri
% Date: 11/01/2023 

%
% This script inject unique ids in the ghrelin_featuretable
%

conn = database('live_database','postgres','1234');

for i = 1:length(idList)
    try
        id = idList(i);
        query = sprintf( ...
            "INSERT INTO ghrelin_featuretable (id) VALUES (%d) ON CONFLICT (id) DO NOTHING", ...
            id);
        exec(conn, query);
        fprintf("Inserted (or skipped existing) ID: %d\n", id);
    catch exception
        fprintf("Error inserting ID %d: %s\n", id, exception.message);
    end
end

close(conn);