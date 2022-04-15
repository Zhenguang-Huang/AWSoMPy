#!/usr/bin/env python3

import argparse
import datetime as dt
import sys
import subprocess
import warnings
import change_param
from remap_magnetogram import FITS_RECOGNIZE
import download_ADAPT

# -----------------------------------------------------------------------------
def change_param_local(time, map, pfss, scheme=2, poynting_flux=-1.0, new_params={},
                       DoUseMarker=0,DoRestart=0):

    params_pfss = ['CHANGEWEAKFIELD', 'BrFactor', 'BrMin']

    # need to turn on CHANGEWEAKFIELD if BrFactor and/or BrMin are changed
    if 'BrFactor' in new_params['change'].keys() or 'BrMin' in new_params['change'].keys():
        if 'add' in new_params.keys():
            new_params['add']=new_params['add']+',CHANGEWEAKFIELD'
        else:
            new_params['add']='CHANGEWEAKFIELD'

    # need to turn on FACTORB0 if FactorB0 is changed
    if 'FactorB0' in new_params['change'].keys():
        if 'add' in new_params.keys():
            new_params['add']=new_params['add']+',FACTORB0'
        else:
            new_params['add']='FACTORB0'

    # well, for 5th order scheme, there is a 0.02 thick layer above rMin for AWSoM-R
    if 'rMin_AWSoMR' in new_params['change'].keys():
        new_params['change']['rMaxLayer_AWSoMR'] = float(new_params['change']['rMin_AWSoMR']) + 0.02

    # set the PFSS solver, FDIPS or Harmonics
    # If it is HARAMONICS, no need to change as HARMONICS is the default
    if (pfss == 'FDIPS'):
        if 'add' in new_params.keys():
            new_params['add']=new_params['add']+',LOOKUPTABLE(FDIPS)'
        else:
            new_params['add']='LOOKUPTABLE(FDIPS)'
        if 'rm' in new_params.keys():
            new_params['rm'] =new_params['rm']+',HARMONICSFILE,HARMONICSGRID' 
        else:
            new_params['rm'] = 'HARMONICSFILE,HARMONICSGRID'
    elif pfss not in ['FDIPS','HARMONICS']:
        raise ValueError(pfss + ' must be either FDIPS')

    # for 5th order scheme
    if scheme == 5:
        if 'rm'in new_params.keys():
            new_params['rm'] =new_params['rm']+',END(END_2nd_scheme)'
        else:
            new_params['rm'] ='END(END_2nd_scheme)'

    new_params_pfss = {}

    # key1 could be change, add, rm, replace
    for key1 in list(new_params.keys()):
        if key1 in ['change','replace']:
            # another dict for ['change','replace']
            for key2 in list(new_params[key1].keys()):
                if key2 in params_pfss:
                    if key1 not in new_params_pfss.keys():
                        new_params_pfss[key1]={key2:new_params[key1][key2]}
                    else:
                        new_params_pfss[key1][key2] = new_params[key1][key2]
                    # delete the entry found in params_pfss
                    new_params[key1].pop(key2,None)
        elif key1 in ['add','rm']:
            # a string for ['add','rm']
            commands_local = new_params[key1]
            commands_list_local = commands_local.split(',')
            commands_list_pfss  = []

            for i in range(len(commands_list_local)):
                if commands_list_local[i] in params_pfss:
                    commands_list_pfss.append(commands_list_local[i])
                    commands_list_local[i] = ''

            # remove '' in the list
            if '' in commands_list_local:
                commands_list_local.remove('')

            if len(commands_list_local) == 0:
                # remove the key if the list of the string is empty (for PARAM.in)
                new_params.pop(key1,None)
            else:
                new_params[key1] = ','.join(commands_list_local)

            # if the list of the string for the pfss is not empty, add the entry
            if len(commands_list_pfss) > 0:
                new_params_pfss[key1] = ','.join(commands_list_pfss)

    if time != 'MapTime':
        # TIME is given with the correct format
        time_input = dt.datetime.strptime(time, "%Y-%m-%dT%H:%M:%S")
        time_param = time.replace('-',',').replace('T',',').replace(':',',')

    if (map == 'NoMap'):
        if time != 'MapTime':
            # Download the ADAPT magnetogram if no map is pvoided
            # default 'fixed', note that the time_input is correctly set.
            filename_map = download_ADAPT.download_ADAPT_magnetogram(time_input)[0]
            print("download the map as: ", filename_map)
        else:
            raise ValueError('No map is provided. Please provide the time '
                             + 'by -t/--time to download the ADAPT map.')
    else:
        # The ADAPT map is provied
        filename_map = map
        
        map_local  = FITS_RECOGNIZE(map)
        time_map   = dt.datetime.strptime(map_local[9], "%Y-%m-%dT%H:%M:%S")

        # Very weird GONG Synoptic map, the map time is a few days after the end of the CR.
        # Use an approximation to get the time corresponding to the central meridian
        if (map_local[0] == 'NSO-GONG Synoptic'):
            CR_number = float(map_local[6])
            time_map = dt.datetime(1853, 11, 9) + dt.timedelta(days=27.2753*(CR_number-0.5))

        if time == 'MapTime':
            # if the user does not provide the time, then set the time based
            # on the time info from the ADAPT map.
            time_param = (str(time_map.year)   + ',' + str(time_map.month) + ',' +
                          str(time_map.day)    + ',' + str(time_map.hour)  + ',' +
                          str(time_map.minute) + ',' + str(time_map.second))

    # Need to add the msc
    time_param = time_param+',0.0'

    # set #STARTTIME
    if 'replace' in new_params.keys():
        new_params['replace']['STARTTIME']=time_param
    else:
        new_params['replace'] = {'STARTTIME':time_param}

    if DoRestart:
        if 'STARTTIME' in new_params['replace']:
            new_params['replace'].pop('STARTTIME',None)

    if poynting_flux > 0:
        # set #POYNTINGFLUX
        if 'replace' in new_params.keys():
            new_params['replace']['POYNTINGFLUX']='{:<10.3e}'.format(poynting_flux)
        else:
            new_params['replace']={'POYNTINGFLUX':'{:<10.3e}'.format(poynting_flux)}
    elif not 'PoyntingFluxPerBSi' in new_params['change'].keys() and not 'POYNTINGFLUX' in new_params['replace'].keys():
        warnings.warn('PoyntingFluxPerBSi is less than 0, use the PoyntingFluxPerBSi in' +
                      ' the original PARAM.in.')

    if 'add' in new_params.keys():
        commands_add=new_params['add']
        change_param.add_commands(commands_add, DoUseMarker=DoUseMarker)

    if 'add' in new_params_pfss.keys():
        commands_add=new_params_pfss['add']
        change_param.add_commands(commands_add, DoUseMarker=DoUseMarker, filenameIn=pfss+'.in', filenameOut=pfss+'.in')

    if 'rm' in new_params.keys():
        commands_rm=new_params['rm']
        change_param.remove_commands(commands_rm, DoUseMarker=DoUseMarker)

    if 'rm' in new_params_pfss.keys():
        commands_rm=new_params_pfss['rm']
        change_param.remove_commands(commands_rm, DoUseMarker=DoUseMarker, filenameIn=pfss+'.in', filenameOut=pfss+'.in')

    if 'replace' in new_params.keys():
        DictReplace = new_params['replace']
        change_param.replace_commands(DictReplace, DoUseMarker=DoUseMarker)

    if 'replace' in new_params_pfss.keys():
        DictReplace = new_params_pfss['replace']
        change_param.replace_commands(DictReplace, DoUseMarker=DoUseMarker, filenameIn=pfss+'.in', filenameOut=pfss+'.in')

    if 'change' in new_params.keys():
        DictChange  = new_params['change']
        change_param.change_param_value(DictChange, DoUseMarker=DoUseMarker)

    if 'change' in new_params_pfss.keys():
        DictChange  = new_params_pfss['change']
        change_param.change_param_value(DictChange, DoUseMarker=DoUseMarker, filenameIn=pfss+'.in', filenameOut=pfss+'.in')

    # prepare each realization map.
    str_exe = str('Scripts/remap_magnetogram.py ' + filename_map)

    subprocess.call(str_exe, shell=True)

