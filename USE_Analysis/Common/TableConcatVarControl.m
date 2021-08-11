function newTable = TableConcatVarControl(table1, table2, varargin)


%rename any columns
columnRenames = CheckVararginPairs('ColumnRenames', [], varargin{:});

if ~isempty(columnRenames)
    if ~iscell(columnRenames) || length(columnRenames) ~= 2
        error('ColumnRenames must be a cell array of length 2.');
    elseif length(columnRenames{1}) ~= length(columnRenames{2})
        error('The two cells in ColumnRenames must have the same number of elements.');
    end
    
    for iCol = 1:length(columnRenames{1})
        if ~ischar(columnRenames{1}(iCol)) || ~isstring(columnRenames{1}(iCol))
            error(['Item ' num2str(iCol) ' in ColumnRenames cell #1 must be a character or string but it is not.']);
        end
        if ~ischar(columnRenames{2}(iCol)) || ~isstring(columnRenames{2}(iCol))
            error(['Item ' num2str(iCol) ' in ColumnRenames cell #2 must be a character or string but it is not.']);
        end
        changeCol1 = find(ismember(table1.Properties.VariableNames, columnRenames{1}(iCol)));
        if (~isempty(changeCol1))
            table1.Properties.VariableNames{changeCol1} = columnRenames{2}(iCol);
        end
        changeCol2 = find(ismember(table2.Properties.VariableNames, columnRenames{1}(iCol)));
        if (~isempty(changeCol2))
            table2.Properties.VariableNames{changeCol2} = columnRenames{2}(iCol);
        end
    end
end

%force desired variables to be numeric
ensureNumeric = CheckVararginPairs('EnsureNumeric', [], varargin{:});
if ~isempty(ensureNumeric)
    table1 = ConvertTableVarsToNumeric(table1, ensureNumeric);
    table2 = ConvertTableVarsToNumeric(table2, ensureNumeric);
end

[table1, table2] = MatchVariables(table1, table2);
newTable = [table1; table2];
