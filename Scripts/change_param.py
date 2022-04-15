#!/usr/bin/env python3

import re
import sys

# -----------------------------------------------------------------------------
def add_commands(StrCommands, filenameIn='PARAM.in',
                 filenameOut='PARAM.in', DoUseMarker=0):

    """
    Add commands in PARAM.in/FDIPS.in/HARMONICS.in files.

    Arguments:
      StrCommands: a string containing all the commands (separated by ',')
                   to be added. An ExtraStr could be added with '()', e.g.,
                   BODY(test).
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
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
         add_commands('BODY(test),TIMEACCURATE')

         # Only add the 3rd BODY/TIMEACCURATE commands
         add_commands('BODY,TIMEACCURATE(test)',DoUseMarker=1)

         # Add the 3rd to 5th BODY/TIMEACCURATE commands
         add_commands('BODY,TIMEACCURATE',DoUseMarker=1)
    """

    # report error if StrCommands is not a string
    if not isinstance(StrCommands,str):
        raise TypeError('StrCommands is not a string, StrCommands=', 
                        StrCommands)

    # return if is an empty string
    if len(StrCommands) == 0:
        return

    # get all the commands in an array
    command_I=StrCommands.split(',')

    IsChanged_I = [False for i in range(len(command_I))]

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all the lines
    for iLine, line in enumerate(lines):
        # loop through all the commands
        for icom, command in enumerate(command_I):
            # well the line may contain the command name + ExtraStr
            commands_line = line.split()

            # check whether extra string is provided with ()
            if '(' and ')' in command:
                commandLocal = command.split('(')[0]
                ExtraStr     = command.split('(')[1].split(')')[0]
            else:
                commandLocal = command
                ExtraStr     = None

            if len(commands_line) == 0:
                continue

            if commandLocal == commands_line[0]:
                # extra string is provided...
                if ExtraStr != None:
                    # if ExtraStr is provided, add the command if the 
                    # line contains:
                    # 1. the ExtraStr if not DoUseMarker
                    # 2. '^' follows by ExtraStr if DoUseMarker=1
                    if ((re.search(rf'\b{ExtraStr}\b', line) and not DoUseMarker) or
                        (re.search(rf'\b{ExtraStr}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                        lines[iLine] = '#'+line
                        IsChanged_I[icom] = True
                elif not DoUseMarker:
                    # DoUseMarker = 0 and ExtraStr = None
                    lines[iLine] = '#'+line
                    IsChanged_I[icom] = True
                else:
                    # DoUseMarker = 1 and ExtraStr = None
                    if '^' in line:
                        lines[iLine] = '#'+line
                        IsChanged_I[icom] = True

    if False in IsChanged_I:
        print('--------------------------------------------------------')
        print("command_I   =", command_I)
        print("IsChanged_I =", IsChanged_I)
        sys.exit("Some commands are not added!!!")

    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)

# -----------------------------------------------------------------------------
def remove_commands(StrCommands, filenameIn='PARAM.in',
                    filenameOut='PARAM.in', DoUseMarker=0):
    """
    Add commands in PARAM.in/FDIPS.in/HARMONICS.in files.

    Arguments:
      StrCommands: a string containing all the commands (separated by ',') to
                   be removed. An ExtraStr could be added with '()', e.g.,
                   BODY(test).
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
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

    # return if is an empty string
    if len(StrCommands)== 0:
        return

    # get all the commands in an array
    command_I=StrCommands.split(',')

    IsChanged_I = [False for i in range(len(command_I))]

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all the lines
    for iLine, line in enumerate(lines):
        # loop through all the commands
        for icom, command in enumerate(command_I):
            # well the line may contain the command name + ExtraStr
            commands_line = line.split()

            # check whether extra string is provided with ()
            if '(' and ')' in command:
                commandLocal = command.split('(')[0]
                ExtraStr     = command.split('(')[1].split(')')[0]
            else:
                commandLocal = command
                ExtraStr     = None

            if len(commands_line) == 0:
                continue

            if commandLocal == commands_line[0][1:] and commands_line[0][0] == '#':
                if ExtraStr != None:
                    # if ExtraStr is provided, remove the command if the
                    # line contains:
                    # 1. the ExtraStr if not DoUseMarker
                    # 2. '^' follows by ExtraStr if DoUseMarker=1
                    if ((re.search(rf'\b{ExtraStr}\b', line) and not DoUseMarker) or
                        (re.search(rf'\b{ExtraStr}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                        lines[iLine] = line[1:]
                        IsChanged_I[icom] = True
                elif not DoUseMarker:
                    # DoUseMarker = 0 and ExtraStr = None
                    lines[iLine] = line[1:]
                    IsChanged_I[icom] = True
                else:
                    # DoUseMarker = 1 and ExtraStr = None
                    if '^' in line:
                        lines[iLine] = line[1:]
                        IsChanged_I[icom] = True
    
    if False in IsChanged_I:
        print('--------------------------------------------------------')
        print("command_I   =", command_I)
        print("IsChanged_I =", IsChanged_I)
        sys.exit("Some commands are not removed!!!")

    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)

# -----------------------------------------------------------------------------
def replace_commands(DictParam, filenameIn='PARAM.in',
                     filenameOut='PARAM.in', DoUseMarker=0):
    """
    Replace commands with their parameters in PARAM.in/FDIPS.in/HARMONICS.in
    files.

    Arguments:
      DictParam:   a dict containing all the commands (string with optional ExtraStr
                   inside '()', e.g., POYNTINGFLUX(test)) with the values
                   of their parameters (string separated by ',') to be
                   replaced. The parameters need to be COMPLETE. The 
                   script will replace the parameters with proper expansion or
                   contraction.
      filenameIn:  an optional string for the input filename.
                   Defualt is PARAM.in.
      filenameOut: an optional string for the output filename.
                   Defualt is PARAM.in.
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

         DictReplace={'POYNTINGFLUX(test)':'3e5', 'CHROMOBC':'1e16,7e4'}

         # Replace all POYNTINGFLUX/CHROMOBC commands:
         replace_commands(DictReplace)

         # Add the 2nd to 4th POYNTINGFLUX/CHROMOBC commands
         replace_commands(DictReplace)

         # Only add the 3rd POYNTINGFLUX/CHROMOBC commands
         replace_commands(DictReplace,DoUseMarker=1)

         # Add the 3rd to 5th POYNTINGFLUX/CHROMOBC commands
         replace_commands(DictReplace,DoUseMarker=1)

         ---------------------------------------------------------

         A fancy way trying to replace the AMRCRITERIARESOLUTION as follows:

	 #AMRCRITERIARESOLUTION              SC^
	 3                       nRefineCrit
	 dphi                    StringRefine
	 3.0                     RefineTo
	 1.5                     CoarsenFrom
	 dphi Innershell         StringRefine
	 1.5                     RefineTo
	 0.75                    CoarsenFrom
	 currentsheet            StringRefine
	 0.5                     CoarsenLimit
	 0.5                     RefineLimit
	 1.5                     MaxResolution

         The Dict could be defined as
         DictReplace={'AMRCRITERIARESOLUTION(SC)':'2,dphi,3.0,1.5,dphi Innershell,1.5,0.75'}
         which will remove the last criteria

         Or
         DictReplace={'AMRCRITERIARESOLUTION(SC)':'4,dphi,3.0,1.5,dphi Innershell,1.5,0.75,currentsheet,0.5,0.5,1.5,InnerShell,0.25,0.25'}
         which will add one criteria.
    """

    # report error if DictParam is not a dict
    if not isinstance(DictParam,dict):
        raise TypeError('DictParam is not a dict, DictParam=', DictParam)

    # return if is an empty dict
    if not DictParam:
        return

    IsChanged_I = [False for i in range(len(DictParam.keys()))]

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all the keys
    for icom, NameCommand in enumerate(DictParam.keys()):
        # check whether extra string is provided with () for the command to be replaced
        if '(' and ')' in NameCommand:
            commandLocal = NameCommand.split('(')[0]
            ExtraStr     = NameCommand.split('(')[1].split(')')[0]
        else:
            commandLocal = NameCommand
            ExtraStr     = None

        # loop through all lines
        for iLine, line in enumerate(lines):
            # well the line may contain the command name + ExtraStr
            commands_line = line.split()

            # skip empty line
            if len(commands_line) == 0:
                continue

            # obtain the parameter list for the command to be replaced
            strParam_I = DictParam[NameCommand].split(',')

            if commandLocal == commands_line[0][1:] and commands_line[0][0] == '#':
                # determine the length of the block of the command
                len_comm_orig = 0
                # the parameter starts at iLine+1
                while lines[iLine+1+len_comm_orig].strip() != '':
                    len_comm_orig = len_comm_orig+1
                    if iLine+1+len_comm_orig == len(lines):
                        break

                # create the new list of the command needs to be replaced
                lines_command = []
                for iParam,param_local in enumerate(strParam_I):
                    if len(strParam_I) == len_comm_orig:
                        # use the same comment if the size of the command does not change
                        # split the original line parame, the parameter starts at iLine+1
                        line_split = lines[iLine+1+iParam].split()
                        line_new   = param_local +'\t\t\t' \
                            + ' '.join(line_split[len(param_local.split()):])+'\n'
                    else:
                        # if the size changes, then no comment for the parameters...
                        line_new   = param_local + '\n'
                    lines_command.append(line_new)

                if ExtraStr != None:
                    # if ExtraStr is provided, replace the command if the
                    # line contains:
                    # 1. the ExtraStr if not DoUseMarker
                    # 2. '^' follows by ExtraStr if DoUseMarker=1
                    if ((re.search(rf'\b{ExtraStr}\b', line) and not DoUseMarker) or
                        (re.search(rf'\b{ExtraStr}\^(?=\W)', line, re.IGNORECASE) and DoUseMarker)):
                        lines[iLine+1:iLine+1+len_comm_orig] = lines_command
                        IsChanged_I[icom] = True
                elif not DoUseMarker:
                    # DoUseMarker = 0 and ExtraStr = None
                    lines[iLine+1:iLine+1+len_comm_orig] = lines_command
                    IsChanged_I[icom] = True
                else:
                    # DoUseMarker = 1 and ExtraStr = None
                    if '^' in line:
                        lines[iLine+1:iLine+1+len_comm_orig] = lines_command
                        IsChanged_I[icom] = True

    if False in IsChanged_I:
        print('--------------------------------------------------------')
        print("DictParam.keys =", DictParam.keys())
        print("IsChanged_I    =", IsChanged_I)
        sys.exit("Some commands are not replaced!!!")

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

    # return if is an empty dict
    if not DictParam:
        return

    IsChanged_I = [False for i in range(len(DictParam.keys()))]

    with open(filenameIn, 'rt') as params:
        lines = list(params)

    # loop through all lines
    for iLine, line in enumerate(lines):
        # loop through all keys
        for ikey, key in enumerate(DictParam.keys()):
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
                    IsChanged_I[ikey] = True
                else:
                    try:
                        lines[iLine] = str(value)+'\t\t\t'+key+'\n'
                        IsChanged_I[ikey] = True
                    except Exception as error:
                        raise TypeError(error, "Value cannot convert to a string.")

    if False in IsChanged_I:
        print('--------------------------------------------------------')
        print("DictParam.keys =", DictParam.keys())
        print("IsChanged_I    =", IsChanged_I)
        sys.exit("Some params are not changed!!!")

    with open(filenameOut, 'w') as file_output:
        for line in lines:
            file_output.write(line)
