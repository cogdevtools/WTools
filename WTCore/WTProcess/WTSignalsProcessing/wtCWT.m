% Complex Morlet wavelet
% Based on cwt_channel.c, algorithm in c++ provided by Gergo
% Matlab porting by Eugenio Parise, CDC CEU 2010        

function coeffs = wtCWT(signal, scales, points, cwMatrix)
    % Define parameters and matrices
    signal = signal';
    signal = signal(:,points);
    nSamples = (length (points));
    nChans = size(signal,1);
    coeffs = zeros(length(scales),nChans,nSamples);
    
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
                coeffs(iFreq,ch,:) = sqrt(conv2(signal(ch,:), ...
                    waveletRe, 'same').^2 + conv2(signal(ch,:), waveletIm, 'same').^2);
            end
        end
    else 
        for iFreq = 1:(length(scales))
            for ch = 1:nChans     
                waveletRe = (cwMatrix{iFreq,1});
                waveletIm = (cwMatrix{iFreq,2});
                re = (conv(signal(ch,:), waveletRe).^2);
                ptDiff = floor((length(re)-size(signal,2))/2);
                re = re(ptDiff+1:ptDiff+size(signal,2));
                im = (conv(signal(ch,:), waveletIm).^2);
                im = im(ptDiff+1:ptDiff+size(signal,2));
                coeffs(iFreq,ch,:) = sqrt(re + im);
            end
        end
    end
    coeffs = permute(coeffs,[1 3 2]); 
end

function oldConv2 = isOldConv2Function() 
    oldConv2 = false;
    try 
        conv2(1,1,'same');
    catch
        oldConv2 = true;
    end
end