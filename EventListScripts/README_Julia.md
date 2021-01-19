# Details for viewing and running Julia scripts

## Downloading Julia:

1) Go to [the Julia Website](https://julialang.org)

2) Click on the `Download` tab.

3) This should open a page with details of the latest stable release (currently v1.5.3)

4) Download the correct installer according to your operating system

5) For older releases, visit [the Older Releases page](https://julialang.org/downloads/oldreleases/). Note that while you are free to use these, they are no longer developed or maintained actively.

6) Once the installation is complete, open the Julia REPL and you should be ready to go. If you wish to use an editor or a specific IDE with Julia, check out options like the [Juno IDE](https://junolab.org/) or the [VS Code Extension](https://www.julia-vscode.org/) for Julia. You can also use Julia in Jupyter notebooks!

VS Code Extension is the currently supported IDE, so it is one of the preferred ways (though not necessarily the best way) to use Julia. It can be setup through the instructions provided here: (https://www.julia-vscode.org/docs/stable/gettingstarted/) Any other setup that's convenient for the user is also fine (for example, a text editor like `Vim`  open side by side with the REPL - see these [Workflow Tips](https://docs.julialang.org/en/v1/manual/workflow-tips/))

## IDEs: 

[Juno](https://junolab.org/) is an IDE based on [Atom](https://atom.io/) for the Julia language. Another popular environment for Julia is the [VS Code] (https://www.julia-vscode.org/) Extension. In addition, Julia also offers great plugins for widely-used text editors like [Vim](https://github.com/JuliaEditorSupport/julia-vim), [Emacs](https://github.com/JuliaEditorSupport/julia-emacs) and [Notepad++](https://github.com/JuliaEditorSupport/julia-NotepadPlusPlus). 

## Activating the environment & Execution: 

Two files `Project.toml` and `Manifest.toml` are included in the scripts folder. These collectively define the project environment and any packages and dependencies that need to be installed for running the various scripts. They are machine generated files and update automatically every time any action is taken regarding addition, removal or changes to packages. To activate the project, `cd` to the directory path, launch Julia and at the Julia prompt, enter the Package mode via `]` . This should change the prompt from `julia >` to something on the lines of `@(v1.5) pkg >`. Now type `activate .`, and this should change the prompt to `(SelectInputRuns) pkg>`. (To go back to `julia>` prompt, hit Backspace). Now the correct environment has been set. If you are viewing the files in VS Code, assuming the Julia extension for the same is installed, the following steps should be taken: 

1) Go to `View` on the top ribbon, and select `Command Palette`.  Type `Julia start REPL` and select the search result `Julia: Start REPL`. This should open up the Julia prompt in the `Terminal` section of the IDE. Open the folder where the scripts are stored through `File > Open Folder`. 

2) At the bottom left of the screen, click on `Julia: v1.5`. At the top of the screen, you should be prompted to select an environment. Select the folder opened previously, and the correct environment should load (this can take some time the first time around). 

3) To execute individual files, the simplest way is to open up a file by double clicking on file name in the file tree (typically under `Untitled (Workspace)`). Then open the `Command Palette` again and type `Julia execute file`. Select the correct entry `Julia: Execute file` and the output should appear, with all created variables showing up in `Julia Explorer: Julia Workspace`.  To execute individual chunks of code in the file, select the desired lines and press `Alt-Enter`. Alternately, open the `Command Palette` and select `Julia: Execute Code and Move`. 

4) In case of errors like: `ArgumentError: Package foo not found in current path`, enter Package mode through `]` and type `add foo`.  Please reach out if any issues are encountered in running the files, or if there are missing files. To use the relevant package's methods,  you need to type `using <Package Name>` in the REPL or in a script. 

**Note**: To exit Package mode, or any other mode, hit the Backspace key. To access help for a command, type `?` at the `julia>` prompt and the prompt should change to `help>`. In Linux and Mac, shell commands can also be accessed by typing `;`, this will change the prompt to `shell>`. Alternately, similar methods are implemented in regular prompt as well, such as `pwd()` and `mkdir()`. 

## Details of the files:

### 1) Modules:

**SelectInputs.jl**: This module contains functions as well as data type needed to define a new random variable type, which not only samples from uniform distribution with lower and upper bound but can also revert to a default setting of parameter with some user defined probability. This probability is set to zero by default, but can be initialized by user if needed. 

**LHSDesign.jl**: This module contains functions needed to create a design matrix via Latin Hypercube Sampling. The current approach used is a so-called "maximin LHS" that tries to select a design from space of possible LH Designs by maximizing minimum distance between design points. We make use of a simple update method that runs for a certain number of iterations (we have called it for 100 iterations in our script). This method is implemented in our module. Note that some variables, like `pfss`, `REALIZATIONS_ADAPT` take discrete values and therefore can not be created with the above LHS. Instead, they are sampled from respective distributions and their columns are concatenated with proposed LHS design to give the final design matrix. 

### 2) Scripts:

**writeLHSRunsToFile.jl**: Making use of the modules we have created, we now generate an array with LHS Design runs and convert it to appropriate text file in the format `YYYY_MM_DD_HH_MM_SS_event_list.txt`.  For full details of the conversion, refer to code comments. The basic procedure is to convert the array into a DataFrame and use the column headings of the DataFrame as well as the individual rows to print strings in the correct format for the `event_list` file. 

**writeBaselineRunsToFile.jl**: Here, all the remaining parameters are set to default values, hence not written to the text file. Instead, runs based on the groups for `model`, `Carrington Rotation` and `magnetogram` are written (16 in total). The implementation is similar to the script for writing LHS runs. 

Sample Outputs from the above scripts are in a separate subdirectory called `SampleOutputs`. 

## Sources for help:

1) The Julia documentation is fairly comprehensive, and is available for several releases of the language, including `v1.5.3`. Access it at [Julia Docs](https://docs.julialang.org/en/v1/)

2) Stack Overflow is often helpful, searching for `how to do xxxx in Julia` will usually lead to useful results. 

3) The Julia language [Discourse forum](https://discourse.julialang.org/) has threads categorized according to domains of application, like Statistics, Modelling & Simulations, as well as general usage and workflows. 

The community for Julia is gradually growing, and it is possible once in a while to encounter something unusual without clear help from the above sources. For the most part however, it should be a fairly good experience to write working scripts in Julia. There are interesting syntactic elements of the language, having something in common with other popular programming environments as well as its own distinct flavour. The `Noteworthy Differences` page (https://docs.julialang.org/en/v1/manual/noteworthy-differences/) is a good starting point to explore when writing Julia code or converting from another environment. 

