SHELL=/bin/bash

include ../Makefile.def

MYDIR       = ${DIR}/SWMFSOLAR
QUEDIR      = $(MYDIR)
RESDIR      = Default
IDLDIR      = ${DIR}/share/IDL/Solar

TIME = 2012,03,12,08,00

REALIZATIONS = 01,02,03,04,05,06,07,08,09,10,11,12

POYNTINGFLUX   = 1.0e6
POTENTIALFIELD = HARMONICS

MAP = NONE

START_TIME       = $(shell echo ${TIME} | tr , ' ')
REALIZATIONLIST  = $(shell echo ${REALIZATIONS} | tr , ' ')

help : 
	@echo "************************************************************************************************"
	@echo "The script relies on swmfpy and remap_magnetogram. Make sure that all the python modules are "
	@echo "installed correctly: "
	@echo "     swmfpy needs the following packages: numpy."
	@echo "The suggested python versio is >3.6. On Pleiades, add 'module load python3/3.7.0' in .cshrc or "
	@echo ".bash_profile. Similar setting should be applied on Frontera. No virtual environment is needed "
	@echo "at this point as there are links in Scripts to swmfpy and pyfits. "
	@echo ""
	@echo "Another note: this script will reconfigure SWMF, but would not do make clean to save time. If "
	@echo "make clean is needed, do it in the SWMF directory first before doing anything here."
	@echo "************************************************************************************************"
	@echo ""
	@echo "Make the AWSoM or AWSoM-R runs with the ADAPT map of 12 realzations"
	@echo ""
	@echo "Examples:"
	@echo "  make awsom_adapt    (run AWSoM   with the 12 realzations ADAPT map with B0 from Harmonics expansion)"
	@echo "  make awsomr_adapt   (run AWSoM-R with the 12 realzations ADAPT map with B0 from Harmonics expansion)"
	@echo ""
	@echo "It is recommended to do the post processing after all simulations are finished and then transfer the "
	@echo "results to a local machine to compare the results with observations. Post processing can be done with"
	@echo ""
	@echo "  make check_postproc RESDIR=event1"
	@echo ""
	@echo "which saves the results into Results/event1"
	@echo ""
	@echo "Comparing the simulations with observations is suggested to do on a local machine and requires SSWIDL. "
	@echo "Make sure that share/IDL/Solar is properly set up. Comparing with observations can be done with"
	@echo ""
	@echo "  make check_compare RESDIR=event1"
	@echo ""
	@echo "which compare the results in Results/event1 with observations. The observations are saved in Results/obsdata."
	@echo ""
	@echo "Options:"
	@echo " POTENTIALFIELD=HARMONICS, which could be HARMONICS or FDIPS, defualt is HARMONICS "
	@echo " TIME=YYYY,MM,DD,HH,MN, which specifies the start time of the simulation "
	@echo " POYNTINGFLUX=1.0e6, which specifies the poynting flux, defualt is 1.0e6 "
	@echo " REALIZATIONS=01,02, which specifies the realzations need to run, MUST BE TWO DIGITS"
	@echo " MAP=***.fts, which specifies the ADAPT map if desired"
	@echo " More options to be added"
	@echo ""
	@echo "Notes:"
	@echo "Users could provide either TIME or MAP or BOTH. If both are provided, the map time and TIME should"
	@echo "be consistent up to hours. If only TIME is provided (without MAP), the script would try to download"
	@echo "the ADAPT map. On some Pleiades and Fronetra, it is known that the ftp download does not work. "
	@echo "If only MAP is provided, the #STARTTIME would be set based on the map time."

######################################################################################

awsom_adapt:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make awsom_compile
	make awsom_rundir
	make awsom_run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

