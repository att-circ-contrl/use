function [table1, table2] = MatchVariables(table1, table2)

iVar = 1;

while ~isequal(table1.Properties.VariableNames, table2.Properties.VariableNames)
    vars1 = table1.Properties.VariableNames;
    vars2 = table2.Properties.VariableNames;
    if iVar <= length(vars1) && iVar <= length(vars2)
        if ~isequal(vars1{iVar}, vars2{iVar})
            var1in2 = find(ismember(vars2, vars1{iVar}));
            var2in1 = find(ismember(vars1, vars2{iVar}));
            if ~isempty(var1in2)
                table2 = [table2(:,1:iVar-1) table2(:,var1in2) table2(:,iVar:var1in2-1) table2(:,var1in2+1:end)];
            elseif ~isempty(var2in1)
                table1 = [table1(:,1:iVar-1) table1(:,var2in1) table1(:,iVar:var2in1-1) table1(:,var2in1+1:end)];
            else
                table1Temp = AddNewVar(table1, table2, iVar);
                table2Temp = AddNewVar(table2, table1, iVar);
                if iVar == length(vars2)
                    table2 = [table2Temp(:,1:iVar-1) table2Temp(:,iVar+1) table2Temp(:,iVar)];
                else
                    table2 = [table2Temp(:,1:iVar-1) table2Temp(:,iVar+1) table2Temp(:,iVar) table2Temp(:,iVar+2:end)];
                end
                table1 = table1Temp;
%                 iVar = iVar + 1;
            end
        end
    elseif iVar <= length(vars1)
        table2 = AddNewVar(table2, table1, iVar);
    elseif iVar <= length(vars2)
        table1 = AddNewVar(table1, table2, iVar);
    else
        fred = 2;
    end
    iVar = iVar + 1;
end


function t1 = AddNewVar(t1, t2, iVar)

varName = t2.Properties.VariableNames{iVar};

switch class(t2.(varName))
    case 'cell'
        newVar = cell(height(t1),1);
    case 'double'
        newVar = nan(height(t1),1);
    otherwise
        error(['No method for adding variables of type ' class(t2.(varName)) ' to table.']);
end

t1 = [t1(:,1:iVar-1) table(newVar, 'VariableNames', {varName}) t1(:,iVar:end)];
