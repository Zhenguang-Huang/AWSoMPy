#!/usr/bin/env python3
""" Hello world
"""

import argparse
import datetime as dt
import swmfpy
import sys
import subprocess

if __name__ == '__main__':

    # Program initiation
    PROG_DESCRIPTION = ('Script to automatically download data'
                        + ' and change PARAM.in if needed')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-p', '--poynting_flux',
                            help='(default: 1.0e6 J/m^2/s/T)',
                            type=float,
                            default=1.e6)
    ARG_PARSER.add_argument('-i', '--paramin',
                            help='(default: "PARAM.in")'
                            + ' nPARAM.in file to read',
                            default='PARAM.in')
    ARG_PARSER.add_argument('-t', '--time',
                            help='(default: Read PARAM.in time.)'
                            + 'Use if you want'
                            + ' to overwrite PARAM.in time.'
                            + ' Format: yyyy mm dd hh min',
                            nargs=5,
                            type=int,
                            default=None)
    ARGS = ARG_PARSER.parse_args()

    # Set the start time
    if len(ARGS.time) == 5:  # Argument given
        TIME = dt.datetime(ARGS.time[0],
                           ARGS.time[1],
                           ARGS.time[2],
                           ARGS.time[3], 
                           ARGS.time[4])
        swmfpy.paramin.replace_command({'#STARTTIME': ARGS.time},
                                       'PARAM.in',
                                       'PARAM.in')
    else:
        raise ValueError('Time sould be given as yyyy mm dd hh min. Correct -t/--time')


    # Poynting Flux
    CMD_PFLUX = {'#POYNTINGFLUX': [[str(ARGS.poynting_flux),
                                    'PoyntingFluxPerBSi [J/m^2/s/T]']]}
    swmfpy.paramin.replace_command(CMD_PFLUX,
                                   ARGS.paramin,
                                   ARGS.paramin)

    # Download magnetogram and remap
    FILE = swmfpy.web.download_magnetogram_adapt(TIME)[0]  # default 'fixed'

    exe_string = str('Scripts/remap_magnetogram.py ' + FILE + ' -istart 1 -iend 12')

    print(subprocess.call(exe_string, shell=True))

    # Done last because it exits current process
