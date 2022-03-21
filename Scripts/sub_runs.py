#!/usr/bin/env python3

import sys
import array
import change_param
import change_awsom_param
import subprocess
import argparse
import os
import warnings
import re
import glob
import shutil
import shlex

# -----------------------------------------------------------------------------
def set_dict_params(list_params,NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations):

    for param in list_params:
        paramTmp = param.split('=')
        if paramTmp[0].lower()   == 'map':
            MAP  = paramTmp[1]
            if 'adapt' in MAP.lower():
                REALIZATIONS = [x for x in range(1,13)]
                TypeMap      = 'ADAPT'
            elif 'gong' in MAP.lower():
                REALIZATIONS = [1]
                TypeMap      = 'GONG'
            else:
                raise ValueError(MAP, ': unknown map type.')
            if not strRealizations.strip():
                ListStrRealizations = [str(iRealztion)
                                       for iRealztion in REALIZATIONS]
                strRealizations = ",".join(ListStrRealizations)
        elif paramTmp[0].lower() == 'pfss':
            PFSS = paramTmp[1]
        elif paramTmp[0].lower() == 'time':
            TIME = paramTmp[1]
        elif paramTmp[0].lower() == 'model':
            MODEL= paramTmp[1]
        elif paramTmp[0].lower() == 'scheme':
            SCHEME = int(paramTmp[1])
        elif paramTmp[0].lower() == 'param':
            PARAM  = paramTmp[1]
        elif paramTmp[0].lower() == 'realization':
            strTmp  = paramTmp[1][1:-1]
            ListRealizationTmp = strTmp.split(',')
            REALIZATIONS = []
            for StrRealiaztion in ListRealizationTmp:
                try:
                    # try to convert it to an integer
                    Realization = int(StrRealiaztion)
                    REALIZATIONS.append(Realization)
                except:
                    # cannot convert to an integer as there is '-'
                    ListTmp = StrRealiaztion.split('-')
                    try:
                        REALIZATIONS.extend([x for x in range(int(ListTmp[0]),
                                                              int(ListTmp[1])+1)])
                    except Exception as error:
                        raise TypeError(error," wrong format: could only contain "
                                        + "integer, ',' and '-'.")
            ListStrRealizations = [str(iRealztion)
                                   for iRealztion in REALIZATIONS]
            strRealizations = ",".join(ListStrRealizations)
        elif paramTmp[0].lower() == 'realizations' or paramTmp[0].lower() == 'restartdir':
            continue
        elif paramTmp[0] == 'add' or paramTmp[0] == 'rm':
            if not paramTmp[0] in NewParam.keys():
                NewParam[paramTmp[0]] = paramTmp[1]
            else:
                NewParam[paramTmp[0]] = NewParam[paramTmp[0]]+','+paramTmp[1]
        elif paramTmp[1][0] == '[' and paramTmp[1][-1] == ']':
            if not 'replace' in NewParam.keys():
                NewParam['replace'] = {paramTmp[0]:paramTmp[1][1:-1]}
            else:
                NewParam['replace'][paramTmp[0]] = paramTmp[1][1:-1]
        else:
            if not 'change' in NewParam.keys():
                NewParam['change']  = {paramTmp[0]:paramTmp[1]}
            else:
                NewParam['change'][paramTmp[0]] = paramTmp[1]


    # need to turn on these two commands if BrFactor and BrMin are used
    if 'BrFactor' in NewParam['change'].keys() or 'BrMin' in NewParam['change'].keys():
        if 'add' in NewParam.keys():
            NewParam['add']=NewParam['add']+',FACTORB0,CHANGEWEAKFIELD'
        else:
            NewParam['add']='FACTORB0,CHANGEWEAKFIELD'

    # well, for 5th order scheme, there is a 0.02 thick layer above rMin for AWSoM-R
    if 'rMin_AWSoMR' in NewParam['change'].keys():
        NewParam['change']['rMaxLayer_AWSoMR'] = float(NewParam['change']['rMin_AWSoMR']) + 0.02

    return NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations

