% Author: Atanu Giri
% Date: 04/15/2024
%
% Possible parameter names 
% logistic3 fit: 'UA', 'slope', 'shift', 'Rsq'
% logistic4 fit: 'LA', 'slope', 'shift', 'UA', 'Rsq'
% BC fit: 'LA', 'slope', 'shift', 'UA', 'param_f', 'Rsq'
% LC fit: 'UA', 'slope', 'shift', 'UA_2', 'slope_2', 'shift_2', 'Rsq'
%
% Example usage: allFitParam('Alcohol_approachavoid_logistic3_fitting_param.mat')
%

function varargout = allFitParam(varargin)

% varargin = {'P2L1 Boost and alcohol_approachavoid_logistic4_fitting_param.mat'};

scriptDir = fileparts(mfilename('fullpath'));
myPath = fullfile(scriptDir, 'Mat files/');

allRsq = cell(1, numel(varargin));
UA = cell(1, numel(varargin));
slope = cell(1, numel(varargin));
shift = cell(1, numel(varargin));
animals = cell(1, numel(varargin));

if contains(varargin{1}, 'logistic3')
    for grp = 1:numel(varargin)
        loadFile = load(fullfile(myPath, varargin{grp}));
        [fitParam, R_squared, animal] = helperFun(loadFile);

        %% Remove negative slopes (Optional)
        ngtvSlpFltr = fitParam(:,2) <= 0;
        fitParam = fitParam(~ngtvSlpFltr, :);
        R_squared = R_squared(~ngtvSlpFltr, :);
        animal = animal(~ngtvSlpFltr, :);

        allRsq{grp} = R_squared;
        UA{grp} = fitParam(:,1);
        slope{grp} = fitParam(:,2);
        shift{grp} = fitParam(:,3);
        animals{grp} = animal;
    end

    varargout = {UA, slope, shift, allRsq, animals};

elseif contains(varargin{1}, 'logistic4')
    LA = cell(1, numel(varargin));

    for grp = 1:numel(varargin)
        loadFile = load(fullfile(myPath, varargin{grp}));
        [fitParam, R_squared, animal] = helperFun(loadFile);

        %% Remove negative slopes (Optional)
        ngtvSlpFltr = fitParam(:,2) <= 0;
        fitParam = fitParam(~ngtvSlpFltr, :);
        R_squared = R_squared(~ngtvSlpFltr, :);
        animal = animal(~ngtvSlpFltr, :);

        allRsq{grp} = R_squared;
        LA{grp} = fitParam(:,1);
        slope{grp} = fitParam(:,2);
        shift{grp} = fitParam(:,3);
        UA{grp} = fitParam(:,4);
        animals{grp} = animal;

    end

    varargout = {LA, slope, shift, UA, allRsq, animals};

elseif contains(varargin{1}, 'BC')
    LA = cell(1, numel(varargin));
    param_f = cell(1, numel(varargin));

    for grp = 1:numel(varargin)
        loadFile = load(fullfile(myPath, varargin{grp}));
        [fitParam, R_squared, animal] = helperFun(loadFile);

        allRsq{grp} = R_squared;
        LA{grp} = fitParam(:,3);
        slope{grp} = fitParam(:,1);
        shift{grp} = fitParam(:,4);
        UA{grp} = fitParam(:,2);
        param_f{grp} = fitParam(:,5);
    end

    varargout = {LA, slope, shift, UA, param_f, allRsq};

elseif contains(varargin{1}, 'LC')
    UA_2 = cell(1, numel(varargin));
    slope_2 = cell(1, numel(varargin));
    shift_2 = cell(1, numel(varargin));

    for grp = 1:numel(varargin)
        loadFile = load(fullfile(myPath, varargin{grp}));
        [fitParam, R_squared, animal] = helperFun(loadFile);

        allRsq{grp} = R_squared;
        UA{grp} = fitParam(:,1);
        slope{grp} = fitParam(:,2);
        shift{grp} = fitParam(:,3);
        UA_2{grp} = fitParam(:,4);
        slope_2{grp} = fitParam(:,5);
        shift_2{grp} = fitParam(:,6);
    end

    varargout = {UA, slope, shift, UA_2, slope_2, shift_2, allRsq};

end

%% Description of helperFun
    function [fitParam, R_squared, animal] = helperFun(loadFile)
        currentFitData = loadFile.trtmntFitData;
        currentFitData = currentFitData(~cellfun(@isempty, currentFitData));
        R_squared = cellfun(@(x) x.R_squared, currentFitData, 'UniformOutput', false);
        R_squared = cell2mat(R_squared);
        fitParam = cellfun(@(x) x.fit_params, currentFitData, 'UniformOutput', false);
        fitParam = cell2mat(fitParam);
        animal = cellfun(@(x) x.Animal, currentFitData, 'UniformOutput', false);
        animal = string(animal);
    end
end