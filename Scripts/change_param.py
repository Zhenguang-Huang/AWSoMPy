#!/usr/bin/env python3

import re

# -----------------------------------------------------------------------------
def add_commands(StrCommands, filenameIn='PARAM.in',
                 filenameOut='PARAM.in', ExtraStr=None, DoUseMarker=0):

    """
    Add commands in PARAM.in/FDIPS.in/HARMONICS.in files.

    Arguments:
      StrCommands: a string containing all the commands (separated by ',')
                   to be added.
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
      ExtraStr:    an optional extra string for selecting the commands to
                   be added, in case the command(s) show up in multiple places
                   in the input file. ExtraStr is for ALL the commands and the
                   user should NOT provide each ExtraStr for each command.
      DoUseMarker: an optional integer indicating whether to use ^ as a 
                   marker. It does not need to be used with ExtraStr. But if
                   ExtraStr is also provided, the marker should be NEXT to 
                   ExtraStr in the input file.

    Examples:
         If the input files contains:
         ---------------------------------------------------------
             TIMEACCURATE
             ...
             BODY
             ...
             TIMEACCURATE            test
             ...
             BODY                    test
             ...
             TIMEACCURATE            test^
             ...
             BODY                    test^
             ...
             TIMEACCURATE            test ^
             ...
             BODY                    test ^
             ...
             TIMEACCURATE            ^
             ...
             BODY                    ^
         ---------------------------------------------------------

         # Add all BODY/TIMEACCURATE commands:
         add_commands('BODY,TIMEACCURATE')

         # Add the 2nd to 4th BODY/TIMEACCURATE commands
         add_commands('BODY,TIMEACCURATE',ExtraStr='test')

         # Only add the 3rd BODY/TIMEACCURATE commands
         add_commands('BODY,TIMEACCURATE',ExtraStr='test',DoUseMarker=1)

         # Add the 3rd to 5th BODY/TIMEACCURATE commands
         add_commands('BODY,TIMEACCURATE',DoUseMarker=1)
    """

    # report error if StrCommands is not a string
    if not isinstance(StrCommands,str):
        raise TypeError('StrCommands is not a string, StrCommands=', 
                        StrCommands)

    # get all the commands in an array
    command_I=StrCommands.split(',')

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all the lines
    for iLine, line in enumerate(lines):
        # loop through all the commands
        for command in command_I:
            # check whether the the line starts with the command
            if command in line[0:len(command)]:
                if ExtraStr != None:
                    # if ExtraStr is provided, add the command if the 
                    # line contains:
                    # 1. the ExtraStr if not DoUseMarker
                    # 2. '^' follows by ExtraStr if DoUseMarker=1
                    if ((re.search(rf'\b{ExtraStr}\b', line) and not DoUseMarker) or
                        (re.search(rf'\b{ExtraStr}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                        lines[iLine] = '#'+line
                elif not DoUseMarker:
                    # DoUseMarker = 0 and ExtraStr = None
                    lines[iLine] = '#'+line
                else:
                    # DoUseMarker = 1 and ExtraStr = None
                    if '^' in line:
                        lines[iLine] = '#'+line

    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)

# -----------------------------------------------------------------------------
def remove_commands(StrCommands, filenameIn='PARAM.in',
                    filenameOut='PARAM.in', ExtraStr=None, DoUseMarker=0):
    """
    Add commands in PARAM.in/FDIPS.in/HARMONICS.in files.

    Arguments:
      StrCommands: a string containing all the commands (separated by ',') to
                   be removed.
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
      ExtraStr:    an optional extra string for selecting the commands to be
                   removed, in case the command(s) show up in multiple places
                   in the input file. ExtraStr is for ALL the commands and the
                   user should NOT provide each ExtraStr for each command.
      DoUseMarker: an optional integer indicating whether to use ^ as a 
                   marker. It does not need to be used with ExtraStr. But if
                   ExtraStr is also provided, the marker should be NEXT to
                   ExtraStr in the input file.

    Example is similar to add_commands.
    """

    # report error if StrCommands is not a string
    if not isinstance(StrCommands,str):
        raise TypeError('StrCommands is not a string, StrCommands=',
                        StrCommands)

    # get all the commands in an array
    command_I=StrCommands.split(',')

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all the lines
    for iLine, line in enumerate(lines):
        # loop through all the commands
        for command in command_I:
            # check whether the the line starts '#' and followed by the
            # command                
            if command in line[1:len(command)+1] and line[0] == '#':
                if ExtraStr != None:
                    # if ExtraStr is provided, remove the command if the
                    # line contains:
                    # 1. the ExtraStr if not DoUseMarker
                    # 2. '^' follows by ExtraStr if DoUseMarker=1
                    if ((re.search(rf'\b{ExtraStr}\b', line) and not DoUseMarker) or
                        (re.search(rf'\b{ExtraStr}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                        lines[iLine] = line[1:]
                elif not DoUseMarker:
                    # DoUseMarker = 0 and ExtraStr = None
                    lines[iLine] = line[1:]
                else:
                    # DoUseMarker = 1 and ExtraStr = None
                    if '^' in line:
                        lines[iLine] = line[1:]
    
    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)

# -----------------------------------------------------------------------------
def replace_commands(DictParam, filenameIn='PARAM.in',
                     filenameOut='PARAM.in', ExtraStr=None, DoUseMarker=0):
    """
    Replace commands with their parameters in PARAM.in/FDIPS.in/HARMONICS.in
    files.

    Arguments:
      DictParam:   a dict containing all the commands (string) with the values
                   of their parameters (string separated by ',') to be
                   replaced. The parameters do not need to be complete. The 
                   script will replace the parameters up to last parameter
                   that the user specifies.
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
      ExtraStr:    an optional extra string for selecting the commands to be
                   replaced, in case the command(s) show up in multiple places
                   in the input file. ExtraStr is for ALL the commands and the
                   user should NOT provide each ExtraStr for each command.
      DoUseMarker: an optional integer indicating whether to use ^ as a 
                   marker. It does not need to be used with ExtraStr. But if
                   ExtraStr is also provided, the marker should be NEXT to
                   ExtraStr in the input file.

    Examples:
         If the input files contains:
         ---------------------------------------------------------
         #POYNTINGFLUX
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T]

         #CHROMOBC
         2e17                    NchromoSi       nChromoSi_AWSoM
         5e4                     TchromoSi

         #POYNTINGFLUX           test
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T]

         #CHROMOBC               test
         2e17                    NchromoSi       nChromoSi_AWSoM
         5e4                     TchromoSi

         #POYNTINGFLUX           test^
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T]

         #CHROMOBC               test^
         2e17                    NchromoSi       nChromoSi_AWSoM
         5e4                     TchromoSi

         #POYNTINGFLUX           test ^
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T]

         #CHROMOBC               test ^
         2e17                    NchromoSi       nChromoSi_AWSoM
         5e4                     TchromoSi

         #POYNTINGFLUX           ^
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T]

         #CHROMOBC               ^
         2e17                    NchromoSi       nChromoSi_AWSoM
         5e4                     TchromoSi
         ---------------------------------------------------------

         DictReplace={'POYNTINGFLUX':'3e5', 'CHROMOBC':'1e16,7e4'}

         # or only need to change NchromoSi in CHROMOBC:
         DictReplace={'POYNTINGFLUX':'3e5', 'CHROMOBC':'1e16'}

         # Replace all POYNTINGFLUX/CHROMOBC commands:
         replace_commands(DictReplace)

         # Add the 2nd to 4th POYNTINGFLUX/CHROMOBC commands
         replace_commands(DictReplace,ExtraStr='test')

         # Only add the 3rd POYNTINGFLUX/CHROMOBC commands
         replace_commands(DictReplace,ExtraStr='test',DoUseMarker=1)

         # Add the 3rd to 5th POYNTINGFLUX/CHROMOBC commands
         replace_commands(DictReplace,DoUseMarker=1)

    """

    # report error if DictParam is not a dict
    if not isinstance(DictParam,dict):
        raise TypeError('DictParam is not a dict, DictParam=', DictParam)

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all lines
    for iLine, line in enumerate(lines):
        # loop through all the keys
        for NameCommand in DictParam.keys():
            # obtain the parameter list
            strParam_I = DictParam[NameCommand].split(',')
            # check whether the the line starts '#' and followed by the
            # command
            if NameCommand in line[1:len(NameCommand)+1] and line[0] == '#':
                if ExtraStr != None:
                    # if ExtraStr is provided, replace the command if the
                    # line contains:
                    # 1. the ExtraStr if not DoUseMarker
                    # 2. '^' follows by ExtraStr if DoUseMarker=1
                    if ((re.search(rf'\b{ExtraStr}\b', line) and not DoUseMarker) or
                        (re.search(rf'\b{ExtraStr}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                        for iParam, param_local in enumerate(strParam_I):
                            # split the original line
                            line_split = lines[iLine+iParam+1].split()
                            # create the new line
                            new_line   = strParam_I[iParam] +'\t\t\t' \
                                + ' '.join(line_split[1:])+'\n'
                            # replace the line containing the parameter
                            lines[iLine+iParam+1] = new_line
                elif not DoUseMarker:
                    # DoUseMarker = 0 and ExtraStr = None
                    for iParam, param_local in enumerate(strParam_I):
                        line_split = lines[iLine+iParam+1].split()
                        new_line   = strParam_I[iParam] +'\t\t\t' \
                            + ' '.join(line_split[1:])+'\n'
                        lines[iLine+iParam+1] = new_line
                else:
                    # DoUseMarker = 1 and ExtraStr = None
                    if '^' in line:
                        for iParam, param_local in enumerate(strParam_I):
                            line_split = lines[iLine+iParam+1].split()
                            new_line   = strParam_I[iParam] +'\t\t\t' \
                                + ' '.join(line_split[1:])+'\n'
                            lines[iLine+iParam+1] = new_line

    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)

# -----------------------------------------------------------------------------
def change_param_value(DictParam, filenameIn='PARAM.in',
                       filenameOut='PARAM.in', DoUseMarker=0):
    """
    Change the value of a parameter in PARAM.in/FDIPS.in/HARMONICS.in files.

    Arguments:
      DictParam:   a dict containing the name (string) and value (a number or
                   a string) of the parameters to be changed. The name of the
                   parameter can be user specified in the input file.
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
      DoUseMarker: an optional integer indicating whether to use ^ as a 
                   marker. If it is set to 1, the marker '^' has to be next 
                   to the name of the parameter.

    Note: This function is very similar to replace_commands. replace_commands
          can change multiple parameters (multiple lines) for the command(s),
          while change_param_value can only change one parameter (one line).
          And user has the flexibility to set the name of the parameter to be
          changed in the input file. replace_commands only replace the command
          which is turned on in the input file, while change_param_value does
          not care whether the associated command is turned on or not.

    Examples:
         If the input files contains:
         ---------------------------------------------------------
         #POYNTINGFLUX
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T]

         #CHROMOBC
         2e17                    NchromoSi       nChromoSi_AWSoM
         5e4                     TchromoSi

         #POYNTINGFLUX
         1.0e6                   PoyntingFluxPerBSi^ [J/m^2/s/T]

         #CHROMOBC
         2e17                    NchromoSi       nChromoSi_AWSoM^
         5e4                     TchromoSi

         #POYNTINGFLUX
         1.0e6                   PoyntingFluxPerBSi [J/m^2/s/T] ^

         #CHROMOBC
         2e17                    NchromoSi       nChromoSi_AWSoM ^
         5e4                     TchromoSi
         ---------------------------------------------------------

         DictChange={'PoyntingFluxPerBSi':'3e5', 'nChromoSi_AWSoM':1e16}

         # Change all the PoyntingFluxPerBSi/nChromoSi_AWSoM
         change_param_value(DictChange)
         
         # Change only the second PoyntingFluxPerBSi/nChromoSi_AWSoM
         change_param_value(DictChange, DoUseMarker=1)
    """

    # report error if DictParam is not a dict
    if not isinstance(DictParam,dict):
        raise TypeError('DictParam is not a dict, DictParam=', DictParam)

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all lines
    for iLine, line in enumerate(lines):
        # loop through all keys
        for key in DictParam.keys():
            # change the value if:
            # 1. the name of the parameter is in the line if 
            #    DoUseMarker = 0
            # 2. '^' follows by the name of the parameter if 
            #    DoUseMarker = 1
            if ((re.search(rf'\b{key}\b', line) and not DoUseMarker) or 
                (re.search(rf'\b{key}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                value = DictParam[key]
                if isinstance(value, str):
                    lines[iLine] = value+'\t\t\t'+key+'\n'
                else:
                    try:
                        lines[iLine] = str(value)+'\t\t\t'+key+'\n'
                    except Exception as error:
                        raise TypeError(error, "Value cannot convert to a string.")

    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)
