#!/usr/bin/env python3

import argparse
import glob
import numpy as np
import subprocess

# -----------------------------------------------------------------------------
def sub_one_bundle_job(SIMDirs, strJobName, nNodes):

    ## header for the job script
    list_strHeader = ['#!/bin/bash','',
                      '#SBATCH -J '+strJobName,
                      '#SBATCH -o '+strJobName+'.o%j',
                      '#SBATCH -e '+strJobName+'.e%j',
                      '#SBATCH --tasks-per-node 56',
                      '#SBATCH -t 24:00:00',
                      '#SBATCH -A BCS21001',
                  ]

    if len(SIMDirs) == 0:
        return

    with open('job.'+strJobName, 'w') as file_out:
        for line in list_strHeader:
            file_out.write(line+'\n')

        # Total number of nodes
        nodesTotal = nNodes*len(SIMDirs)
        if nodesTotal > 512:
            file_out.write('#SBATCH -p large\n')
        else:
            file_out.write('#SBATCH -p normal\n')
        file_out.write('#SBATCH -N '+str(nodesTotal)+'\n\n\n')

        # for stable connection
        file_out.write('export UCX_TLS="knem,rc"\n\n')

        iRunLocal = 0
        for iDir in SIMDirs:
            file_out.write('sleep 5\n')
            file_out.write('cd '+iDir+'\n')
            offset = iRunLocal * nNodes*56
            file_out.write('ibrun -o '+str(offset)
                           + ' -n 1 ./PostProc.pl -r=180 -n=1 >& PostProc.log &\n')
            file_out.write('( ibrun -o '+str(offset+56)
                           +' -n '+str((nNodes-1)*56)+' SWMF.exe > runlog_`date +%y%m%d%H%M` ; touch PostProc.STOP ) &\n')
            file_out.write('cd ../../\n')
            iRunLocal += 1

        file_out.write('\nwait\n')

    subprocess.call('sbatch job.'+strJobName, shell=True)

# -----------------------------------------------------------------------------
if __name__ == '__main__':

    PROG_DESCRIPTION = ('Script to write and submit bundle jobs.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-i', '--IDs',
                            help='A string for the run IDs, similar to'  +
                            'the format in the param_list.txt. If it is' +
                            'not specified, then all the run*.' +
                            '(default:)',
                            type=str, default='')
    ARG_PARSER.add_argument('-n', '--nodes',
                            help='The number of nodes per run dir, '+
                            '(default:40)',
                            type=int, default=40)
    ARG_PARSER.add_argument('-max', '--MaxNodes',
                            help='The maximum number of nodes per job script, '+
                            '(default:512)',
                            type=int, default=512)
    ARG_PARSER.add_argument('-s', '--strJob',
                            help='The String for the job info, '+
                            '(default:bundle)',
                            type=str, default='bundle')
    ARGS = ARG_PARSER.parse_args()

    list_RunIDs = []
    SIMDirs     = []

    # get the run IDs if ARGS.IDs is not empty
    if ARGS.IDs.strip():
        # split the string
        list_str_RunIDs = ARGS.IDs.split(',')

        # loop through list_str_RunIDs to get the list of run IDs in an integer list
        for StrRunID in list_str_RunIDs:
            try:
                # try to convert it to an integer
                RunID = int(StrRunID)
                list_RunIDs.append(RunID)
            except:     # cannot convert to an integer as there is '-'
                ListTmp = StrRunID.split('-')
                try:
                    list_RunIDs.extend([x for x in range(int(ListTmp[0]),
                                                         int(ListTmp[1])+1)])
                except Exception as error:
                    raise TypeError(error," wrong format: could only contain "
                                    + "integer, ',' and '-'.")

        for iRun in list_RunIDs:
            dirTmp = glob.glob('run'+str(iRun).zfill(3)+'*/run*')
            if len(dirTmp):
                dirTmp = sorted(dirTmp)
                SIMDirs.extend(dirTmp)
    else:
        SIMDirs = glob.glob('run*/run*')
        SIMDirs = sorted(SIMDirs)

    # see if it fits into only one job script
    if (len(SIMDirs)*ARGS.nodes)/ARGS.MaxNodes > 1:
        # number of runs per job script
        nRunPerScript = np.floor(ARGS.MaxNodes/ARGS.nodes)

        # number of job scripts
        nScript = np.floor(len(SIMDirs)/nRunPerScript) + 1

        iScript = 0
        while iScript < nScript:
            # the the list of IDs within the script
            iStart = int( iScript   *nRunPerScript)
            iEnd   = int((iScript+1)*nRunPerScript)
            SIMDirsLocal = SIMDirs[iStart:iEnd]

            sub_one_bundle_job(SIMDirsLocal, ARGS.strJob+str(iScript), ARGS.nodes)
            iScript +=  1
    else:
        sub_one_bundle_job(SIMDirs, ARGS.strJob, ARGS.nodes)