awsom_compile:
	-@(cd ${DIR}; \
	./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; 			\
	./Config.pl -o=SC:u=AwsomFluids,e=MhdWavesPeAnisoPi,nG=3; 	\
	./Config.pl -o=IH:u=AwsomFluids,e=MhdWavesPeAnisoPiSignB,nG=3; 	\
	./Config.pl -g=SC:6,8,8,IH:8,8,8; 	\
	make -j SWMF PIDL; 			\
	cd ${DIR}/util/DATAREAD/srcMagnetogram; \
	make HARMONICS FDIPS; 			\
	cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ ! -L ${MYDIR}/Scripts/swmfpy ]); then					\
		ln -s ${DIR}/share/Python/swmfpy/swmfpy ${MYDIR}/Scripts/swmfpy; 	\
	fi;										\
	if([ ! -L ${MYDIR}/Scripts/pyfits ]); then					\
		ln -s ${DIR}/share/Python/pyfits ${MYDIR}/Scripts/pyfits; 		\
	fi;										\
	)

awsom_rundir:
	@echo "Creating rundirs"
	rm -rf ${MYDIR}/run_backup;                     \
	mkdir -p ${MYDIR}/run_backup;                   \
	mv run[01]* ${MYDIR}/run_backup/;               \
	cp Param/PARAM.in.awsom PARAM.in
	${MYDIR}/Scripts/change_param.py --map ${MAP} -t ${START_TIME} -p ${POYNTINGFLUX} -B0 ${POTENTIALFIELD}
	for iRealization in ${REALIZATIONLIST}; do					\
		cd $(DIR); 								\
		make rundir MACHINE=${MACHINE} RUNDIR=${MYDIR}/run$${iRealization}; 	\
		cp ${MYDIR}/PARAM.in ${MYDIR}/run$${iRealization}; 			\
		cp ${MYDIR}/Input/job.${POTENTIALFIELD}.${MACHINE} ${MYDIR}/run$${iRealization}/job.long;	\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/run$${iRealization}/SC/;  			\
		cp ${DIR}/util/DATAREAD/srcMagnetogram/redistribute.pl ${MYDIR}/run$${iRealization}/SC/; 	\
	done
	rm -f PARAM.in
	rm -f map_*out

awsom_run:
	@echo "Submitting jobs"
	for iRealization in ${REALIZATIONLIST}; do              	        		\
		if [[ "${POTENTIALFIELD}"  == "HARMONICS" ]]; then				\
			cp ${MYDIR}/Param/HARMONICS.in ${MYDIR}/run$${iRealization}/SC/; 	\
			cd ${MYDIR}/run$${iRealization}/SC/; 					\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" HARMONICS.in;		\
			HARMONICS.exe; 								\
			cd ${MYDIR}/run$${iRealization};					\
			if [[ "${MACHINE}" == "frontera" ]];					\
				then perl -i -p -e "s/amap01/amap$${iRealization}/g" job.long;  \
				sbatch job.long;						\
			fi;									\
			if [[ "${MACHINE}" == "pfe" ]];                         		\
				then ./qsub.pfe.pl job.long amap$${iRealization};      		\
			fi; 									\
		fi; 										\
		if [[ "${POTENTIALFIELD}"  == "FDIPS" ]]; then					\
			cp ${MYDIR}/Param/FDIPS.in ${MYDIR}/run$${iRealization}/SC/; 	\
			cd ${MYDIR}/run$${iRealization}/SC/; 					\
			perl -i -p -e "s/map_1/map_$${iRealization}/g" FDIPS.in;		\
			cd ${MYDIR}/run$${iRealization}; 					\
			if [[ "${MACHINE}" == "frontera" ]];					\
				then perl -i -p -e "s/amap01/amap$${iRealization}/g" job.long;	\
				sbatch job.long; 						\
			fi;									\
			if [[ "${MACHINE}" == "pfe" ]];                                         \
				then ./qsub.pfe.pl job.long amap$${iRealization};		\
			fi;									\
		fi; 										\
	done

#########################################################################################

awsomr_adapt:
	@echo "Submitting AWSoM-R runs with a ADAPT map."
	make awsomr_compile
	make awsomr_rundir
	make awsom_run
	@echo "Finished submitting AWSoM-R runs with a ADAPT map."

