**Script**:
writeRestartRunsToFile.jl:
This script will write a `param_list` with the following components:
1) Event specific params (to be read in from a file such as EEGGL_Params_CR2154.txt). Will begin with header `#CME`.
2) Background runs - these will only consist of params downselected from sensitivity analysis, sampled from their respective posterior distributions that data assimilation provides. This is also read in from a file.
3) Restart runs. We specify which background runs we want to restart and insert a flux rope into, the params for these are calculated with formulae that use the event specific params read in 1) and Design Parameters sampled from uniform distributions imposed on their respective ranges. 

writeSEPBackgroundList.jl
Write param list for background parameters.

Process to run:
- Navigate to ParamListScripts, and go to Julia REPL
```julia
julia> using Pkg
julia> Pkg.activate()
julia> Pkg.resolve()     # rebuild Manifest if dependencies have changed
julia> Pkg.instantiate() # install packages for environment as specified by Manifest
```
- run script from 
1) the Julia REPL using `include("path/to/writeRestartRunsToFile.jl)` 
OR 
2) use the `Execute File in REPL` command if using VSCode. 
OR
3) the Terminal / shell via `julia --project=. writeRestartRunsToFile.jl`

These options will only parse default arguments so we will need to manually change the defaults if a different `param_list` is desired.

- In the terminal, type
`julia --project=. writeRestartRunsToFile.jl --help` 
to list all options
```
usage: writeRestartRunsToFile.jl [--fileEEGGL FILEEEGGL]
                        [--fileBackground FILEBACKGROUND]
                        [--fileRestart FILERESTART]
                        [--fileOutput FILEOUTPUT] [--mg MG] [--cr CR]
                        [--md MD] [--start_time START_TIME]
                        [--restartID RESTARTID] [-h]

Generate run list for background and restart

optional arguments:
  --fileEEGGL FILEEEGGL
                        Path to load EEGGL Params from. (default:
                        "./output/restartRunDesignFiles/EEGGLParams_CR2154.txt")
  --fileBackground FILEBACKGROUND
                        Path to load background wind runs from.
                        (default:
                        "./output/restartRunDesignFiles/Params_MaxPro_postdist.csv")
  --fileRestart FILERESTART
                        Path to load restart runs from. (default:
                        "./output/restartRunDesignFiles/X_design_CME_2021_10_18.csv")
  --fileOutput FILEOUTPUT
                        Give path to file where we wish to write param
                        list (default:
                        "./output/param_list_2021_10_19.txt")
  --mg MG               Magnetogram to use, for example, GONG.
                        (default: "ADAPT")
  --cr CR               CR to use eg: 2152. (type: Int64, default:
                        2154)
  --md MD               Model to use, for example AWSoM, AWSoMR,
                        AWSoM2T. (default: "AWSoM")
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
                        double quotes, and parsing functions in the
                        script take care of the rest. (default: "all")
  -h, --help            show this help message and exit
```


To generate a new list of restart runs, the command may be for example:
`julia --project=. writeRestartRunsToFile.jl --cr=2152`

To generate a new background params list for SEP event, the command may be for example:
`julia --project=. writeSEPBackgroundList.jl --nRuns=500 --fileParam="../Param/PARAM.in.awsomr.SCIHOH"`

The output from this will be:
bash```
Valid PARAM file provided
Wrote background runs
The PARAM file gives the following results when checking keywords:
1.0                     FactorB0 BrFactor^
1e6                     PoyntingFluxPerBSi
1.5e5                   LperpTimesSqrtBSi^
1.5e5                   LperpTimesSqrtBSi^
1.5e5                   LperpTimesSqrtBSi
Successfully wrote runs to file ./output/sep_param_lists/param_list_2022_03_14.txt
```

The above has:
1) Checking if a _valid_ PARAM file name is supplied, to avoid errors in case for example.

2) grepping the keywords written from script in the PARAM file to provide basic check that correct keywords have been written. We can open PARAM file manually for detailed checking.

