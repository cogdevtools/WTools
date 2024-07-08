% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

classdef WTStringUtils

    methods(Static)
        % Convert the input or its content into char arrays, possibly in a recursive way. The input can be
        % strings, string arrays or cell arrays.  String arrays are converted into cell arrays.
        function c = convertStrToChar(v, recursively)
            if iscell(v)
                if nargin > 1 && recursively
                    c = cellfun(@WTStringUtils.convertToChar, v, 'UniformOutput', false);
                else
                    [v{:}] = convertStringsToChars(v{:});
                    c = v;
                end
            else
                c = convertStringsToChars(v);
            end
       end

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

        % Convert a possible html char array into text (remove hyperlinks). If the conversion failse, it returns
        % the input.
        function result = htmlToCharArray(html)
            try
                result = convertStringsToChars(extractHTMLText(htmlTree(html)));
            catch
                result = html;
            end
        end
    end
end