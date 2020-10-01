SHELL=/bin/bash

# Include the link to the Makefile.def from the SWMF used
include Makefile.def

MYDIR   = $(shell echo `pwd -P`)
QUEDIR  = ${MYDIR}
RESDIR  = Default
IDLDIR  = ${DIR}/share/IDL/Solar

TIME = 2012,03,12,08,00

REALIZATIONS = 01,02,03,04,05,06,07,08,09,10,11,12

POYNTINGFLUX   = -1.0
POTENTIALFIELD = HARMONICS

MAP = None

START_TIME       = $(shell echo ${TIME} | tr , ' ')
REALIZATIONLIST  = $(shell echo ${REALIZATIONS} | tr , ' ')

RESTART = F

MODEL   = AWSoM

FULLRESDIR    = ${MYDIR}/Results/${RESDIR}
RunDirList    = $(sort $(dir $(wildcard ${MYDIR}/run[01][0-9]/)))
ResRunDirList = $(sort $(dir $(wildcard ${FULLRESDIR}/run[01][0-9]/)))

help : 
	@echo "************************************************************************************************"
	@echo "The script relies on swmfpy and remap_magnetogram.py that uses pyfits that is part of SWMF. "
	@echo "There are links in SWMFSOLAR/Scripts to swmfpy and pyfits. "
	@echo "     swmfpy needs the following packages: numpy. "
	@echo "The suggested python version is 3.6 or later. Check the python version in the system before running"
	@echo "the script, e.g., type python in the termianl, the launched python should show Python 3.7.0 or above."
	@echo "On Pleiades, add 'module load python3/3.7.0' in the .cashrc or .bashrc file."
	@echo "On Frontera, the default python is python2 and it is a link in /bin. One trcik that could solve this"
	@echo "issue is to make a bin folder in the home folder (~/bin), and ~/bin in the PATH, and add a link with"
	@echo "  ln -s /opt/apps/intel19/python3/3.7.0/bin/python3.7 ~/bin/"
	@echo "The exact location of python 3.7 could be obtained by which python3.7. "
	@echo ""
	@echo "Note: this script will reconfigure SWMF, but does not execute make clean to save time. "
	@echo "If make clean is needed, do it in the SWMF directory first before doing anything here."
	@echo "************************************************************************************************"
	@echo ""
	@echo "Make the AWSoM or AWSoM-R runs with a magnetogram (could be either ADAPT or GONG or MDI or HMI)"
	@echo ""
	@echo "Examples:"
	@echo "  make adapt_run MODEL=AWSoM  (run AWSoM   with 12 ADAPT realizations with B0 from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoMR (run AWSoM-R with the 12 ADAPT realizations with B0 from Harmonics)"
	@echo "  make adapt_run MODEL=AWSoM REALIZATIONS=01 MAP=hmi.dat POTENTIALFIELD=FDIPS"
	@echo "                              (run AWSoM with a single map named hmi.dat and use FDIPS)"
	@echo ""
	@echo "To run a single GONG/MDI/HMI map, use MAP=filename REALIZATIONS=01"
	@echo "(assuming here that GONG/HMI/GONG have only one realization, though this is not necessarily true.)"
	@echo ""
	@echo "It is recommended to do the post processing after all simulations are finished and then transfer "
	@echo "the results to a local machine to compare with observations. Post processing can be done with"
	@echo ""
	@echo "  make check_postproc RESDIR=event1"
	@echo ""
	@echo "which saves the results into Results/event1"
	@echo ""
	@echo "Comparing the simulations with observations is best to do on a local machine and requires SSWIDL. "
	@echo "Make sure that share/IDL/Solar is properly set up. Comparing with observations can be done with"
	@echo ""
	@echo "  make check_compare RESDIR=event1"
	@echo ""
	@echo "which compare the results in Results/event1 with observations. The observations are saved in Results/obsdata."
	@echo ""
	@echo "Options:"
	@echo " MODEL=AWSoM, which could be AWSoM or AWSoMR, case sensitive, default is AWSoM."
	@echo " POTENTIALFIELD=HARMONICS - options are HARMONICS or FDIPS, defualt is HARMONICS."
	@echo " TIME=YYYY,MM,DD,HH,MN    -  set the start time of the simulation. "
	@echo " POYNTINGFLUX=1.0e6       -  set the Poynting flux, defualt is -1, which would not adjust the Poynting flux."
	@echo " MAP=filename             -  set the input map if desired. Default is to download ADAPT maps."
	@echo " REALIZATIONS=01,02       -  list the realzations to run, MUST BE TWO DIGITS. Default is "
	@echo "   REALIZATIONS=01,02,03,04,05,06,07,08,09,10,11,12"
	@echo " More options to be added"
	@echo ""
	@echo "Notes:"
	@echo "One can set either TIME or MAP, NOT BOTH. "
	@echo "If only TIME is provided, the script tries to download the corresponding ADAPT map. "
	@echo "This works for ADAPT maps only AND requires ftp to work. On Pleiades and Frontera ftp does not work."
	@echo "If only MAP is provided, the #STARTTIME is set based on the map time."
	@echo ""

