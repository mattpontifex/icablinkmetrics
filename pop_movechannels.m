function [EEG, com] = pop_movechannels(EEG)

    if isobject(EEG) % eegobj
        disp('Error in pop_movechannels(): This function is not designed to work with the EEG object.')
        beep
    else
        if isempty(EEG)
            disp('Error in pop_movechannels(): This function cannot run on an empty EEG dataset.')
            beep
        else
            if isempty(EEG.data)
                disp('Error in pop_movechannels(): This function cannot run on an empty EEG dataset.')
                beep
            else

               cb_chansel1 = 'tmpchanlocs = EEG(1).chanlocs; [tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on''); set(findobj(gcbf, ''tag'', ''EEGDATA''   ), ''string'',tmpval); clear tmpchanlocs tmp tmpval';
               cb_chansel2 = 'tmpchanlocs = EEG.etc.skipchannels.labels; [tmp tmpval] = pop_chansel(tmpchanlocs, ''withindex'', ''on''); set(findobj(gcbf, ''tag'', ''EEGSKIP''   ), ''string'',tmpval); clear tmpchanlocs tmp tmpval';
                
               % Check to see if skipped channels are available
               enabSKIP = 'off';
               enabskipmess = 'no channels to restore';
               try
                   tmpchanlocs = EEG.etc.skipchannels.labels;
                   if ~(isempty(tmpchanlocs))
                        enabSKIP = 'on';
                        enabskipmess = '';
                   end
               catch
                   boolerr = 1;
               end
                
                g1 = [0.5 0.5 ];
                g2 = [0.05 0.475 0.475];
                g3 = [0.5 0.5 0.2];
                s1 = [1];
                geometry = { s1 g3 s1 s1 g3 s1};
                uilist = { ...
                      { 'Style', 'text', 'string', 'Remove Channel from EEG.data'} ...
                      ...
                      { 'Style', 'text', 'string', 'Select channels to temporarily remove from EEG.data:'} ...
                      { 'Style', 'edit', 'string', '' 'tag' 'EEGDATA' } ...
                      { 'Style' 'pushbutton' 'string' '...' 'callback' cb_chansel1 'tag' 'EEGDATArefbr' } ...
                      ...
                      { } ...
                      ...
                      { 'Style', 'text', 'string', 'Restore Channel to EEG.data'} ...
                      ...
                      { 'Style', 'text', 'string', 'Select channels to restore to EEG.data:'} ...
                      { 'Style', 'edit', 'string', enabskipmess 'tag' 'EEGSKIP', 'enable' enabSKIP } ...
                      { 'Style' 'pushbutton' 'string' '...' 'callback' cb_chansel2 'tag' 'refbr', 'enable' enabSKIP } ...
                      ...
                      { } ...
                      ...
                  };

                  [ tmp1 tmp2 strhalt structout ] = inputgui( geometry, uilist, 'pophelp(''movechannels'');', 'Relocate Referential/Bipolar Channel -- pop_movechannels');
                  if ~isempty(structout)
                      
                      if ~(isempty(structout.EEGDATA) | strcmpi(structout.EEGDATA, '') ) % a channel was selected for removal
                          
                          skipchanlist = textscan(structout.EEGDATA,'%s','Delimiter',' ');
                          skipchanlist = skipchanlist{1}';
                          com = sprintf('%s = movechannels(%s, ''Direction'', ''Remove'', ''Channels'', %s);', inputname(1), inputname(1), makecellarraystr(skipchanlist));
                          eval(com);
                          disp(sprintf('\nEquivalent Code:\n\t%s', com));
                          
                      end
                      if ~(isempty(structout.EEGSKIP) | strcmpi(structout.EEGSKIP, '') | strcmpi(structout.EEGSKIP,'no channels to restore') ) % a channel was selected for restoration
                          
                          skipchanlist = textscan(structout.EEGSKIP,'%s','Delimiter',' ');
                          skipchanlist = skipchanlist{1}';
                          com = sprintf('%s = movechannels(%s, ''Direction'', ''Restore'', ''Channels'', %s);', inputname(1), inputname(1), makecellarraystr(skipchanlist));
                          eval(com);
                          disp(sprintf('\nEquivalent Code:\n\t%s', com));
                      end
                  else
                      EEG = EEG;
                      com = '';
                  end
            end
        end
    end
end