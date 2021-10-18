**Script**:
writeRestartRunsToFile.jl:
This script will write a `param_list` with the following components:
1) Event specific params (to be read in from a file such as EEGGL_Params_CR2154.txt). Will begin with header `#CME`.
2) Background runs - these will only consist of params downselected from sensitivity analysis, sampled from their respective posterior distributions that data assimilation provides. This is also read in from a file.
3) Restart runs. We specify which background runs we want to restart and insert a flux rope into, the params for these are calculated with formulae that use the event specific params read in 1) and Design Parameters sampled from uniform distributions imposed on their respective ranges. 


Options:
- run from the Julia REPL using `include("path/to/writeRestartRunsToFile.jl` or use the `Execute File in REPL` command if using VSCode. Note that both these options will only parse default arguments so we will need to manually change the defaults if a different `param_list` is desired.

- (Preferred): Navigate to `ParamListScripts` in the Terminal / shell and type:
`julia --project=. writeRestartRunsToFile.jl --help` and if all goes well, the following help message should show up (at the time of writing, 2021/10/16):
```
usage: writeRestartRunsToFile.jl [--mg MG] [--cr CR] [--md MD]
                        [--fileEEGGL FILEEEGGL]
                        [--fileBackground FILEBACKGROUND]
                        [--fileRestart FILERESTART]
                        [--start_time START_TIME]
                        [--restartID RESTARTID] [-h]

Generate event list for background and restart

optional arguments:
  --mg MG               Magnetogram to use, for example, GONG.
                        (default: "ADAPT")
  --cr CR               CR to use eg: 2152. (type: Int64, default:
                        2154)
  --md MD               Model to use, for example AWSoM, AWSoMR,
                        AWSoM2T. (default: "AWSoM")
  --fileEEGGL FILEEEGGL
                        Path to load EEGGL Params from. (default:
                        "./output/restartRunDesignFiles/EEGGLParams_CR2154.txt")
  --fileBackground FILEBACKGROUND
                        Path to load background wind runs from.
                        (default:
                        "./output/restartRunDesignFiles/Params_MaxPro_postdist.csv")
  --fileRestart FILERESTART
                        Path to load restart runs from. (default:
                        "./output/restartRunDesignFiles/X_design_CME_2021_10_15.csv")
  --start_time START_TIME
                        start time to use for background. Can give
                        yyyy-mm-ddThh:mm:sec:fracsec (default:
                        "MapTime")
  --restartID RESTARTID
                        give one or more selected background runs to
                        which to apply restarts. defaults to 'all',
                        i.e. all backgrounds are used.        If for
                        eg, '5' is supplied, then restartdir will be
                        printed as `run005_MODEL` where MODEL can be,
                        say, AWSoM        If for eg, '1 3 5 7' is
                        supplied, and nRestart > nBackground, then we
                        will cycle through 1, 3, 5, and 7 till restart
                        runs are written.         It is flexible in
                        that we can give '1, 3, 5, 7', '1,3,5,7' or '1
                        3 5 7' and all are valid.        Another
                        option is to specify a range directly, for eg
                        '1:2:8' will return the same output. Another
                        valid range example is '1:100'.        Note
                        that all these arguments have to supplied in
                        double quotes, and parsing functions take care
                        of the rest. (default: "all")
  -h, --help            show this help message and exit
```

Some of the important arguments: 

we can supply paths to EEGGL Params, background and restart design files, a start time to use for background (which will revert to MapTime if not given) and one or more backgrounds to be restarted under "--restartID", which will revert to using all backgrounds as the default behaviour.

To generate a new list, the command may be for example:
`julia --project=. writeRestartRunsToFile.jl --restartID "1, 4, 5, 9, 15" --cr=2152`

The document will be likely updated as further changes are made. 