######################################################################################

adapt_run:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make compile
	make rundir
	make run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

compile:
	-@(cd ${DIR}; \
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
	-@(rm -rf ${MYDIR}/run_backup;										\
	mkdir -p ${MYDIR}/run_backup;                   							\
	mv run[01]* ${MYDIR}/run_backup/;               							\
	if [[ "${MODEL}" == "AWSoM" ]]; then 									\
		cp Param/PARAM.in.awsom PARAM.in; 								\
	else													\
		cp Param/PARAM.in.awsomr PARAM.in;								\
	fi; 													\
	if [[ "${MAP}" != "None" ]]; then									\
		${MYDIR}/Scripts/change_param.py --amap ${MAP} -p ${POYNTINGFLUX} -B0 ${POTENTIALFIELD};	\
	else													\
		${MYDIR}/Scripts/change_param.py -t ${START_TIME} -p ${POYNTINGFLUX} -B0 ${POTENTIALFIELD};	\
	fi; 													\
	for iRealization in ${REALIZATIONLIST}; do								\
		cd ${DIR}; 											\
		make rundir MACHINE=${MACHINE} RUNDIR=${MYDIR}/run$${iRealization}; 				\
		cp ${MYDIR}/PARAM.in ${MYDIR}/run$${iRealization}; 						\
		cp ${MYDIR}/JobScripts/job.${POTENTIALFIELD}.${MACHINE} ${MYDIR}/run$${iRealization}/job.long;	\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/run$${iRealization}/SC/;  			\
		cp ${DIR}/util/DATAREAD/srcMagnetogram/redistribute.pl ${MYDIR}/run$${iRealization}/SC/; 	\
	done; 		\
	cd ${MYDIR};	\
	rm -f PARAM.in; \
	rm -f map_*out; \
	)

run:
	@echo "Submitting jobs"
	for iRealization in ${REALIZATIONLIST}; do              	        		\
		cd ${MYDIR}/run$${iRealization}/SC/; 						\
		if [[ "${POTENTIALFIELD}"  == "HARMONICS" ]]; then				\
			cp ${MYDIR}/Param/HARMONICS.in ${MYDIR}/run$${iRealization}/SC/; 	\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" HARMONICS.in;		\
			./HARMONICS.exe; 							\
		fi; 										\
		if [[ "${POTENTIALFIELD}"  == "FDIPS" ]]; then					\
			cp ${MYDIR}/Param/FDIPS.in ${MYDIR}/run$${iRealization}/SC/; 		\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" FDIPS.in;		\
		fi; 										\
		cd ${MYDIR}/run$${iRealization}; 						\
		if [[ "${MACHINE}" == "frontera" ]];						\
			then perl -i -p -e "s/amap01/amap$${iRealization}/g" job.long;  	\
			sbatch job.long;							\
			./PostProc.pl -r=360 >& PostProc.log & 					\
		fi;										\
		if [[ "${MACHINE}" == "pfe" ]];                         			\
			then ./qsub.pfe.pl job.long amap$${iRealization};      			\
			./PostProc.pl -r=360 >& PostProc.log & 					\
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
				mkdir -p ${FULLRESDIR}/$${RunDir: -6:-1};                      	\
				if([ ! -d RESULTS ]); then ./PostProc.pl RESULTS; fi;   	\
				mv runlog* SC/map_*out RESULTS/*				\
					${FULLRESDIR}/$${RunDir: -6:-1}/;			\
				if [[ -f SC/fdips_bxyz.out ]]; then          			\
					mv SC/fdips_bxyz.out SC/FDIPS.in 			\
						${FULLRESDIR}/$${RunDir: -6:-1}/; 		\
				fi;								\
				if [[ -f SC/harmonics_adapt.dat ]]; then			\
					mv SC/harmonics_adapt.dat SC/HARMONICS.in               \
						${FULLRESDIR}/$${RunDir: -6:-1}/ ;		\
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
	@cd ${IDLDIR}; 										\
	for RunDir in ${ResRunDirList};  do 							\
		csh compare_insitu.sh ${DIR} $${RunDir}/IH $${RunDir}; 				\
		csh compare_remote.sh ${DIR} $${RunDir}/SC $${RunDir} ${MYDIR}/Results/obsdata; \
	done

#########################################################################################

clean_plot:
	for RunDir in ${ResRunDirList};  do 	\
		cd $${RunDir}; 			\
		rm -f *eps; 			\
		rm -f log_insitu log_remote; 	\
	done
