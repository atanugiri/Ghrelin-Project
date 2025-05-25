% Author: Atanu Giri
% Date: 12/11/2023

parfor index = 1:length(idList)
    id = idList(index);
    try
        % Each worker must create its own connection
        connLocal = database('live_database','postgres','1234');

        [normT, normX, normY] = extractNormalizedCoordinate(id, connLocal);

        normT = normT(:); normX = normX(:); normY = normY(:);

        norm_t_string = sprintf('ARRAY[%s]', strjoin(cellstr(num2str(normT, '%.6f')), ','));
        norm_x_string = sprintf('ARRAY[%s]', strjoin(cellstr(num2str(normX, '%.6f')), ','));
        norm_y_string = sprintf('ARRAY[%s]', strjoin(cellstr(num2str(normY, '%.6f')), ','));

        updateQuery = sprintf("UPDATE ghrelin_featuretable SET norm_t=%s, norm_x=%s, norm_y=%s " + ...
            "WHERE id=%d", norm_t_string, norm_x_string, norm_y_string, id);

        exec(connLocal, updateQuery);
        close(connLocal);

        fprintf("Updated ID %d with %d points\n", id, numel(normT));

    catch ME
        fprintf("Calculation error in %d: %s\n", id, ME.message);
        continue;
    end
end