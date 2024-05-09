classdef WTStringUtils

    methods(Static)
        % quote() quotes the argument (which must be a char array)
        function quoted = quote(str) 
            quoted = sprintf('''%s''', char(str));
        end

        % quoteMany() does the same as quote but on a variable input of char array arguments.
        function quoted = quoteMany(varargin)
            quoted = cellfun(@WTStringUtils.quote, varargin, 'UniformOutput', false);
        end

        % Transform a cell array of strings (char arrays) in a new list where each element is made of 'separator' 
        % separated strings of max 'itemsPerLine' original items. The first item in the returned result can be 
        % prefixed with an header which can be different depending if the original list contained only one item  
        % or multiple (see the parameters 'singleItemHeader' or 'multipleItemsHeader')
        function lines = chunkStrings(singleItemHeader, multipleItemsHeader, strItems, itemsPerLine, separator)
            lines = {''};
            if nargin < 5
                separator = ',';
            end
            nItems = length(strItems);
            if nItems == 0
                return
            end
            header = WTCodingUtils.ifThenElse(nItems == 1, singleItemHeader, multipleItemsHeader);
            iter = 1:itemsPerLine:nItems;
            lines = cell(1, length(iter));
            for i = 1:length(iter)
                subItems = strItems(iter(i):min(iter(i)+itemsPerLine, nItems));
                lines{i} = char(join(subItems, separator));
            end
            lines{1} = [ header lines{1} ];
        end
    end
end