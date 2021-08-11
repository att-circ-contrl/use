function dataTable = ReadDataFiles(path, identifier, varargin)
%{
ReadDataFiles concatenates a folder of columnar text files with a common naming
convention (e.g. "*_Trial1.txt", "*_Trial2.txt", etc) into a single table.
(The extension does not need to be .txt)

Inputs:
path: the path to the data folder.
identifier: the common elements to filenames (e.g. '*_Trial*.txt')

Varargin pairs:
'ImportOptions', char or cell - if 'detectImportOptions', runs this on
first file in folder. If cell, should be pairs of import options.

%}

fileInfo = dir([path filesep identifier]);
[fileNames,~] = sort_nat({fileInfo.name}'); 

%some issues with hidden files
startsWithPeriod = @(x) startsWith(x, '.');
fileNames(cellfun(startsWithPeriod, fileNames)) = [];



numFiles = length(fileNames);

if isempty(fileNames)
    error(['No files matching "' identifier '" in folder ' path '.']);
end

importOptions = CheckVararginPairs('importOptions', 'detectImportOptions', varargin{:});

if ~isempty(importOptions)
    if isstring(importOptions) || ischar(importOptions)
        if strcmpi(importOptions, 'detectImportOptions')
            opt = detectImportOptions([path filesep fileNames{1}]);
        else
            error(['Unknown import options string "' importOptions '".']);
        end
    end
end



dataCell = cell(numFiles,1);

splitPath = strsplit(path, filesep);
finalFolder = splitPath{end};

matlabversion = version;
year = str2double(matlabversion(end-5:end-2));

reverseStr = '';
for iFile = 1 : numFiles
    %print percentage of file reading
    percentDone = 100 * iFile / numFiles;
    msg = sprintf(['%3.1f percent finished reading files from ' finalFolder], percentDone); 
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    try
        if iscell(importOptions)
            if year < 2019
                dataCell{iFile} = readtable([path filesep fileNames{iFile}], importOptions{:});
            else
                dataCell{iFile} = readtable([path filesep fileNames{iFile}], importOptions{:}, 'Format', 'auto');
            end
        elseif isstring(importOptions) || ischar(importOptions)
            if year < 2019
                dataCell{iFile} = readtable([path filesep fileNames{iFile}], opt);
            else
                dataCell{iFile} = readtable([path filesep fileNames{iFile}], opt, 'Format', 'auto');
            end
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB:readtable:BadFileFormat')
            isCalibIssue = 1;
            rawTextArray = strsplit(fileread([path filesep fileNames{iFile}]), '\n')';
            numTabs = count(rawTextArray{1},char(9));
            %older versions of USE don't import calibration data well this
            %is a super hacky way of repairing that
            calibLines = [];
            timestampLines = [];
            for iLine = 1:length(rawTextArray)
                if count(rawTextArray{iLine},char(9)) ~= numTabs && numTabs == 2
                    if strcmp(rawTextArray{iLine}(1:5),'CALIB') 
                        prevLine = strsplit(rawTextArray{iLine-1}, char(9));
                        rawTextArray{iLine} = [prevLine{1} char(9) prevLine{2} char(9) rawTextArray{iLine}];
                        calibLines = [calibLines iLine];
                    elseif strcmp(rawTextArray{iLine}(1:22), '###PythonSentTimeStamp')
                        rawTextArray(calibLines) = strcat(rawTextArray(calibLines), rawTextArray{iLine});
                        calibLines = [];
                        timestampLines = [timestampLines iLine];
                    else
                        isCalibIssue = 0;
                        break;
                    end
                elseif count(rawTextArray{iLine},char(9)) ~= numTabs
                    isCalibIssue = 0;
                    break;
                end
            end
            if isCalibIssue
                rawTextArray(timestampLines) = [];
                
                rawText = strjoin(rawTextArray(2:end), newline);
                cellText = textscan(rawText, '%f %f %s', length(rawTextArray) - 1, 'Delimiter', '\t');
                dataCell{iFile} = table(cellText{1}, cellText{2}, cellText{3}, 'VariableNames', strsplit(rawTextArray{1}, char(9)));
            end
        else
            isCalibIssue = 0;
        end
        if ~isCalibIssue
            display(['Error reading file ' fileNames{iFile}]);
            error(ME.message);
        end
    end
end
fprintf('\n');
% dataCell(cellfun(@isempty,dataCell)) = []; %older versions of FLU task wrote empty files 
concatenated = 0;
while ~concatenated
    try
        dataTable = vertcat(dataCell{:});
        concatenated = 1;
    catch ME
    %     if strcmp(ME.identifier, 'MATLAB:table:vertcat:VertcatCellAndNonCell')
        switch ME.identifier
            case 'MATLAB:table:vertcat:VertcatCellAndNonCell'
                quotes = strfind(ME.message, '''');
                if length(quotes) == 2
                    problemVar = ME.message(quotes(1)+1 : quotes(2)-1);
                    
                    if find(ismember({'TrialInBlock', 'TrialInExperiment'}, problemVar))
                        dataCell = ForceDouble(dataCell, problemVar);
                    elseif find(ismember({'TouchedObjectID', 'TouchedObjectId', 'SimpleTouchTarget', 'ShotgunTouchHits', 'ModalShotgunTouchHit', 'PreSplitEventCodes', 'SimpleGazeTarget', 'ShotgunGazeHits', 'ModalShotgunGazeHit'}, problemVar))
                        dataCell = ForceCell(dataCell, problemVar);
                    else
                        error(['Concatenation problem with variable ' problemVar]);
                    end
                end
            otherwise
                error(ME.message);
        end
        fred = 2;
    end
end

function dataCell = ForceDouble(dataCell, varName)
for iCell = length(dataCell):-1:1
    if iscell(dataCell{iCell}.(varName))
        dataCell{1}.(varName) = str2double(dataCell{1}.(varName));
    end
end

function dataCell = ForceCell(dataCell, varName)
for iCell = length(dataCell):-1:1
    if ~iscell(dataCell{iCell}.(varName)) && sum(isnan(dataCell{iCell}.(varName))) == height(dataCell{iCell})
        dataCell{iCell}.(varName) = cell(height(dataCell{iCell}),1);
        dataCell{iCell}.(varName)(:) = {''};
    elseif ~iscell(dataCell{iCell}.(varName)) && isnumeric(dataCell{iCell}.(varName))
        newData = cell(height(dataCell{iCell}),1);
        newData(isnan(dataCell{iCell}.(varName))) = {''};
        numericCells = find(~isnan(dataCell{iCell}.(varName)));
        for i = 1:length(numericCells)
            newData(numericCells(i)) = {num2str(dataCell{iCell}.(varName)(numericCells(i)))};
        end
        dataCell{iCell}.(varName) = newData;
    elseif ~iscell(dataCell{iCell}.(varName))
        error(['Unable to force variable ' varName ' to cell.']);
    end
end

