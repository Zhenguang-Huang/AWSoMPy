SHELL=/bin/bash

# Include the link to the Makefile.def from the SWMF used
include Makefile.def

MYDIR  = $(shell echo `pwd -P`)
SIMDIR = Default
RESDIR = Default
IDLDIR = ${DIR}/share/IDL/Solar

MODEL = AWSoM
PFSS  = HARMONICS

TIME  = NoTime
MAP   = NoMap

POYNTINGFLUX   = -1.0

REALIZATIONS    = 1,2,3,4,5,6,7,8,9,10,11,12
REALIZATIONLIST = $(foreach v, $(shell echo ${REALIZATIONS} | tr , ' '), $(shell printf '%02d' $(v)))

RESTART  = F

JOBNAME  = amap

FULLRESDIR    = ${MYDIR}/Results/${RESDIR}
RunDirList    = $(sort $(dir $(wildcard ${MYDIR}/${SIMDIR}/run[01][0-9]/)))
ResRunDirList = $(sort $(dir $(wildcard ${FULLRESDIR}/run[01][0-9]/)))

help: 
	@echo "*******************************************************************************"
	@echo "The script relies on swmfpy and remap_magnetogram.py that uses pyfits that is "
	@echo "part of SWMF. "
	@echo ""
	@echo "There are links in SWMFSOLAR/Scripts to swmfpy and pyfits. "
	@echo "   swmfpy needs the following packages: numpy. "
	@echo "The suggested python version is 3.6 or later. Check the python version in the "
	@echo "system before running the script, e.g., enter python in the termianl, the "
	@echo "launched python should show Python 3.7.0 or above. "
	@echo ""
	@echo "On Pleiades, add 'module load python3/3.7.0' in the .cashrc or .bashrc file."
	@echo "On Frontera, the default python is python2 and it is a link in /bin. One trcik "
	@echo "that could solve this issue is to make a bin folder in the home folder (~/bin),"
	@echo "and add it in the PATH (e.g., setenv PATH ~/bin/:${PATH}. The order matters!)."
	@echo "Then add a link as:"
	@echo "  ln -s /opt/apps/intel19/python3/3.7.0/bin/python3.7 ~/bin/python"
	@echo "The exact location of python 3.7 could be obtained by which python3.7. "
	@echo "*******************************************************************************"
	@echo ""
	@echo "Make the AWSoM or AWSoM-R runs with a magnetogram:"
	@echo ""
	@echo "Examples:"
	@echo "  make adapt_run_w_compile MODEL=AWSoM  "
	@echo "       (configure SWMF and run AWSoM with 12 ADAPT realizations with B0 "
	@echo "        from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoM  "
	@echo "       (run AWSoM   with 12 ADAPT realizations with B0 from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoMR "
	@echo "       (run AWSoM-R with the 12 ADAPT realizations with B0 from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoM REALIZATIONS=01 MAP=hmi.dat PFSS=FDIPS"
	@echo "       (run AWSoM with a single map named hmi.dat and use FDIPS)"
	@echo ""
	@echo "To run a single GONG/MDI/HMI map, use MAP=filename REALIZATIONS=01"
	@echo "(assuming here that GONG/HMI/GONG have only one realization, though this is "
	@echo "not true.)"
	@echo ""
	@echo "*******************************************************************************"
	@echo "Note: adapt_run will NOT re-configure/compile SWMF, assuming SWMF is correctly"
	@echo "configured and compiled. If the user would like to re-configure/compile SWMF "
	@echo "(e.g., making the first run(s) in SWMFSOLAR or after updating SWMF), "
	@echo "use adapt_run_w_compile instead of adapt_run, which will uninstall SWMF, then "
	@echo "install SWMF and compile it. This whole process would take substantial time. "
	@echo "After making the first run or without updating SWMF, adapt_run is sufficient "
	@echo "and could save lots of time for installation and compilation."
	@echo "*******************************************************************************"
	@echo ""
	@echo "It is recommended to do the post processing after all simulations are finished "
	@echo "and then transfer the results to a local machine to compare with observations. "
	@echo "Post processing can be done with"
	@echo ""
	@echo "  make check_postproc RESDIR=event1"
	@echo ""
	@echo "which saves the results into Results/event1"
	@echo ""
	@echo "Comparing the simulations with observations is best to do on a local machine "
	@echo "and requires SSWIDL. Make sure that share/IDL/Solar is properly set up. "
	@echo "Comparing with observations can be done with"
	@echo ""
	@echo "  make check_compare RESDIR=event1 MODEL=AWSoMR"
	@echo ""
	@echo "which compare the results in Results/event1 with observations. The observations"
	@echo "are saved in Results/obsdata. MODEL is needed for AWSoM-R runs to correctly "
	@echo "write the legend in the in-situ plot."
	@echo ""
	@echo "Options:"
	@echo " MODEL=AWSoM               - set the model, either AWSoM or AWSoMR, case "
	@echo "                             sensitive, default is AWSoM."
	@echo " SIMDIR=run01_test         - set the name for the simulation directory, default "
	@echo "                             is Default. "
	@echo " RESDIR=run01_test         - set the name for the result directory, default is "
	@echo "                             Default."
	@echo " PFSS=HARMONICS,           - set the potential field solover, either HARMONICS "
	@echo "                             or FDIPS, defualt is HARMONICS."
	@echo " TIME=2012-1-1T1:1:1       - set the start time of the simulation, format is "
	@echo "                             YYYY-MM-DDTHH:MM:SC, default is NoTime (meaning "
	@echo "                             the start time is obtained from the map)."
	@echo " POYNTINGFLUX=1.0e6,       - set the Poynting flux, defualt is -1, which would"
	@echo "                             not adjust the Poynting flux."
	@echo " MAP=filename              - set the input map if desired. Default is NoMap."
	@echo " REALIZATIONS=1,2          - list the realzations to run. Default is 1,2,3,4,5,"
	@echo "                             6,7,8,9,10,11,12. "
	@echo " JOBNAME=amap              - set the job name, default is amap. The submitted"
	@echo "                             job name would have the realzation number at the"
	@echo "                             end, e.gn. amap01, amap12. Some systems have a "
	@echo "                             limitation of the total length (e.g., 6 chars in"
	@echo "                             total)."
	@echo " More options to be added"
	@echo ""
	@echo "Notes:"
	@echo "User can set either TIME or MAP, or BOTH. And the following will occur:"
	@echo " 1. Both TIME and MAP are provided. The script will use the map and set the "
	@echo "    start time based on TIME."
	@echo " 2. Only TIME is provided. The script will download the ADAPT map and set the "
	@echo "    start time based on TIME."
	@echo " 3. Only MAP is provided. The script will use the map and set the start time "
	@echo "    based on the info from the map."
	@echo ""