# -----------------------------------------------------------------------------
def set_restart_params(RestartDirIn,NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations):
    # use patten search to find, RestartDirIn does not need to be the full name
    filenameKeyparams = glob.glob('Results/' + RestartDirIn+'*/key_params.txt')[0]
    with open(filenameKeyparams, 'r') as file_keyparams:
        lines_keyparams = list(file_keyparams)

    for iLine, line in enumerate(lines_keyparams):
        # remove the /n in the .txt file...
        lines_keyparams[iLine] = line.strip()
        # the string for the realizations is saved...
        if 'realizations' in line.lower():
            strRealizationsRestart = line.strip().split('=')[1]
        else:
            strRealizationsRestart = ''
        if 'restartdir' in line.lower():
            # remove /n with strip() and then RestartDir is the second element after split
            RestartDirLocal  = line.strip().split('=')[1]
            NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations = \
                set_restart_params(RestartDirLocal, NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations)

    # set the params based on the key_params.txt
    NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations = \
        set_dict_params(lines_keyparams,NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations)

    if strRealizationsRestart.strip():
        strRealizations=strRealizationsRestart

    return NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations
    
# -----------------------------------------------------------------------------
if __name__ == '__main__':

    PROG_DESCRIPTION = ('Script to submit jobs selected from a file.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-f', '--filename',
                            help='(default:param_list.txt)',
                            type=str, default='param_list.txt')
    ARG_PARSER.add_argument('-c', '--DoCompile',
                            help='(default: 1)'
                            + 'Use if you want to re-install and compile '
                            + 'the code.', 
                            type=int, default=1)
    ARG_PARSER.add_argument('-l', '--DoLink',
                            help='(default: 1)'
                            + 'Use if you want to link the restart '
                            + 'files only.',
                            type=int, default=0)
    ARG_PARSER.add_argument('-m', '--DoUseMarker',
                            help='(default: 1)'
                            + 'Use if you want to use the marker ^ for'
                            + 'changing the PARAM.in file.',
                            type=int, default=1)
    ARG_PARSER.add_argument('-r', '--DoSubRun',
                            help='(default: 1)'
                            + 'Use if you want to submit runs',
                            type=int, default=1)
    ARG_PARSER.add_argument('-t', '--ThresholdBrPoynting',
                            help='(default: -1.0)'
                            + 'Use if you want to set the Threshold for'
                            + 'BrFactor*PoyntingFlux',
                            type=float, default=-1.0)
    ARGS = ARG_PARSER.parse_args()

    # whether to reinstall the code
    DoInstall = True

    with open(ARGS.filename, 'rt') as events:
        lines = list(events)

    for iLine, line in enumerate(lines):
        if 'selected run IDs' in line[0:16]:
            iSelectedID=iLine
        if '#START' in line[0:6]:
            iParamStart=iLine+2
            break
        
    # find the location of =
    iChar  = lines[iSelectedID].find('=')

    # any character after = is considered to be the string containing 
    # run IDs.
    StrRunIDs = lines[iSelectedID][iChar+1:]

    # split the string
    List_StrRunIDs = StrRunIDs.split(',')

    RunIDs = []

    # loop through List_StrRunIDs to get the list of run IDs in an integer list
    for StrRunID in List_StrRunIDs:
        try:
            # try to convert it to an integer
            RunID = int(StrRunID)
            RunIDs.append(RunID)
        except:
            # cannot convert to an integer as there is '-'
            ListTmp = StrRunID.split('-')
            try:
                RunIDs.extend([x for x in range(int(ListTmp[0]),
                                                int(ListTmp[1])+1)])
            except Exception as error:
                raise TypeError(error," wrong format: could only contain "
                                + "integer, ',' and '-'.")

    params_I =[]

    for iLine, line in enumerate(lines[iParamStart:]):
        if line.strip():
            # preserve the white space within ''
            param_now = shlex.split(line.strip())
            # this will preserve the white space within []
            # param_now    = re.split(r'\s+(?![^[\]]*])', line.strip())

            # the first element is always an inter representing the run ID.
            param_now[0] = int(param_now[0])
            params_I.append(param_now)

    for iID, params in enumerate(params_I):
        # if the run ID is found in the selected run ID.

        if params[0] in RunIDs:
            RunID = params[0]

            # reset all the default values
            MAP   = 'NoMap'
            PFSS  = 'HARMONICS'
            TIME  = 'MapTime'
            MODEL = 'AWSoM'
            PARAM = 'Default'
            SCHEME= 2
            DoRestart = False

            NewParam        = {}
            strRealizations = ''

            # check whether restartdir exists, if yes, set the params first.
            for param in params[1:]:
                if 'restartdir=' in param.lower():
                    DoRestart   = True
                    # remove /n with strip() and then RestartDir is the second element after split
                    RestartDir  = param.strip().split('=')[1]
                    NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations = \
                        set_restart_params(RestartDir,NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations)

            # the actual param starts from the 2nd element
            NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations = \
                set_dict_params(params[1:],NewParam,MAP,PFSS,TIME,MODEL,PARAM,SCHEME,strRealizations)

            if ARGS.ThresholdBrPoynting > 0:
                BrFactor_local     = float(NewParam['change']['BrFactor'])
                PoyntingFlux_local = float(NewParam['change']['PoyntingFluxPerBSi'])
                if BrFactor_local*PoyntingFlux_local > ARGS.ThresholdBrPoynting:
                    warnings.warn('For run ID: '+str(RunID).zfill(3) + '\n'
                                  +'BrFactor           ='+str(BrFactor_local)           + '\n'
                                  +'PoyntingFluxPerBSi ='+str(PoyntingFlux_local) + '\n'
                                  +'BrFactor*PoyntingFluxPerBSi ='+str(BrFactor_local*PoyntingFlux_local) + '\n'
                                  +'BrFactor*PoyntingFluxPerBSi >'+str(ARGS.ThresholdBrPoynting))
                    continue

            SIMDIR = ('run' + str(RunID).zfill(3) + '_' + MODEL)

            if DoRestart:
                SIMDIR = SIMDIR+'_restart_'+RestartDir.replace('/','_')

            # if ARGS.DoLink, link the associated IH restart files and continue the loop.
            if ARGS.DoLink:
                # check if the SIMDIR exists in Results
                if os.path.isdir('Results/'+SIMDIR):
                    for dirTmp in os.listdir('Results/'+SIMDIR):
                        if os.path.isdir(os.path.join('Results/'+SIMDIR, dirTmp)):
                            linkSrc = os.path.join(os.getcwd(), 'Results/'+RestartDir, dirTmp, 'RESTART/IH')
                            linkDst = os.path.join(os.getcwd(), 'Results/'+SIMDIR,     dirTmp, 'RESTART/IH')
                            # check whether the IH restart files is linked or not, if yes, remove the link first.
                            if os.path.islink(linkDst):
                                os.unlink(linkDst)
                            os.symlink(linkSrc, linkDst)
                            print('Created link from '+ linkSrc  + ' to ' + linkDst)
                else:
                    print('Results/'+SIMDIR+' does not exist!!!!')
                continue

            strPfssMake  ='PFSS='+PFSS
            strModelMake ='MODEL='+MODEL
            strParamMake ='PARAM='+PARAM

            strRealizationsMake = 'REALIZATIONS='+strRealizations

            strSimDirMake = 'SIMDIR='+SIMDIR

            # Compile the code if needed. AWSoM and AWSoM-R could not be 
            # selected at the same time
            if not MODEL in ['AWSoM','AWSoMR','AWSoM2T','AWSoMR_SCIHOHSP']:
                warnings.warn(MODEL+' may not be supported.')

            # If the corresponding MODEL.exe does not exist, need to re-compile the code.
            # If it exists, do not change ARGS.DoCompile, which default is 1 (to re-compile
            # the code for the first time when running the event list). However, the user
            # may still set it to 0, in which case the code will not be re-compiled.
            if not os.path.isfile('SWMF/bin/'+MODEL+'.exe'):
                ARGS.DoCompile = 1

            if ARGS.DoCompile:
                print('--------------------')
                print('working on '+MODEL)
                print('--------------------')
                if DoInstall:
                    subprocess.call('make compile DOINSTALL=T MODEL='+MODEL, shell=True)
                else:
                    subprocess.call('make compile DOINSTALL=F MODEL='+MODEL, shell=True)
                DoInstall = False
            else:
                print('--------------------')
                print('no need to re-compile model = '+MODEL)
                print('--------------------')

            # The code is compiled already, may not need to re-compile next time.
            ARGS.DoCompile = 0

            # backup previous results if needed
            strbackup_run = 'make backup_run ' + strSimDirMake
            subprocess.call(strbackup_run, shell=True)

            # copy the PARAM.in, HARMONICS.in and FDIPS.in files
            strCopy_param = 'make copy_param ' + strModelMake + ' ' + strParamMake
            subprocess.call(strCopy_param, shell=True)

            # change the PARAM.in file
            change_awsom_param.change_param_local(time=TIME, map=MAP, pfss=PFSS, 
                                                  new_params=NewParam,scheme=SCHEME,
                                                  DoUseMarker=ARGS.DoUseMarker)
            
            # make run directories
            strRun_dir = ('make rundir_realizations ' + strSimDirMake + ' '
                          + strRealizationsMake + ' ' + strPfssMake + ' MODEL=' + MODEL)
            subprocess.call(strRun_dir, shell=True)

            file_output = open(SIMDIR+'/key_params.txt', 'w')
            file_output.write('model='+MODEL+'\n')
            for param in params[1:]:
                if not 'realization' in param and not 'model' in param:
                    file_output.write(str(param)+'\n')
            file_output.write('realizations='+strRealizations+'\n')
            file_output.close()

            if DoRestart:
                listRealizations = strRealizations.split(',')
                # only consider the current realization list
                for iRealization in listRealizations:
                    path_swmfsolar     = os.getcwd()
                    StrRealizationLocal=str(int(iRealization)).zfill(2)
                    # go to the realiztion dir in SIMDIR
                    os.chdir(SIMDIR+'/run'+StrRealizationLocal)
                    RestartDirFull = glob.glob(path_swmfsolar + '/Results/' + RestartDir
                                               + '*/run' + StrRealizationLocal+'/RESTART')
                    if len(RestartDirFull):
                        strLinkRestart = './Restart.pl -v -i ' + RestartDirFull[0]
                        subprocess.call(strLinkRestart, shell=True)
                        if os.path.exists(RestartDirFull[0]+'/../fdips_bxyz.out'):
                            shutil.copy2(RestartDirFull[0] +'/../fdips_bxyz.out', './SC/')
                        if os.path.exists(RestartDirFull[0]+'/../harmonics_bxyz.out'):
                            shutil.copy2(RestartDirFull[0] +'/../harmonics_bxyz.out', './SC/')
                    # go back to the SWMFSOLAR dir
                    os.chdir(path_swmfsolar)

            # clean the PARAM.in, HARMONICS.in, FDIPS.in and map_*.out files 
            # in the SWMFSOLAR folder
            subprocess.call('make clean_rundir_tmp', shell=True)

            # submit runs
            if ARGS.DoSubRun:
                strRun = ('make run ' + strPfssMake + ' ' + strSimDirMake + ' '
                          + strRealizationsMake + ' JOBNAME=r'+str(RunID).zfill(2)+'_')
                subprocess.call(strRun, shell=True)