# =============================================================================
if __name__ == '__main__':

    # Program initiation
    PROG_DESCRIPTION = ('Script to change PARAM.in if needed and '
                        + ' automatically download the ADAPT map.')
    ARG_PARSER = argparse.ArgumentParser(description=PROG_DESCRIPTION)
    ARG_PARSER.add_argument('-p', '--poynting_flux',
                            help='(default: -1.0 J/m^2/s/T)',
                            type=float, default=-1)
    ARG_PARSER.add_argument('-t', '--time',
                            help='(default: MapTime)'
                            + 'Use if you want to overwrite PARAM.in time.'
                            + ' Format: yyyy-mm-ddThh:min:sec',
                            type=str, default='MapTime')
    ARG_PARSER.add_argument('-B0', '--pfss',
                            help='(default: HARMONICS.)'
                            + ' Use if you want to specify the PFSS solver.',
                            type=str, default='HARMONICS')
    ARG_PARSER.add_argument('-m', '--map',
                            help='(default: NoMap)'
                            + ' Use if you want to specify the ADAPT map.',
                            type=str, default='NoMap')
    ARG_PARSER.add_argument('-param', '--parameters',
                            help='(default: {})' +
                            ' Use if you want to change the values of the'
                            + ' parameters.',
                            type=list)
    ARG_PARSER.add_argument('--DoRestart',
                            help='(default: 0)' +
                            ' Use if it is a restart run.',
                            type=int)
    ARGS = ARG_PARSER.parse_args()

    change_param_local(time=ARGS.time, map=ARGS.map, pfss=ARGS.pfss,
                       poynting_flux=ARGS.poynting_flux, DoUseMarker=0, DoRestart=ARGS.DoRestart)
