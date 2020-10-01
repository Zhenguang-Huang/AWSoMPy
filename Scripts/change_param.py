#!/usr/bin/env python3

import argparse
import datetime as dt
import swmfpy
import sys
import subprocess
import warnings
from remap_magnetogram import FITS_RECOGNIZE

if __name__ == '__main__':

    # Program initiation
    PROG_DESCRIPTION = ('Script to automatically download data'
                        + ' and change PARAM.in if needed')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-p', '--poynting_flux',
                            help='(default: -1.0 J/m^2/s/T)',
                            type=float, default=-1)
    ARG_PARSER.add_argument('-t', '--time',
                            help='(default: None.)'
                            + 'Use if you want to overwrite PARAM.in time.'
                            + ' Format: yyyy mm dd hh min',
                            nargs=5, type=int, default=None)
    ARG_PARSER.add_argument('-B0', '--potentialfield',
                            help='(default: HARMONICS.)'
                            + ' Use if you want to specify the PFSS solver.',
                            type=str, default='HARMONICS')
    ARG_PARSER.add_argument('-m', '--amap',
                            help='(default: None.)'
                            + ' Use if you want to specify the ADAPT map.',
                            type=str, default=None)
    ARGS = ARG_PARSER.parse_args()

    if ARGS.time != None: 
        if len(ARGS.time) == 5:
            # TIME is given with the correct format
            time_input = dt.datetime(ARGS.time[0],
                                     ARGS.time[1],
                                     ARGS.time[2],
                                     ARGS.time[3], 
                                     ARGS.time[4])
            time_param = ARGS.time
        else:
            raise ValueError(ARGS.time,
                             'Time sould be given as yyyy mm dd hh min. ' +
                             'Correct -t/--time')

    if (ARGS.amap == None):
        if ARGS.time != None:
            # Download magnetogram if no map is pvoided
            # default 'fixed', note that the time_input is correctly set.
            filename_map = swmfpy.web.download_magnetogram_adapt(time_input)[0]
        else:
            raise ValueError(ARGS.time, 'Please provide the time by -t/--time')
    else:
        # The ADAPT map is provied
        filename_map = ARGS.amap
        
        map_local  = FITS_RECOGNIZE(ARGS.amap)
        time_map   = dt.datetime.strptime(map_local[9], "%Y-%m-%dT%H:%M:%S")

        if ARGS.time != None:
            # Check if the user provides a different time....
            if (time_map.year  != time_input.year    or
                time_map.month != time_input.month   or  
                time_map.day   != time_input.day     or
                time_map.hour  != time_input.hour):
                raise ValueError(ARGS.time, 'MAP and TIME are inconsistent. ' +
                                 'Either set MAP or TIME; or make them '      +
                                 'consistent')
        else:
            # if the user does not provide the time, then set the time based
            # on the time info from the ADAPT map.
            time_param = [time_map.year, time_map.month,
                          time_map.day,  time_map.hour]

    # set #STARTTIME
    swmfpy.paramin.replace_command({'#STARTTIME': time_param},
                                   'PARAM.in', 'PARAM.in')

    if ARGS.poynting_flux > 0:
        # set #POYNTINGFLUX
        str_flux = {'#POYNTINGFLUX': [['{:<10.3e}'.format(ARGS.poynting_flux), 
                                       'PoyntingFluxPerBSi [J/m^2/s/T]']]}
        swmfpy.paramin.replace_command(str_flux, 'PARAM.in', 'PARAM.in')
    else:
        warnings.warn('PoyntingFluxPerBSi is less than 0, use the PoyntingFluxPerBSi in' +
                      ' the original PARAM.in.')

    # set the PFSS solver, FDIPS or Harmonics
    if (ARGS.potentialfield == 'FDIPS'):
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
    elif ARGS.potentialfield != 'HARMONICS':
        raise ValueError(ARGS.potentialfield + ' must be either HARMONICS or FDIPS')


    # prepare each realization map.
    str_exe = str('Scripts/remap_magnetogram.py ' + filename_map)

    subprocess.call(str_exe, shell=True)
