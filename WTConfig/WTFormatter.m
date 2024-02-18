classdef WTFormatter 

    properties(Constant)
        FmtStr        = '''%s'''
        FmtInt        = '%d'
        FmtIntStr     = '''%d'''
        FmtFloat      = '%f'
        FmtFloatStr   = '''%f'''
        FmtArrayStr   = '''[%s]'''  
    end

    methods(Static)

        function txt = StringCellsField(fieldName, cells)
            try
                quoted = WTUtils.quoteMany(cells{:});
                content = char(join(quoted, ' '));
                txt = sprintf('%s = { %s };', fieldName, content);
            catch me
                WTLog().except(me, false);
                txt = '';
            end   
        end

        function txt = StringCellsFieldArgs(fieldName, varargin)
            txt = WTFormatter.StringCellsField(fieldName, varargin);
        end

        function txt = IntCellsField(fieldName, cells)
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

        function txt = IntCellsFieldArgs(fieldName, varargin)
            txt = WTFormatter.IntCellsField(fieldName, varargin);
        end

        function txt = GenericCellsFieldArgs(fieldName, varargin)
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