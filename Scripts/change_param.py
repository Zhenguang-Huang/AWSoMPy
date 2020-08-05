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
    ARG_PARSER.add_argument('-t', '--time',
                            help='(default: Read PARAM.in time.)'
                            + 'Use if you want'
                            + ' to overwrite PARAM.in time.'
                            + ' Format: yyyy mm dd hh min',
                            nargs=5,
                            type=int,
                            default=None)
    ARG_PARSER.add_argument('-B0', '--potentialfield',
                            help='(default: HARMONICS.)'
                            + ' Use if you want to specify '
                            + ' the potential field solver. ',
                            type=str,
                            default='HARMONICS')
    ARG_PARSER.add_argument('-m', '--map',
                            help='(default: NONE.)'
                            + ' Use if you want to specify '
                            + ' the ADAPT map. ',
                            type=str,
                            default='NONE')
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
                                   'PARAM.in',
                                   'PARAM.in')

    # Download magnetogram and remap if no maps are pvoided
    if (ARGS.potentialfield == 'none'):
        FILE = swmfpy.web.download_magnetogram_adapt(TIME)[0]  # default 'fixed'
    else:
        FILE = ARGS.map

    exe_string = str('Scripts/remap_magnetogram.py ' + FILE + ' -istart 1 -iend 12')

    print(subprocess.call(exe_string, shell=True))

    if (ARGS.potentialfield == 'HARMONICS'):
        print("The default is HARMONICS, no need to change")
    elif (ARGS.potentialfield == 'FDIPS'):
        input_file  = open('PARAM.in', 'rt')
        lines = []
        while True:
            line = input_file.readline()
            if not line: break

            if 'LOOKUPTABLE' in line:
                linenext = input_file.readline()
                if 'B0' in linenext:
                    line = '#'+line
                lines.append(line)
                lines.append(linenext)
            elif '#MAGNETOGRAM' in line:
                line = line[1:]
                lines.append(line)
            else:
                lines.append(line)

        output_file = open('PARAM.in', 'w')
        for line in lines:
            output_file.write(line)

        input_file.close()
        output_file.close()
    else:
        raise ValueError(ARGS.potentialfield + ' must be either HARMONICS or FDIPS')