awsomr_compile:
	-@(cd ${DIR}; \
	./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; \
	./Config.pl -o=SC:u=ScChromo,e=MhdWavesPeAnisoPi,nG=3; \
	./Config.pl -o=IH:u=ScChromo,e=MhdWavesPeAnisoPiSignB,nG=3; \
	./Config.pl -g=SC:6,8,8,IH:8,8,8; \
	make -j SWMF PIDL; \
	make NOMPI; 				\
	cd ${DIR}/util/DATAREAD/srcMagnetogram; \
	make HARMONICS FDIPS; \
	cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ ! -L ${MYDIR}/Scripts/swmfpy ]); then					\
		ln -s ${DIR}/share/Python/swmfpy/swmfpy ${MYDIR}/Scripts/swmfpy; 	\
	fi;										\
	)

awsomr_rundir:
	@echo "Creating rundirs"
	rm -rf ${MYDIR}/run_backup;                     \
	mkdir -p ${MYDIR}/run_backup;                   \
	mv run[01]* ${MYDIR}/run_backup/;               \
	cp Param/PARAM.in.awsomr PARAM.in
	${MYDIR}/Scripts/change_param.py -t ${START_TIME} -p ${POYNTINGFLUX}
	for iRealization in ${REALIZATIONLIST}; do					\
		cd $(DIR); 								\
		make rundir MACHINE=${MACHINE} RUNDIR=${MYDIR}/run$${iRealization}; 	\
		cp ${MYDIR}/PARAM.in ${MYDIR}/run$${iRealization}; 			\
		cp ${MYDIR}/Input/job.${POTENTIALFIELD}.${MACHINE} ${MYDIR}/run$${iRealization}/job.long;	\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/run$${iRealization}/SC/;  \
		cp ${DIR}/util/DATAREAD/srcMagnetogram/redistribute.pl ${MYDIR}/run$${iRealization}/SC/; \
	done
	rm -f PARAM.in
	rm -f map_*out


#########################################################################################

FULLRESDIR  = ${MYDIR}/Results/${RESDIR}
RunDirList  = $(sort $(dir $(wildcard run[01][1-9]/)))

check_postproc:
	@if([ ! -d ${MYDIR}/Results/${RESDIR} ]); then                   		\
		echo "Post processing simulation results to Results/${RESDIR}";		\
		for RunDir in ${RunDirList};  do                              		\
			cd ${MYDIR}/$${RunDir};                                    	\
			if([ -f SWMF.SUCCESS ]); then                              	\
				if([ ! -d RESULTS ]); then ./PostProc.pl RESULTS; fi;   \
				mkdir -p ${FULLRESDIR}/$${RunDir};                      \
				cp -r runlog* RESULTS/SC RESULTS/IH RESULTS/PARAM.in	\
					${FULLRESDIR}/$${RunDir}/;                      \
				if [[ -f SC/fdips_bxyz.out ]]; then          		\
					cp SC/fdips_bxyz.out ${FULLRESDIR}/$${RunDir}/; \
				fi;							\
				if [[ -f SC/harmonics_adapt.dat ]]; then		\
					cp SC/harmonics_adapt.dat ${FULLRESDIR}/$${RunDir}/ ; \
				fi;							\
			fi; 								\
		done;									\
	else                                                            		\
		echo "${RESDIR} already exists; skip post processing.";       		\
	fi

#########################################################################################

ResRunDirList = $(sort $(dir $(wildcard ${FULLRESDIR}/run[01][1-9]/)))

check_compare:
	@cd ${IDLDIR}; \
	for RunDir in ${ResRunDirList};  do \
		csh compare_insitu.sh ${DIR} $${RunDir}/IH $${RunDir}; \
		csh compare_remote.sh ${DIR} $${RunDir}/SC $${RunDir} ${MYDIR}/Results/obsdata; \
	done

#########################################################################################

clean_plot:
	for RunDir in ${ResRunDirList};  do 	\
		cd $${RunDir}; 			\
		rm -f *eps; 			\
		rm -f log_insitu log_remote; 	\
	done
