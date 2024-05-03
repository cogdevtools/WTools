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

        function txt = stringCellsField(fieldName, cells)
            try
                quoted = WTUtils.quoteMany(cells{:});
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