SHELL=/bin/bash

include ../Makefile.def

MYDIR       = ${DIR}/SWMFSOLAR
QUEDIR      = $(MYDIR)
RESDIR      = Default

TIME = 2012,03,12,08,00

REALIZATIONS = 01,02,03,04,05,06,07,08,09,10,11,12

POYNTINGFLUX   = 1.0e6
POTENTIALFIELD = HARMONICS

START_TIME       = $(shell echo ${TIME} | tr , ' ')
REALIZATIONLIST  = $(shell echo ${REALIZATIONS} | tr , ' ')

help : 
	@echo ""
	@echo "Make the AWSoM or AWSoM-R runs with the ADAPT map of 12 realzations"
	@echo ""
	@echo "Examples:"
	@echo "make awsom_adapt    (run AWSoM with the 12 realzations ADAPT map with B0 from Haarmonics expansion)"
	@echo "make awsomr_adapt   (run AWSoM-R with the 12 realzations ADAPT map with B0 from Haarmonics expansion)"
	@echo ""
	@echo "Users need to install swmfpy in advance otherwise the python would not work. "
	@echo "Make sure that all the python modules are installed correctly: "
	@echo "     swmfpy needs the following packages: numpy, drms, sunpy.  "
	@echo "     remap_magnetogram needs the following packages: pyfits.  "
	@echo ""
	@echo "Options:"
	@echo " POTENTIALFIELD=HARMONICS, which could be HARMONICS or FDIPS, defualt is HARMONICS "
	@echo " TIME=YYYY,MM,DD,HH,MN, which specifies the start time of the simulation "
	@echo " POYNTINGFLUX=1.0e6, which specifies the poynting flux, defualt is 1.0e6 "
	@echo " REALIZATIONS=01,02, which species the realzations need to run, MUST BE TWO DIGITS"
	@echo " More options to be added"
	@echo ""

######################################################################################

awsom_adapt:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make awsom_compile
	make awsom_rundir
	make awsom_run
	@echo "Finished submitting AWSoM runs with a ADAPT map."

awsom_compile:
	-@(cd ${DIR}; \
	./Config.pl -v=Empty,SC/BATSRUS,IH/BATSRUS; \
	./Config.pl -o=SC:u=AwsomFluids,e=MhdWavesPeAnisoPi,nG=3; \
	./Config.pl -o=IH:u=AwsomFluids,e=MhdWavesPeAnisoPiSignB,nG=3; \
	./Config.pl -g=SC:6,8,8,IH:8,8,8; \
	make -j SWMF PIDL; \
	cd ${DIR}/util/DATAREAD/srcMagnetogram; \
	make HARMONICS FDIPS; \
	cp ${DIR}/util/DATAREAD/srcMagnetogram/remap_magnetogram.py ${MYDIR}/Scripts/;	\
	if([ ! -L ${MYDIR}/Scripts/swmfpy ]); then					\
		ln -s ${DIR}/share/Python/swmfpy/swmfpy ${MYDIR}/Scripts/swmfpy; 	\
	fi;										\
	)

awsom_rundir:
	@echo "Creating rundirs"
	rm -rf ${MYDIR}/run_backup;                     \
	mkdir -p ${MYDIR}/run_backup;                   \
	mv run[01]* ${MYDIR}/run_backup/;               \
	cp Param/PARAM.in.awsom PARAM.in
	${MYDIR}/Scripts/change_param.py -t ${START_TIME} -p ${POYNTINGFLUX} -B0 ${POTENTIALFIELD}
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

