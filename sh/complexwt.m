function coefs=complexwt(signal,scales,wname,fb,points,Fs,cwtmatrix)

%%%%%%%%%%%%%%%%%%Complex Morlet wavelet%%%%%%%%%%%%%%%%%%%%
%Based on cwt_channel.c, algorithm in c++ provided by Gergo%
%Matlab porting by Eugenio Parise, CDC CEU 2010            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(wname,'cwt')
    
    %define parameters and matrices
    signal=signal';
    signal=signal(:,points);
    nSamples= (length (points));
    nChans=size(signal,1);
    coefs = zeros(length(scales),nChans,nSamples);
    
    %Remove DC component from signal.
    for ch=1:nChans
        signalDC = repmat(mean(signal(ch, :)), 1 , nSamples);
        signal(ch,:) = signal(ch,:) - signalDC;
    end
    
    %Calculate CWT at each frequency.
    %(The wavelets calculation has been moved to tf_cmor.m to speed up computation)
    for iFreq=1:(length(scales))        
        waveletRe=(cwtmatrix{iFreq,1});
        waveletIm=(cwtmatrix{iFreq,2});
        
        %Convolve wavelet with signal
        for ch=1:nChans

            %New optimized algoritm by Luca Filippin,
            %using MATLAB function conv();
            try
                %This will not work on older Matlab versions,
                %where the option 'same' is not implemented
                coefs(iFreq,ch,:) = sqrt(conv2(signal(ch,:), ...
                    waveletRe, 'same').^2 + conv2(signal(ch,:), waveletIm, 'same').^2);
            catch
                RE=(conv(signal(ch,:), waveletRe).^2);
                ptdiff=floor((length(RE)-size(signal,2))/2);
                RE=RE(ptdiff+1:ptdiff+size(signal,2));
                IM=(conv(signal(ch,:), waveletIm).^2);
                IM=IM(ptdiff+1:ptdiff+size(signal,2));
                coefs(iFreq,ch,:) = sqrt(RE + IM);
            end
            
        end
        
    end
    
    coefs=permute(coefs,[1 3 2]);
    
end

return
