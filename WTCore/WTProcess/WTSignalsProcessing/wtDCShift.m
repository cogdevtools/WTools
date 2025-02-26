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

% Apply a DC shift to ensure that the CWT (power or amplittude) which 
% has been baseline corrected, doesn't have negative or zero values, in 
% order to be able to apply a log transform (to dB for example). Notice
% that a DC shift is applied only if the signal min calculated as by 
% the perChannel, perFrequency parameters is negative, otherwise no 
% shift is necessary.
% - data: matrix of size (channels, frequencies, time)
% - minFactor, epsilon: those 2 parameters are used to determine an extra
%   delta value to ensure that the signal after being shifted by -min:
%   delta = max(minFactor * abs(minVal), epsilon).
%   A eeasonable value for epsilon depends on the type of signal, wether 
%   it's power or amplitude: for amplitute 10^-6, for power 10^-12 might
%   work. minFactor is a % factor which must be in (0, 0.1] range. 
% - perChannel: if true, calculate the DC  per channel
% - perFrequency: if true, calculate the DC  per frequency (=> perTime false)
% - perTime: if true, calculate the DC  per time (=> perFrequency false)
% Return:
% - data: the shifted data
% - dc: an array/matrix of size (1, channels), or (1, frequencies) or 
%   (channels, frequencies) or a scalar, depending on the value of the 
%   paramter perChannel and perFrequency.

function [dataShifted, dc] = wtDCShift(data, minFactor, epsilon, perChannel, perFrequency, perTime)
    WTValidations.mustBeInRange(epsilon, 0, 0.1, false, true);
    WTValidations.mustBeInRange(minFactor, 0, 0.1, false, true);
    if perFrequency && perTime
        WTException.incompatibleValues('perFrequncy and perTime cannot be both true').throw();
    end

    dataShifted = data;  % Initialize shifted data matrix
    [channels, freqs, times] = size(data);

    % Check if we want to apply shift per channel and/or per frequency
    if perChannel
        if perFrequency
            % Apply shift per channel and frequency
            dc = zeros(channels, freqs);  % Initialize dc matrix for each channel and frequency

            for c = 1:channels
                for f = 1:freqs
                    minVal = min(dataShifted(c, f, :), [], 'all');  % Minimum value per channel and frequency
                    
                    if minVal <= 0
                        delta = max(minFactor * abs(minVal), epsilon);
                        dc(c, f) = -minVal + delta;  % Calculate shift
                        dataShifted(c, f, :) = dataShifted(c, f, :) + dc(c, f);  % Apply shift
                    end
                end
            end 
        elseif perTime
            % Apply shift per channel and time
            dc = zeros(channels, times);  % Initialize dc matrix for each channel and frequency

            for c = 1:channels
                for t = 1:times
                    minVal = min(dataShifted(c, :, t), [], 'all');  % Minimum value per channel and time
                    
                    if minVal <= 0
                        delta = max(minFactor * abs(minVal), epsilon);
                        dc(c, t) = -minVal + delta;  % Calculate shift
                        dataShifted(c, :, t) = dataShifted(c, :, t) + dc(c, t);  % Apply shift
                    end
                end
            end 
        else 
            % Apply shift per channel
            dc = zeros(1, channels);  % Initialize dc matrix for each channel

            for c = 1:channels
                minVal = min(dataShifted(c, :, :), [], 'all');  % Minimum value per channel (across all frequencies)
                
                if minVal <= 0
                    delta = max(minFactor * abs(minVal), epsilon);
                    dc(c) = -minVal + delta;  % Calculate shift
                    dataShifted(c, :, :) = dataShifted(c, :, :) + dc(c);  % Apply shift
                end
            end
        end 
    else 
        if perFrequency
            % Apply shift per frequency
            dc = zeros(1, freqs);  % Initialize dc matrix for each frequency

            for f = 1:freqs
                minVal = min(dataShifted(:, f, :), [], 'all');  % Minimum value per frequency (across all channels)
                
                if minVal <= 0
                    delta = max(minFactor * abs(minVal), epsilon);
                    dc(f) = -minVal + delta;  % Calculate shift
                    dataShifted(:, f, :) = dataShifted(:, f, :) + dc(f);  % Apply shift
                end
            end
        elseif perTime
            % Apply shift per time
            dc = zeros(1, times);  % Initialize dc matrix for each time

            for t = 1:times
                minVal = min(dataShifted(:, :, t), [], 'all');  % Minimum value per time (across all channels)
                
                if minVal <= 0
                    delta = max(minFactor * abs(minVal), epsilon);
                    dc(t) = -minVal + delta;  % Calculate shift
                    dataShifted(:, :, t) = dataShifted(:, :, t) + dc(t);  % Apply shift
                end
            end
        else
            % Apply global shift
            minVal = min(dataShifted, [], 'all');  % Minimum value across the entire dataset
            dc = 0;  % Global shift

            if minVal <= 0
                delta = max(minFactor * abs(minVal), epsilon);
                dc = -minVal + delta;  % Calculate global shift
                dataShifted = dataShifted + dc;  % Apply shift
            end
        end
    end
end