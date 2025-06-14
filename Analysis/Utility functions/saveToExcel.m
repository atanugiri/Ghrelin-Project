% Author: Atanu Giri
% Date: 06/13/2025
%
function saveToExcel(fileName, varargin)
    % Check if there are at least two inputs (fileName and one array)
    if nargin < 2
        error('At least one data array must be provided.');
    end
    
    % Get the number of arrays provided
    numArrays = nargin - 1;
    
    % Check if the last input is a cell array (assumed to be VariableNames)
    if iscell(varargin{end})
        varNames = varargin{end}; % Variable names from the last input
        numArrays = numArrays - 1; % Adjust numArrays to exclude the VariableNames input
        varargin = varargin(1:end-1); % Remove the last input (VariableNames)
    else
        % If VariableNames are not provided, default names will be created
        varNames = arrayfun(@(i) sprintf('Var%d', i), 1:numArrays, 'UniformOutput', false);
    end
    
    % Check that all arrays have the same length, padding with NaN if necessary
    maxLength = max(cellfun(@(x) length(x), varargin));  % Find max length of arrays
    paddedArrays = cell(1, numArrays);
    
    for i = 1:numArrays
        currentArray = varargin{i};
        if length(currentArray) < maxLength
            % Pad with NaNs if the current array is shorter
            paddedArrays{i} = [currentArray; NaN(maxLength - length(currentArray), 1)];
        else
            paddedArrays{i} = currentArray;
        end
    end
    
    % Create the table from padded arrays
    dataTable = table(paddedArrays{:}, 'VariableNames', varNames);
    
    % Write the table to an Excel file
    writetable(dataTable, [fileName, '.xlsx']);
    
    disp(['Data saved to Excel file: ', fileName, '.xlsx']);
end
