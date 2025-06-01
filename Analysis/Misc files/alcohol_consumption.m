% Author: Atanu Giri
% Date: 01/22/2025
%
% This script calculates the alcohol consumption by sex in input treatment
% group. Use 'false' if you don't want to normalize by weight.
%
% Example usage:
% [male_psych, female_psych, male_total, female_total] = alcohol_consumption('P2A Boost and alcohol',false);
%
function varargout = alcohol_consumption(trtGroup, wt_normalize)

if nargin < 2
    wt_normalize = true;
end

males = {'aladdin', 'carl', 'jafar', 'jimi', 'jr', 'kobe', 'mike', 'scar', ...
    'simba', 'sully'};
females = {'alexis', 'fiona', 'harley', 'juana', 'kryssia', 'neftali', ...
    'raven', 'renata', 'sarah', 'shakira'};

% Get weights from Excel sheet
maleWts = [578, 592, 529, 513, 486, 562, 534, 500, 518, 616];
femaleWts = [264, 339, 334, 264, 282, 304, 294, 295, 311, 312];

% Alcohol consumption per mL
alcVol = [20, 10, 4, 1] ./100;

% Connect to database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');

treatmentIDs = treatmentIDfun(trtGroup, conn);
treatmentIDs_str = strjoin(arrayfun(@num2str, treatmentIDs, 'UniformOutput', false), ',');
treatment_data = fetchHealthDataTable('approachavoid', treatmentIDs_str, conn);
treatment_data = cleanBadSessionsFromTable(treatment_data, 'approachavoid', trtGroup);

% Create placeholder
animalList = {males, females};
wts = {maleWts, femaleWts};
totalAlcConsumPerSession = cell(1,2); % Placeholder for both sexes
animalCt = cell(1,2); % Placeholder for both sexes

for sex = 1:2
    totalAlcConsumPerSession{sex} = zeros(25, 4);
    animalCt{sex} = zeros(25, 1);
end

for sex = 1:2
    animals = animalList{sex};
    animalWts = wts{sex};

    for animal = 1:numel(animals)
        % Calculations for male
        [featureForEach, ~, trialCt] = getPsychometricBySession(treatment_data, ...
            'approachavoid', animals{animal});

        approachNum = featureForEach.*trialCt;
        alcConc = 0.789;

        if wt_normalize
            alcoholConsumed = (approachNum .*alcVol*alcConc)/(animalWts(animal)*0.001);
        else
            alcoholConsumed = (approachNum .*alcVol*alcConc);
        end

        rows = size(alcoholConsumed, 1);
        totalAlcConsumPerSession{sex}(1:rows, :) = totalAlcConsumPerSession{sex}(1:rows, :) + alcoholConsumed;
        animalCt{sex}(1:rows, :) = animalCt{sex}(1:rows, :) + 1;
    end
end

% Remove empty rows
for sex = 1:2
    validRow = animalCt{sex} ~=0;
    totalAlcConsumPerSession{sex} = totalAlcConsumPerSession{sex}(validRow,:);
    animalCt{sex} = animalCt{sex}(validRow);
end

%% Canculate mean alcohol consumtion per animal per session accross 4 conc
% Obtain average alcohol consumption per animal
avAlcConsumPerSession = cell(1,2);
meanAlcConsum = cell(1,2);
stdErr = cell(1,2);

for sex = 1:2
    avAlcConsumPerSession{sex} = totalAlcConsumPerSession{sex} ./animalCt{sex};
    meanAlcConsum{sex} = mean(avAlcConsumPerSession{sex});
    stdErr{sex} = std(avAlcConsumPerSession{sex})/sqrt(length(animalCt{sex}));
end

% Plot figure
figure;
sex_labels = {'Male', 'Female'};
colors = {'b','r'};

for sex = 1:2
    errorbar(1:4, meanAlcConsum{sex}, stdErr{sex}, 'DisplayName', sex_labels{sex}, ...
        'LineWidth', 2, 'Color', colors{sex});
    hold on;
end

hold off;

% Add label and legend
xlabel('Sucrose conc.', 'Interpreter','none', 'FontSize', 25);
if wt_normalize
    ylabel(sprintf('Alcohol consumption (g/kg)'), 'Interpreter', 'latex', 'FontSize', 25);
else
    ylabel(sprintf('Alcohol consumption (g)'), 'Interpreter', 'latex', 'FontSize', 25);
end
xticks(1:4);
label = {'0.5','2','5','9'};
set(gca,'xticklabel',label,'FontSize',15);
legend('show', 'Interpreter', 'none');


%% Canculate mean alcohol consumtion per animal per session
totalAlcConsumOverAllConc = cell(1,2);
meanAlcConsumOverAllConc = zeros(1,2);
stdErrOverAllConc = zeros(1,2);

for sex = 1:2
    totalAlcConsumOverAllConc{sex} = sum(avAlcConsumPerSession{sex}, 2);
    meanAlcConsumOverAllConc(sex) = mean(totalAlcConsumOverAllConc{sex});
    stdErrOverAllConc(sex) = std(totalAlcConsumOverAllConc{sex})/sqrt(length(animalCt{sex}));
end

% Create a bar plot
figure;
barHandle = bar(meanAlcConsumOverAllConc, 'FaceColor', 'flat'); % Bar plot
hold on;

% Set bar colors: blue for male, red for female
barHandle.CData(1, :) = [0 0 1]; % RGB for blue
barHandle.CData(2, :) = [1 0 0]; % RGB for red

% Add error bars
x = barHandle.XEndPoints; % Get x-coordinates of bar centers
errorbar(x, meanAlcConsumOverAllConc, stdErrOverAllConc, 'k', ...
    'linestyle', 'none', 'LineWidth', 1.5); % Error bars

% Customize the plot
xticks([1 2]); % Set x-ticks
xticklabels(sex_labels); % Set x-tick labels
if wt_normalize
    ylabel('Alcohol consumption (g/kg)', 'Interpreter', 'latex', 'FontSize', 14);
else
    ylabel('Alcohol consumption (g)', 'Interpreter', 'latex', 'FontSize', 14);
end
set(gca, 'FontSize', 12);
hold off;

% Return output
varargout{1} = avAlcConsumPerSession{1};
varargout{2} = avAlcConsumPerSession{2};

varargout{3} = totalAlcConsumOverAllConc{1};
varargout{4} = totalAlcConsumOverAllConc{2};