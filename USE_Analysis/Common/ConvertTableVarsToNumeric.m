function tableToCheck = ConvertTableVarsToNumeric(tableToCheck, ensureNumeric)
%ensures specific variables are numeric (sometimes they can be read in as
%strings)

%Inputs:
%ensureNumeric: a cell array of variable names that will be checked for numeric-ness
%and converted to numeric if necessary. There is no error correction here,
%all strings will be converted to numeric

for iVar = 1:length(ensureNumeric)
    colToCheck = find(ismember(tableToCheck.Properties.VariableNames, ensureNumeric{iVar}), 1);
    if ~isempty(colToCheck)
        varName = tableToCheck.Properties.VariableNames{colToCheck};
        oldVar = tableToCheck.(varName);
        if ~isnumeric(oldVar)
            tableToCheck.(varName) = [];
            if iscell(oldVar)
                for iEntry = 1:length(newVar)
                    if ~isnumeric(newVar{iEntry})
                        newVar{iEntry} = str2double(newVar{iEntry});
                    end
                end
                oldVar = cell2mat(oldVar);
            else
                error(['Trying to convert non-numeric variable ' varName ' to numeric but it is not a cell.']);
            end
            if colToCheck == 1
                tableToCheck = [table(newVar, 'VariableNames', {varName}) tableToCheck];
            else
                tableToCheck = [tableToCheck(:,1:colToCheck-1) table(newVar, 'VariableNames', {varName}) tableToCheck(:,colToCheck:end)];
            end
        end
    end
end