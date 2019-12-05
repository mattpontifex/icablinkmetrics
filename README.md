icablinkmetrics
==============

An EEGLAB extension that is designed for automated/semi-automated selection of ICA components associated
with eyeblink artifact using time-domain measures. The toolbox is based on the premises that 1) an ICA
component associated with eye blinks should be more related to the recorded eye blink activity than other
ICA components, and 2) removal of the ICA component associated with eye blinks should reduce the eye blink
artifact present within the EEG following back projection.

Other than the EEG input, the only required input for the function is specification of the channel that
exhibits the artifact (in most cases the VEOG electrode). This can either be stored within the EEG.data
matrix or within EEG.skipchannels. It will then identify eye-blinks within the channel to be used for
computation of the metrics listed below. If you are not sure what channel to choose, you can let the
function determine the channel where the artifact maximally presents but this does slow the function down.


Background
------------
The premise and validation of this approach is detailed in: Pontifex, M. B., Miskovic, V., & Laszlo, S. 
(2017). Evaluating the efficacy of fully automated approaches for the selection of eyeblink ICA components.
Psychophysiology, 54, 780-791.
http://education.msu.edu/kin/hbcl/_articles/Pontifex_2017_EvaluatingTheEfficacyOf.pdf

Installation
------------
To use these functions, click the "Clone or download" button on the right and then select "Download ZIP".
Once the file has downloaded, unzip the package and then copy the icablinkmetricsX.X file into the EEGLAB plugins
folder.

Once you restart EEGLAB, under Tools you should now see "Compute icablinkmetrics" listed as an option.
