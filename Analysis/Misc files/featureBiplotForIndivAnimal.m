% Author: Atanu Giri
% Date: 07/16/2024
%
% This function generates biplots of all combinations of fitting paramaeter
% for each animal and compares between different treatment groups.
%
function featureBiplotForIndivAnimal(featureList, animals, ...
    treatmentGroups, fitParams)

numFeatures = numel(featureList);
animalColors = hsv(numel(animals));

% Define different shapes for the treatment groups
shapes = {'o', 's', 'pentagram', '+', 'v', '<', '>', 'p', 'h'};

% Ensure we have enough shapes for the number of treatment groups
if numel(shapes) < numel(treatmentGroups)
    error('Not enough marker shapes defined for the number of treatment groups');
end

% Define where to save
scriptDir = fileparts(mfilename('fullpath'));
folderName = 'Fig files';
myPath = fullfile(scriptDir, folderName);
% Check if the folder exists, if not, create it
if ~exist(myPath, 'dir')
    mkdir(myPath);
end

% Define file name
fileName = 'clusters2D';
pdf_file = fullfile(myPath, sprintf("%s.pdf", fileName));

% Loop through feature combinations and plot
for i = 1:numFeatures
    for j = i+1:numFeatures
        xFeature = featureList{i};
        yFeature = featureList{j};

        figure;

        for grp = 1:numel(treatmentGroups)

            xData = fitParams{grp}.(xFeature);
            yData = fitParams{grp}.(yFeature);

            for animalIdx = 1:numel(animals)
                scatter(xData(animalIdx), yData(animalIdx), 50, 'filled', ...
                    'MarkerFaceColor', animalColors(animalIdx, :), ...
                    'Marker', shapes{grp}, ...
                    'DisplayName', animals{animalIdx});
                hold on;

            end
        end

        hold off;

        % Create a legend for the animals
        legend(animals, 'Location', 'best', 'Interpreter', 'none');

        % Save the figure to a PDF file with a separate page for each figure
        xlabel(xFeature);
        ylabel(yFeature);
        title(sprintf('%s vs %s', xFeature, yFeature));

        if i == 1 && j == 2
            exportgraphics(gcf, pdf_file, 'ContentType', 'vector');
        else
            exportgraphics(gcf, pdf_file, 'ContentType', 'vector', 'Append', true);
        end

        close(gcf);
    end
end

% % Treatment group legends
% legendLabels = cell(1,numel(treatmentGroups));
% for jj = 1:numel(treatmentGroups)
%     result = regexp(treatmentGroups{jj}, '^[^_]+', 'match');
%     extracted_part = result{1};
%     legendLabels{jj} = extracted_part;
% end
end