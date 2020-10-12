#!/usr/bin/env python3

import argparse
import datetime as dt
import swmfpy
import sys
import subprocess
import warnings
from remap_magnetogram import FITS_RECOGNIZE

# -------------------------------------------------------------------------------
def add_command(NameCommand, filenameInput='PARAM.in',
                filenameOut='PARAM.in', NameNextLine=None):
    """
    """

    file_input  = open(filenameInput, 'rt')

    lines = []
    while True:
        line = file_input.readline()
        if not line: break

        if NameCommand in line and line[0] != '#':
            if NameNextLine != None:
                linenext = file_input.readline()
                if NameNextLine in linenext:
                    line = '#'+line
                lines.append(line)
                lines.append(linenext)
            else:
                line = '#'+line
                lines.append(line)
        else:
            lines.append(line)

    file_input.close()

    file_output = open(filenameOut, 'w')
    for line in lines:
        file_output.write(line)
    file_output.close()

# -------------------------------------------------------------------------------
def remove_command(NameCommand, filenameInput='PARAM.in',
                   filenameOut='PARAM.in', NameNextLine=None):
    """
    """

    file_input  = open(filenameInput, 'rt')

    lines = []
    while True:
        line = file_input.readline()
        if not line: break

        if NameCommand in line and line[0] == '#':
            if NameNextLine != None:
                linenext = file_input.readline()
                if NameNextLine in linenext:
                    line = line[1:]
                lines.append(line)
                lines.append(linenext)
            else:
                lines.append(line[1:])
        else:
            lines.append(line)

    file_input.close()

    file_output = open(filenameOut, 'w')
    for line in lines:
        file_output.write(line)
    file_output.close()

# -------------------------------------------------------------------------------
def change_param_value(NameParam, ValueParam, filenameInput='PARAM.in',
                       filenameOut='PARAM.in'):
    """
    """
    import re

    file_input  = open(filenameInput, 'rt')

    lines = []
    while True:
        line = file_input.readline()
        if not line: break

        if NameParam in line:
            print("ValueParam =", ValueParam)
            print("line =", line)
            line=re.sub('\d+\.\d+', str(ValueParam), line)

        lines.append(line)

    file_input.close()

    file_output = open(filenameOut, 'w')
    for line in lines:
        file_output.write(line)
    file_output.close()

# ===============================================================================
if __name__ == '__main__':

    # Program initiation
    PROG_DESCRIPTION = ('Script to change PARAM.in if needed and '
                        + ' automatically download the ADAPT map.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-p', '--poynting_flux',
                            help='(default: -1.0 J/m^2/s/T)',
                            type=float, default=-1)
    ARG_PARSER.add_argument('-t', '--time',
                            help='(default: NoTime.)'
                            + 'Use if you want to overwrite PARAM.in time.'
                            + ' Format: yyyy-mm-ddThh:min:sec',
                            type=str, default='NoTime')
    ARG_PARSER.add_argument('-B0', '--potentialfield',
                            help='(default: HARMONICS.)'
                            + ' Use if you want to specify the PFSS solver.',
                            type=str, default='HARMONICS')
    ARG_PARSER.add_argument('-m', '--map',
                            help='(default: NoMap.)'
                            + ' Use if you want to specify the ADAPT map.',
                            type=str, default='NoMap')
    ARGS = ARG_PARSER.parse_args()

    if ARGS.time != 'NoTime':
        # TIME is given with the correct format
        time_input = dt.datetime.strptime(ARGS.time, "%Y-%m-%dT%H:%M:%S")
        time_param = [[time_input.year,  'iYear'],
                      [time_input.month, 'iMonth'],
                      [time_input.day,   'iDay'],
                      [time_input.hour,  'iHour'],
                      [time_input.minute,'iMinute'],
                      [time_input.second,'iSecond']]

    if (ARGS.map == 'NoMap'):
        if ARGS.time != 'NoTime':
            # Download the ADAPT magnetogram if no map is pvoided
            # default 'fixed', note that the time_input is correctly set.
            filename_map = swmfpy.web.download_magnetogram_adapt(time_input)[0]
            print("download the map as: ", filename_map)
        else:
            raise ValueError('No map is provided. Please provide the time '
                             + 'by -t/--time to download the ADAPT map.')
    else:
        # The ADAPT map is provied
        filename_map = ARGS.map
        
        map_local  = FITS_RECOGNIZE(ARGS.map)
        time_map   = dt.datetime.strptime(map_local[9], "%Y-%m-%dT%H:%M:%S")

        # Very weird GONG Synoptic map, the map time is a few days after the end of the CR.
        # Use an approximation to get the time corresponding to the central meridian
        if (map_local[0] == 'NSO-GONG Synoptic'):
            CR_number = float(map_local[6])
            time_map = dt.datetime(1853, 11, 9) + dt.timedelta(days=27.2753*(CR_number-0.5))

        if ARGS.time == 'NoTime':
            # if the user does not provide the time, then set the time based
            # on the time info from the ADAPT map.
            time_param = [[time_map.year,  'iYear'],
                          [time_map.month, 'iMonth'],
                          [time_map.day,   'iDay'],
                          [time_map.hour,  'iHour'],
                          [time_map.minute,'iMinute'],
                          [time_map.second,'iSecond']]

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
        add_command('LOOKUPTABLE', NameNextLine='B0')
        remove_command('MAGNETOGRAM')
    elif (ARGS.potentialfield == 'HARMONICS'):
        remove_command('LOOKUPTABLE', NameNextLine='B0')
        add_command('MAGNETOGRAM')
    else:
        raise ValueError(ARGS.potentialfield + ' must be either HARMONICS or FDIPS')

    # prepare each realization map.
    str_exe = str('Scripts/remap_magnetogram.py ' + filename_map)

    subprocess.call(str_exe, shell=True)