######################################################################################

adapt_run_w_compile:
	@echo "Submitting AWSoM runs with a ADAPT map with re-compiling the code."
	make compile
	make rundir
	make run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

adapt_run:
	@echo "Submitting AWSoM runs with a ADAPT map without re-compiling the code."
	make rundir
	make run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

compile:
	-@(cd ${DIR}; \
	./Config.pl -uninstall; 							\
	./Config.pl -install; 								\
	./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; 					\
	if [[ "${MODEL}" == "AWSoM" ]]; then 						\
		./Config.pl -o=SC:u=AwsomFluids,e=MhdWavesPeAnisoPi,nG=3; 		\
		./Config.pl -o=IH:u=AwsomFluids,e=MhdWavesPeAnisoPi,nG=3; 		\
	else										\
		./Config.pl -o=SC:u=ScChromo,e=MhdWavesPe,nG=3; 			\
		./Config.pl -o=IH:u=ScChromo,e=MhdWavesPe,nG=3; 			\
	fi; 										\
	./Config.pl -g=SC:6,8,8,IH:8,8,8; 						\
	make -j SWMF PIDL; 								\
	cd ${DIR}/util/DATAREAD/srcMagnetogram; 					\
	make HARMONICS FDIPS; 								\
	cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ -L ${MYDIR}/Scripts/swmfpy ]); then					\
		rm -f ${MYDIR}/Scripts/swmfpy; 						\
	fi;										\
	if([ -L ${MYDIR}/Scripts/pyfits ]); then					\
		rm -f ${MYDIR}/Scripts/pyfits; 						\
	fi;										\
	ln -s ${DIR}/share/Python/swmfpy/swmfpy ${MYDIR}/Scripts/swmfpy; 		\
	ln -s ${DIR}/share/Python/pyfits ${MYDIR}/Scripts/pyfits; 			\
	)

