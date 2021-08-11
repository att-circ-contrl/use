function newVal = CheckVararginPairs(varname, defaultVal, varargin)
%{
Parses varargin for name-value pairs
%}


newVal = defaultVal;
for i = 1:2:length(varargin)
    if isstring(varargin{i}) || ischar(varargin{i})
        if strcmpi(varname, varargin{i})
            newVal = varargin{i+1};
            break
        end
    else
        error('First element in varargin pairs should always be a string or character vector');
    end
end
    