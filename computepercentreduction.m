function percentreduction = computepercentreduction(INEEG, varargin)
%   Computes percent reduction
%
%   percentreduction = computepercentreduction(EEG, 'ArtifactChannel', EEG.data(find(strcmp({EEG.chanlocs.labels},'VEOG')),:), 'ComponentArray', [1, 2]);
%

    if ~isempty(varargin)
             r=struct(varargin{:});
    end
    try, r.Window; catch, r.Window = [-150 150]; end
    try, r.MinimumArtifacts; catch, r.MinimumArtifacts = 4; end
    try, r.VisualizeData; catch, r.VisualizeData = 'False'; end
    try, r.TemplateThreshold; catch, r.TemplateThreshold = 0.96; end
    try, r.MinimumCorrelation; catch, r.MinimumCorrelation = 0.8; end
    try, r.ComponentArray; catch, r.ComponentArray = [0]; end
      
    if isempty(INEEG.icaact)
        INEEG.icaact = (INEEG.icaweights*INEEG.icasphere)*reshape(INEEG.data, INEEG.nbchan, INEEG.trials*INEEG.pnts);
        INEEG.icaact = reshape( INEEG.icaact, size(INEEG.icaact,1), INEEG.pnts, INEEG.trials);
    end
    try
        r.ArtifactLatencies; 
    catch % no latency markers were inputted
        fprintf('\n')
        fprintf('icablinkmetrics(). Artifact latency information not provided. Running eyeblinklatencies() on inputted artifact channel.')
        r.ArtifactLatencies = eyeblinklatencies('BlinkActivity', r.ArtifactChannel, 'SampleRate', INEEG.srate, 'Threshold', r(1).TemplateThreshold);
        if (numel(r.ArtifactLatencies) < r.MinimumArtifacts)
            fprintf('Warning at icablinkmetrics(). A small number of eye blinks were found in the data. Adjusting parameters for searching and trying again.\n')
            r.ArtifactLatencies = eyeblinklatencies('BlinkActivity', r.ArtifactChannel, 'SampleRate', INEEG.srate, 'Threshold', 0.9);
        end
    end
    if (numel(r.ArtifactLatencies) < r.MinimumArtifacts)
        error('Error at icablinkmetrics(). Too few blink events are available for reliable metrics. Try including more markers.');
    end
    ArtifactLatencies = r.ArtifactLatencies;
   
    %% Step 1: Make sure inputted blink latencies do not overlap ends of data with the window period and that the blinks are consistent
    % Set window period in points instead of ms
    r.Window(1) = floor(r.Window(1)*(INEEG.srate/1000));
    r.Window(2) = floor(r.Window(2)*(INEEG.srate/1000));
    
    % Screen blink latencies relative to window period
    for blinkindex = 1:size(ArtifactLatencies,2)
        if ((ArtifactLatencies(blinkindex) + r.Window(1)) < 0) || ((ArtifactLatencies(blinkindex) + r.Window(2)) > INEEG.pnts)
            ArtifactLatencies(blinkindex) = 0;
        end
    end
    ArtifactLatencies = ArtifactLatencies(ArtifactLatencies~=0); % Remove blinks which would overlap with zero and the end of the data
    if (numel(ArtifactLatencies) < r.MinimumArtifacts)
        error('Error at icablinkmetrics(). Too few blink events are available for reliable metrics. Try including more markers or shortening the window period.');
    end
    
    %% Step 2: Prepare Data Matrices
    % Create Average Eyeblink from Artifact Channel (i.e., VEOG)
    r.ArtifactChannel = fastsmooth(r.ArtifactChannel, floor(INEEG.srate/50), 2, 1); % Smooth the VEOG channel to remove high frequency activity
    matrixofVEOGiBlinks = zeros(size(ArtifactLatencies,2),(r.Window(2)-r.Window(1))+1);
    for blinkindex = 1:size(ArtifactLatencies,2)
        matrixofVEOGiBlinks(blinkindex,:) = r.ArtifactChannel(1,(r.Window(1)+ArtifactLatencies(blinkindex)):(r.Window(2)+ArtifactLatencies(blinkindex))); % extract data from the artifact channel for the window period
        matrixofVEOGiBlinks(blinkindex,:) = matrixofVEOGiBlinks(blinkindex,:) - matrixofVEOGiBlinks(blinkindex,1); %baseline correct
    end
    if (size(ArtifactLatencies,2) == 1)
        meanofVEOGiBlinks = matrixofVEOGiBlinks; % Compute mean eyeblink artifact
    else
        meanofVEOGiBlinks = mean(matrixofVEOGiBlinks); % Compute mean eyeblink artifact
    end
    
    % Populate Component Matrix From ICA activity - Number of ICA Components * Window Period * Number of Artifacts
    matrixofICAiBlinks3D = zeros(size(INEEG.icaweights,1), (r.Window(2)-r.Window(1))+1, size(ArtifactLatencies,2));
    for blinkindex = 1:size(ArtifactLatencies,2) % for each artifact
        tempmat = INEEG.icaact(:,(r.Window(1)+ArtifactLatencies(blinkindex)):(r.Window(2)+ArtifactLatencies(blinkindex))); % Extract data from icaact
        for compindex = 1:size(INEEG.icaweights,1) % for each component
            tempmat(compindex,:) = tempmat(compindex,:) - tempmat(compindex,1); % Baseline correct matrix
        end
        matrixofICAiBlinks3D(:,:,blinkindex) = tempmat; % load baseline corrected windowed data from icaact into matrix
    end
    % Average Across Eyeblinks - Number of ICA Components * Window Period
    if (size(ArtifactLatencies,2) == 1)
        matrixofICAiBlinks = matrixofICAiBlinks3D;
    else
        matrixofICAiBlinks = zeros(size(INEEG.icaweights,1), (r.Window(2)-r.Window(1))+1);
        for compindex = 1:size(INEEG.icaweights,1) % for each component
            tempmat = squeeze(matrixofICAiBlinks3D(compindex,:,:))'; % Extract data only for this compnent
            matrixofICAiBlinks(compindex,:) = mean(tempmat);
        end
    end
    
    % Populate Eyeblink Matrix From Raw EEG - Number of EEG Channels * Window Period * Number of Artifacts
    matrixofEEGiBlinks3D = zeros(INEEG.nbchan, (r.Window(2)-r.Window(1))+1, size(ArtifactLatencies,2));
    for blinkindex = 1:size(ArtifactLatencies,2) % for each artifact
        tempmat = INEEG.data(:,(r.Window(1)+ArtifactLatencies(blinkindex)):(r.Window(2)+ArtifactLatencies(blinkindex))); % Extract data from EEG.data
        for chanindex = 1:INEEG.nbchan % for each channel
            tempmat(chanindex,:) = tempmat(chanindex,:) - tempmat(chanindex,1); % Baseline correct matrix
        end
        matrixofEEGiBlinks3D(:,:,blinkindex) = tempmat; % load baseline corrected windowed data from EEG.data into matrix
    end
    % Average Across Eyeblinks - Number of EEG Channels * Window Period
    if (size(ArtifactLatencies,2) == 1)
        matrixofEEGiBlinks = matrixofEEGiBlinks3D;
    else
        matrixofEEGiBlinks = zeros(INEEG.nbchan, (r.Window(2)-r.Window(1))+1);
        for chanindex = 1:INEEG.nbchan % for each channel
            tempmat = squeeze(matrixofEEGiBlinks3D(chanindex,:,:))'; % extract data only for this channel
            matrixofEEGiBlinks(chanindex,:) = mean(tempmat);
        end
    end
    
    %% Step 3: Compute Metrics comparing the EOG blink with the ICA components
   
    % meanConvolution of EOG blinks with components
    ConvolutionP = NaN(1,size(INEEG.icaweights,1));
    matrixofICAConvolution = NaN(size(INEEG.icaweights,1),((r.Window(2)-r.Window(1))*2)+1);
    for compindex = 1:size(INEEG.icaweights,1) % for each ICA component
        matrixofICAConvolution(compindex,:) = conv(abs(meanofVEOGiBlinks(:)), abs(matrixofICAiBlinks(compindex,:)')); % convolution of eyeblink artifact and ica activity for each ica component
    end
    Convolution = mean(matrixofICAConvolution');% mean convolution of eyeblink artifact and ica activity for each ica component
    ConvolutionZ = adjustbynumberofsamples(trimzscore(Convolution)); % adjust Z score by number of channels
    sampleZ = trimzscore(ConvolutionZ); % Z score of adjusted convolutions - yes this is the z-score of a z-score but the adjustment takes into account regression towards the mean for larger channel numbers
    for cC = 1:numel(sampleZ) % Compute P value for each adjusted Z score
        %ConvolutionP(cC) = normcdf(-abs(sampleZ(cC)),0,1);
        ConvolutionP(cC) = 0.5 * erfc(-(-abs(sampleZ(cC))-0)/1*sqrt(2)); % Formula obtained from Matlab File Exchange - guassian_mixture_model.m by Matthew Roughan - Oct-28-2009
    end
    
    %% Step 4: Compute Metrics comparing the reduction in blink artifact when components are removed
    meanofEEGiBlinks = mean((matrixofEEGiBlinks)); % return the average rectified blink artifact collapsed across channels
    meanofEEGiBlinks = fastsmooth(meanofEEGiBlinks, floor(INEEG.srate/100), 2, 0); % Smooth the data to remove high frequency noise
    meanofEEGConvolution = mean(conv((meanofEEGiBlinks), (meanofEEGiBlinks))); % Convolve EEG artifact with itself as a baseline for computation of percent change
    PercentChangeP = NaN(1,size(INEEG.icaweights,1));
    meanEEGiBlinksafterICAremoval = NaN(size(INEEG.icaweights,1), (r.Window(2)-r.Window(1))+1);
    
    % To increase computational speed, restrict to only epochs containing the artifact
    INEEG.data = reshape(matrixofEEGiBlinks3D, size(matrixofEEGiBlinks3D,1), size(matrixofEEGiBlinks3D,2)*size(matrixofEEGiBlinks3D,3));
    INEEG.pnts = size(INEEG.data,2);
    INEEG.xmin = 0;
    INEEG.xmax = (INEEG.pnts-1)/INEEG.srate+INEEG.xmin;
    INEEG.times = INEEG.times(1:size(INEEG.data,2));
    INEEG.icaact = [];
    ORIGEEG = INEEG; % Save copy of original EEG set
    
    
        clear INEEG
        INEEG = ORIGEEG;
        [T, INEEG] = evalc('pop_subcomp( INEEG, r.ComponentArray, 0);'); % Remove component
        fprintf('.')
        % Populate Eyeblink Matrix From Raw EEG - Number of EEG Channels * Window Period * Number of Artifacts
        matrixofEEGiBlinks3DafterICAremoval = reshape(INEEG.data, size(matrixofEEGiBlinks3D,1), size(matrixofEEGiBlinks3D,2), size(matrixofEEGiBlinks3D,3));
        % Average Across Eyeblinks - Number of Channels * Window Period
        if (size(ArtifactLatencies,2) == 1)
            matrixofEEGiBlinksafterICAremoval = matrixofEEGiBlinks3DafterICAremoval;
        else
            matrixofEEGiBlinksafterICAremoval = zeros(INEEG.nbchan, (r.Window(2)-r.Window(1))+1);
            for chanindex = 1:INEEG.nbchan % for each channel
                tempmat = squeeze(matrixofEEGiBlinks3DafterICAremoval(chanindex,:,:))'; % extract data only for this channel
                matrixofEEGiBlinksafterICAremoval(chanindex,:) = mean(tempmat);
            end
        end
        tempmat = mean((matrixofEEGiBlinksafterICAremoval)); % return the average rectified blink artifact collapsed across channels following removal of ICA component
        meanEEGiBlinksafterICAremoval = fastsmooth(tempmat, floor(INEEG.srate/100), 2, 0); % Smooth the data to remove high frequency noise
        matrixofEEGConvolutionafterICAremoval = conv((meanofEEGiBlinks(:)), (meanEEGiBlinksafterICAremoval)); % Convolve original EEG artifact with EEG data following ICA removal
        % Compute Percent Change
        diff = (abs(meanofEEGConvolution)-abs(mean(matrixofEEGConvolutionafterICAremoval)));
        percentreduction = (abs(diff)/meanofEEGConvolution)*100;
%         if (percentreduction > 100)
%             
%             EEGvector = meanofEEGiBlinks;
%             Convolutionvector = (conv(abs(meanofEEGiBlinks), abs(meanofEEGiBlinks))); % Convolve EEG artifact with itself as a baseline for computation of percent change
%             %plot([EEGvector; meanEEGiBlinksafterICAremoval]')
%             plot([Convolutionvector; matrixofEEGConvolutionafterICAremoval]')
%             booler = 1;
%             error('overcorrect')
%         end
        
   
end
    
    