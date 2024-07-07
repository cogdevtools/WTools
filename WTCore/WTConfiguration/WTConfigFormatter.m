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

classdef WTConfigFormatter 

    properties(Constant)
        FmtStr        = '''%s'''
        FmtInt        = '%d'
        FmtIntStr     = '''%d'''
        FmtFloat      = '%f'
        FmtFloatStr   = '''%f'''
        FmtArray      = '[%s]'
        FmtArrayStr   = '''[%s]'''  
    end

    methods(Static)

        function txt = stringField(fieldName, value)
            try
                txt = sprintf('%s = ''%s'';', fieldName, value);
            catch me
                WTLog().except(me, false);
                txt = '';
            end   
        end

        function txt = intField(fieldName, value)
            try
                WTValidations.mustBeInt(value);
                txt = sprintf('%s = %d;', fieldName, value);
            catch me
                WTLog().except(me, false);
                txt = '';
            end   
        end

        function txt = doubleField(fieldName, value)
            try
                txt = sprintf('%s = %s;', fieldName, num2str(value));
            catch me
                WTLog().except(me, false);
                txt = '';
            end   
        end

        function txt = stringCellsField(fieldName, cells)
            try
                quoted = WTStringUtils.quoteMany(cells{:});
                content = char(join(quoted, ' '));
                txt = sprintf('%s = { %s };', fieldName, content);
            catch me
                WTLog().except(me, false);
                txt = '';
            end   
        end

        function txt = stringCellsFieldArgs(fieldName, varargin)
            txt = WTConfigFormatter.stringCellsField(fieldName, varargin);
        end

        function txt = intCellsField(fieldName, cells)
            if isempty(cells)
                txt = sprintf('%s = { };', fieldName);
                return
            end
            try
                fmt = ['%s = { ' repmat('%d ', 1, length(cells)) '};'];
                txt = sprintf(fmt, fieldName, cells{:});
            catch me
                WTLog().except(me, false);
                txt = '';
            end   
        end

        function txt = intCellsFieldArgs(fieldName, varargin)
            txt = WTConfigFormatter.intCellsField(fieldName, varargin);
        end

        function txt = genericCellsFieldArgs(fieldName, varargin)
            if isempty(varargin)
                txt = sprintf('%s = { };', fieldName);
                return
            end 
            try
                contentFmt = join(varargin(1:2:end), ' ');
                contentVal = varargin(2:2:end);
                fmt = ['%s = { ' contentFmt{1} ' };'];
                txt = sprintf(fmt, fieldName, contentVal{:});
            catch me
                WTLog().except(me, false);
                txt = '';
            end
        end
    end
end