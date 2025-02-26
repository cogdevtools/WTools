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

% Complex Morlet wavelet transform     
function [coeffsMod, coeffsRe, coeffsIm] = wtCWT(signal, scales, points, cwMatrix)
    % signal: matrix of size (nChans, nSamples)
    signal = signal';
    signal = signal(:,points);
    nSamples = length(points);
    nChans = size(signal,1);
    coeffsMod = zeros(length(scales),nChans,nSamples);
    coeffsRe = zeros(length(scales),nChans,nSamples);
    coeffsIm = zeros(length(scales),nChans,nSamples);
    
    % Remove DC component from signal.
    for ch = 1:nChans
        signalDC = repmat(mean(signal(ch, :)), 1 , nSamples);
        signal(ch,:) = signal(ch,:) - signalDC;
    end
    
    % Calculate CWT at each frequency. (The wavelets calculation has been moved to wtPerformCWT.m 
    % to speed up computation)
    if  ~isOldConv2Function() 
        for iFreq = 1:(length(scales)) 
            for ch = 1:nChans
                waveletRe = (cwMatrix{iFreq,1});
                waveletIm = (cwMatrix{iFreq,2}); 
                % New optimized algorithm by Luca Filippin, using MATLAB function conv();  
                re = conv2(signal(ch,:), waveletRe, 'same');
                im = conv2(signal(ch,:), waveletIm, 'same');
                coeffsRe(iFreq,ch,:) = re;
                coeffsIm(iFreq,ch,:) = im;
                coeffsMod(iFreq,ch,:) = sqrt(re.^2 + im.^2);
            end
        end
    else 
        for iFreq = 1:(length(scales))
            for ch = 1:nChans     
                waveletRe = (cwMatrix{iFreq,1});
                waveletIm = (cwMatrix{iFreq,2});
                re = conv(signal(ch,:), waveletRe);
                im = conv(signal(ch,:), waveletIm);
                ptDiff = floor((length(re)-size(signal,2))/2);
                re = re(ptDiff+1:ptDiff+size(signal,2));
                im = im(ptDiff+1:ptDiff+size(signal,2));
                coeffsRe(iFreq,ch,:) = re;
                coeffsIm(iFreq,ch,:) = im;
                coeffsMod(iFreq,ch,:) = sqrt(re.^2 + im.^2);
            end
        end
    end
    % Permute (freq, channel, time) as (freq, time, channel)
    coeffsRe = permute(coeffsRe,[1 3 2]); 
    coeffsIm = permute(coeffsIm,[1 3 2]); 
    coeffsMod = permute(coeffsMod,[1 3 2]);
end

function oldConv2 = isOldConv2Function() 
    oldConv2 = false;
    try 
        conv2(1,1,'same');
    catch
        oldConv2 = true;
    end
end