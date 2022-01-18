#!/usr/bin/env python3

import argparse
import glob

# -----------------------------------------------------------------------------
if __name__ == '__main__':

    PROG_DESCRIPTION = ('Script to submit jobs selected from a file.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-i', '--IDs',
                            help='If it is empty, then all the run*, '+
                            '(default:)', 
                            type=str, default='')
    ARG_PARSER.add_argument('-n', '--nodes',
                            help='The number of nodes per run dir, '+
                            '(default:40)',
                            type=int, default=40)
    ARG_PARSER.add_argument('-s', '--strJob',
                            help='The String for the job info, '+
                            '(default:bundle1)',
                            type=str, default='bundle1')
    ARGS = ARG_PARSER.parse_args()

    RunIDs = []

    ## header for the job script
    StrsHeader = ['#!/bin/bash','',
                 '#SBATCH -J '+ARGS.strJob,
                 '#SBATCH -o '+ARGS.strJob+'.o%j',
                 '#SBATCH -e '+ARGS.strJob+'.e%j',
                 '#SBATCH --tasks-per-node 56',
                 '#SBATCH -t 24:00:00',
                 '#SBATCH -A BCS21001',
                 ]

    # get the run IDs if ARGS.IDs is not empty
    if ARGS.IDs.strip():
        # split the string
        List_StrRunIDs = ARGS.IDs.split(',')

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

    # get the dir list
    if len(RunIDs):
        SIMDirs = []
        for iRun in RunIDs:
            dirTmp = glob.glob('run'+str(iRun).zfill(3)+'*/run*')
            if len(dirTmp):
                SIMDirs.extend(dirTmp)
    else:
        SIMDirs = glob.glob('run*/run*')

    with open('job.'+ARGS.strJob, 'w') as file_out:
        for line in StrsHeader:
            file_out.write(line+'\n')

        # Total number of nodes
        nodesTotal = ARGS.nodes*len(SIMDirs)
        if nodesTotal > 512:
            file_out.write('#SBATCH -p large\n')
        else:
            file_out.write('#SBATCH -p normal\n')
        file_out.write('#SBATCH -N '+str(nodesTotal)+'\n\n\n')
        
        iRunLocal = 0
        for iDir in SIMDirs:
            file_out.write('cd '+iDir+'\n')
            offset = iRunLocal * ARGS.nodes*56
            file_out.write('ibrun -o '+str(offset)   
                           + ' -n 1 ./PostProc.pl -r=180 -n=30 >& PostProc.log &\n')
            file_out.write('ibrun -o '+str(offset+56)
                           +' -n '+str((ARGS.nodes-1)*56)+' SWMF.exe  > runlog_`date +%y%m%d%H%M` &\n')
            file_out.write('cd ../../\n')
            iRunLocal += 1

        file_out.write('\n\nsleep 180\n\n')

        if ARGS.IDs.strip():
            file_out.write('ibrun -o 0 -n 1 Scripts/watch_runlog.py -i '+ARGS.IDs+' >& log_watch_runlog_`date +%y%m%d%H%M%S` &\n')
        else:
            file_out.write('ibrun -o 0 -n 1 Scripts/watch_runlog.py >& log_watch_runlog_`date +%y%m%d%H%M%S` &\n')
        file_out.write('\nwait\n')
