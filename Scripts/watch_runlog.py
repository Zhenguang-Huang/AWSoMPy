#!/usr/bin/env python3

import argparse
import glob
import time
import os
from datetime import datetime as dt

# -----------------------------------------------------------------------------
if __name__ == '__main__':

    PROG_DESCRIPTION = ('Script to submit jobs selected from a file.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-i', '--IDs',
                            help='If it is empty, then all the run*, '+
                            '(default:)', 
                            type=str, default='')
    ARGS = ARG_PARSER.parse_args()

    RunIDs = []

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

    # the last modified time for the runlog in the corresponding dir
    list_time   = [0]*len(SIMDirs)
    # whether PostProc.STOP is touched for the corresponding dir
    list_DoStop = [False]*len(SIMDirs)

    while False in list_DoStop:
        print('working on IDs '+ARGS.IDs+ ' at '+dt.now().strftime("%Y-%m-%d %H:%M:%S"))
        for i, iDir in enumerate(SIMDirs):
            # PostProc.STOP already exists, skip
            if os.path.exists(iDir+'/PostProc.STOP'):
                list_DoStop[i] = True
                continue

            # find all the runlog files
            list_runlog = glob.glob(iDir+'/runlog*')
            # only consider the last created runlog file
            runlog_tmp = sorted(list_runlog)[-1]
            # get the modified time for the runlog
            time_now   = os.path.getmtime(runlog_tmp)

            if list_time[i] == 0:
                list_time[i] = time_now
            else:
                if time_now == list_time[i]:
                    try:
                        os.utime(iDir+'/PostProc.STOP',None)
                    except OSError:
                        open(iDir+'/PostProc.STOP','a').close()
                    list_DoStop[i] = True
                    print('Created '+iDir+'/PostProc.STOP at '+dt.now().strftime("%Y-%m-%d %H:%M:%S"))
                else:
                    list_time[i]  = time_now
        time.sleep(180)
