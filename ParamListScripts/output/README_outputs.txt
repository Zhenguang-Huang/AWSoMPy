Filename                                                        Type                     Description
param_list_CR*_CME_validation_study_2024_06_19.txt | CME runs |(for manuscript) 20 CME runs for CR2107, CR2134, CR2142. (in total, we will have 6 events on which the DA methodology is applied). Modified versions of `param_list_CR*_validation_study_1au_2024_03_08.txt`. (Pending) - replace restartdir argument by whatever background is selected.

param_list_CR2107_2134_2142_backgrounds_validation_study_2024_06_19.txt | Backgrounds |(for manuscript) Redoing backgrounds for CR2107, CR2134 and CR2142. Once a single background is finalized for each, do 20 CME runs for each. (in total, we will have 6 events on which the DA methodology is applied). This is a modified version of `/data/Simulations/zghuang/SWQU/solar/code_stable/CME/Backgrounds_AWSoM3T` with 121-123 removed (used previous maps), all parameters like LonCME_min, max etc. correctly specified and AWSoM2T instead of AWSoM.

param_list_CR2192_CME_validation_study_2024_03_14.txt | CME runs | (for manuscript) Additional 120 CME runs where apart from BStrength and iHelicity, the OrientationCme and ApexHeight are also varied. All conditioned on a single background.

param_list_CR*_validation_study_1au_2024_03_08.txt | Backgrounds and CME runs | Redoing a single background for each of CR2107, CR2134 and CR2142 with latest code version, AWSoM2T, time, CME Box provided. 20 CME runs are done for each background once background results are verified (obsolete now)

param_list_CR*_backgrounds_validation_study_2024_02_05.txt | (for manuscript) Background and CME runs | Redoing backgrounds for the validation runs of three events (CR2154, CR2161 and CR2192) with the latest version of the code - timestep fixes etc. 10 best backgrounds are used for each event and CME runs are restarted based on the top background from each|

param_list_CR*_validation_study_1au_2023_09_20.txt         | CME Runs           | 24 Validation CME Runs each for the DA manuscript of three events - CR2154, CR2161, CR2192. Will be obsolete when fresh runs are performed.                            |