#!/usr/bin/env python3

import sys
import array
import change_param
import subprocess
import argparse

if __name__ == '__main__':

    PROG_DESCRIPTION = ('Script to submit jobs selected from a file.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-f', '--filename',
                            help='(default:event_list.txt)',
                            type=str, default='event_list.txt')
    ARG_PARSER.add_argument('-c', '--DoCompile',
                            help='(default: 1)'
                            + 'Use if you want to re-install and compile '
                            + 'the code.', 
                            type=int, default=1)
    ARG_PARSER.add_argument('-m', '--DoUseMarker',
                            help='(default: 1)'
                            + 'Use if you want to use the marker ^ for'
                            + 'changing the PARAM.in file.',
                            type=int, default=1)
    ARG_PARSER.add_argument('-l', '--DoUseLink',
                            help='(default: 1)'
                            + 'Change if you want to use link for '
                            + 'SWMF.exe',
                            type=str, default='F')
    ARGS = ARG_PARSER.parse_args()

    # whether the code was compiled before
    ModelCompiled = None

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
            param_now    = line.split()

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
            SCHEME= 2

            NewParam = {}

            # the actual param starts from the 2nd element
            for param in params[1:]:
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
                    ListStrRealizatinos = [str(iRealztion) 
                                           for iRealztion in REALIZATIONS]
                    StrRealizatinos = ",".join(ListStrRealizatinos)
                elif paramTmp[0].lower() == 'pfss':
                    PFSS = paramTmp[1]
                elif paramTmp[0].lower() == 'time':
                    TIME = paramTmp[1]
                elif paramTmp[0].lower() == 'model':
                    MODEL= paramTmp[1]
                elif paramTmp[0].lower() == 'scheme':
                    SCHEME = int(paramTmp[1])
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
                    ListStrRealizatinos = [str(iRealztion)
                                           for iRealztion in REALIZATIONS]
                    StrRealizatinos = ",".join(ListStrRealizatinos)
                else:
                    NewParam[paramTmp[0]] = paramTmp[1]

            # need to turn on these two commands if BrFactor and BrMin are used
            if 'BrFactor' in NewParam.keys() or 'BrMin' in NewParam.keys():
                if 'add' in NewParam.keys():
                    NewParam['add']=NewParam['add']+',FACTORB0,CHANGEWEAKFIELD'
                else:
                    NewParam['add']='FACTORB0,CHANGEWEAKFIELD'

            # well, for 5th order scheme, there is a 0.02 thick layer above rMin for AWSoM-R
            if 'rMin_AWSoMR' in NewParam.keys():
                NewParam['rMaxLayer_AWSoMR'] = float(NewParam['rMin_AWSoMR']) + 0.02

            SIMDIR = ('run' + str(RunID).zfill(3) + '_' + MODEL)

            strMAP  ='MAP='+MAP
            strPFSS ='PFSS='+PFSS
            strTime ='TIME='+TIME
            strModel='MODEL='+MODEL

            strRealizations = 'REALIZATIONS='+StrRealizatinos

            strSIMDIR = 'SIMDIR='+SIMDIR

            # Compile the code if needed. AWSoM and AWSoM-R could not be 
            # selected at the same time
            if not MODEL in ['AWSoM','AWSoMR','AWSoM2T']:
                raise ValueError(MODEL, ': un-supported model.')

            # If ModelCompiled is set and not equal to the current model,
            # compile the code. AWSoM2T and AWSoMR both use isotropic
            # while AWSoM uses anisotropic.
            if ModelCompiled != None and ModelCompiled != MODEL:
                if MODEL in ['AWSoMR','AWSoM2T'] and ModelCompiled in ['AWSoMR','AWSoM2T']:
                    ARGS.DoCompile = 0
                else:
                    ARGS.DoCompile = 1

            if ARGS.DoCompile:
                print('--------------------')
                print('working on '+MODEL)
                print('--------------------')
                subprocess.call('make compile MODEL='+MODEL, shell=True)
            else:
                print('--------------------')
                print('ModelCompiled, MODEL = ',ModelCompiled,MODEL)
                print('No need to re-compile')
                print('--------------------')

            # The code is compiled already, may not need to re-compile next time.
            ARGS.DoCompile = 0
            ModelCompiled = MODEL

            # backup previous results if needed
            strbackup_run = 'make backup_run ' + strSIMDIR
            subprocess.call(strbackup_run, shell=True)

            # copy the PARAM.in, HARMONICS.in and FDIPS.in files
            strCopy_param = 'make copy_param ' + strModel
            subprocess.call(strCopy_param, shell=True)

            # change the PARAM.in file
            change_param.change_param_func(time=TIME, map=MAP, pfss=PFSS, 
                                           new_params=NewParam,scheme=SCHEME,
                                           DoUseMarker=ARGS.DoUseMarker)
            
            # make run directories
            strRun_dir = ('make rundir_realizations ' + strSIMDIR + ' '
                          + strRealizations + ' ' + strPFSS
                          + ' USELINK='+ARGS.filename)
            subprocess.call(strRun_dir, shell=True)

            file_output = open(SIMDIR+'/key_params.txt', 'w')
            file_output.write('model='+MODEL+'\n')
            for param in params[1:]:
                if not 'realization' in param and not 'model' in param:
                    file_output.write(str(param)+'\n')
            file_output.write('realizations='+StrRealizatinos+'\n')
            file_output.close()

            # clean the PARAM.in, HARMONICS.in, FDIPS.in and map_*.out files 
            # in the SWMFSOLAR folder
            subprocess.call('make clean_rundir_tmp', shell=True)

            # submit runs
            strRun = ('make run ' + strPFSS + ' ' + strSIMDIR + ' ' 
                      + strRealizations + ' JOBNAME=r'+str(RunID).zfill(2)+'_')
            subprocess.call(strRun, shell=True)
