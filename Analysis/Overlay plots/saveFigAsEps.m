% Author: Atanu Giri
% Date: 08/02/2024
%
% This function takes all .fig files in 'Fig files' folder and convert them
% into .eps files.
%

% Specify the directory containing the .fig files
scriptDir = fileparts(mfilename('fullpath'));
figDir = fullfile(scriptDir, 'Sigmoid fitting/Fig files');

% Get a list of all .fig files in the directory
figFiles = dir(fullfile(figDir, '*.fig'));

% Loop through each file, open it, and save as .eps
for k = 1:length(figFiles)
    % Open the .fig file
    figFile = fullfile(figDir, figFiles(k).name);
    openfig(figFile);
    
    % Construct the .eps file name
    [~, name, ~] = fileparts(figFiles(k).name);
    epsFile = fullfile(figDir, name);
    
    % Save the figure as an .eps file
    print(gcf, epsFile, '-depsc');
    
    % Close the figure
    close(gcf);
end