rundir:
	@echo "Creating rundirs"
	-@(rm -rf ${MYDIR}/${SIMDIR}/run_backup;									\
	mkdir -p ${MYDIR}/${SIMDIR}/run_backup;                   							\
	mv ${MYDIR}/${SIMDIR}/run[01]* ${MYDIR}/${SIMDIR}/run_backup/;               					\
	if [[ "${MODEL}" == "AWSoM" ]]; then 										\
		cp Param/PARAM.in.awsom PARAM.in; 									\
	else														\
		cp Param/PARAM.in.awsomr PARAM.in;									\
	fi; 														\
	cp Param/HARMONICS.in Param/FDIPS.in .; 									\
	${MYDIR}/Scripts/change_param.py --map ${MAP} -t ${TIME} -p ${POYNTINGFLUX} -B0 ${PFSS};			\
	for iRealization in ${REALIZATIONLIST}; do									\
		cd ${DIR}; 												\
		make rundir MACHINE=${MACHINE} RUNDIR=${MYDIR}/${SIMDIR}/run$${iRealization}; 				\
		cp ${MYDIR}/PARAM.in     ${MYDIR}/${SIMDIR}/run$${iRealization}; 					\
		cp ${MYDIR}/HARMONICS.in ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 					\
		cp ${MYDIR}/FDIPS.in     ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 					\
		cp ${MYDIR}/JobScripts/job.${PFSS}.${MACHINE} ${MYDIR}/${SIMDIR}/run$${iRealization}/job.long;		\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/;  			\
		cp ${DIR}/util/DATAREAD/srcMagnetogram/redistribute.pl ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 	\
	done; 					\
	cd ${MYDIR};				\
	rm -f PARAM.in HARMONICS.in FDIPS.in;	\
	rm -f map_*.out; 			\
	)

run:
	@echo "Submitting jobs"
	-@for iRealization in ${REALIZATIONLIST}; do              	        		\
		cd ${MYDIR}/${SIMDIR}/run$${iRealization}/SC/; 					\
		if [[ "${PFSS}"  == "HARMONICS" ]]; then					\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" HARMONICS.in;		\
			./HARMONICS.exe; 							\
		fi; 										\
		if [[ "${PFSS}"  == "FDIPS" ]]; then						\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" FDIPS.in;		\
		fi; 										\
		cd ${MYDIR}/${SIMDIR}/run$${iRealization}; 					\
		if [[ "${MACHINE}" == "frontera" ]];						\
			then perl -i -p -e "s/amap01/${JOBNAME}$${iRealization}/g" job.long;  	\
			sbatch job.long;							\
		fi;										\
		if [[ "${MACHINE}" == "pfe" ]];                         			\
			then ./qsub.pfe.pl job.long ${JOBNAME}$${iRealization};      		\
		fi; 										\
	done

#########################################################################################

check_postproc:
	@if([ ! -d ${MYDIR}/Results/${RESDIR} ]); then                   			\
		rm -f error_postproc.log; 							\
		echo "Post processing simulation results to Results/${RESDIR}";			\
		for RunDir in ${RunDirList};  do                              			\
			echo "processing rundir = $${RunDir}";					\
			cd $${RunDir};                                    			\
			if([ -f SWMF.SUCCESS ]); then                              		\
				mkdir -p ${FULLRESDIR}/$${RunDir: -6:5};                      	\
				if([ ! -d RESULTS ]); then ./PostProc.pl RESULTS; fi;   	\
				mv SC/map_*out RESULTS/*					\
				   ${FULLRESDIR}/$${RunDir: -6:5}/;				\
				if [[ -f SC/fdips_bxyz.out ]]; then          			\
					mv SC/fdips_bxyz.out SC/FDIPS.in 			\
						${FULLRESDIR}/$${RunDir: -6:5}/; 		\
				fi;								\
				if [[ -f SC/harmonics_adapt.dat ]]; then			\
					mv SC/harmonics_adapt.dat SC/HARMONICS.in               \
						${FULLRESDIR}/$${RunDir: -6:5}/ ;		\
				fi;								\
			else									\
				echo "$${RunDir} crashed" >> ${MYDIR}/error_postproc.log;	\
			fi; 									\
		done;										\
	else                                                            			\
		echo "${RESDIR} already exists; skip post processing.";				\
	fi

#########################################################################################

check_compare:
	make check_compare_insitu
	make check_compare_remote

check_compare_insitu:
	-@(cd ${IDLDIR}; 									\
	for RunDir in ${ResRunDirList};  do 							\
		csh compare_insitu.sh ${DIR} $${RunDir}/IH $${RunDir} ${MODEL}; 		\
	done)

check_compare_remote:
	-@(cd ${IDLDIR}; 									\
	for RunDir in ${ResRunDirList};  do 							\
		csh compare_remote.sh ${DIR} $${RunDir}/SC $${RunDir} ${MYDIR}/Results/obsdata; \
	done)

#########################################################################################

clean_plot:
	for RunDir in ${ResRunDirList};  do 	\
		cd $${RunDir}; 			\
		rm -f *eps; 			\
		rm -f log_insitu log_remote; 	\
	done
