function dataCell = ReadJsonFiles(path, identifier)
%{
ReadJsonFiles reads a folder of json text files with a common naming
convention (e.g. "*_Trial1.txt", "*_Trial2.txt", etc) into a single cell object (or struct if there is only one file).
(The extension does not need to be .txt)

Inputs:
path: the path to the data folder.
identifier: the common elements to filenames (e.g. '*_Trial*.txt')

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


splitPath = strsplit(path, filesep);
finalFolder = splitPath{end};


if numFiles> 1
    dataCell = cell(numFiles,1);
    reverseStr = '';
    for iFile = 1 : numFiles
        %print percentage of file reading
        percentDone = 100 * iFile / numFiles;
        msg = sprintf(['%3.1f percent finished reading files from ' finalFolder], percentDone);
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        
        dataCell{iFile} = jsondecode(fileread([path filesep fileNames{iFile}]));
        
    end
else
    dataCell = jsondecode(fileread([path filesep fileNames{1}]));
end


