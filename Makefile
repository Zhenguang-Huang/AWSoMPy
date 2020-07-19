SHELL=/bin/bash

include ../Makefile.def

MYDIR       = ${DIR}/SWMFSOLAR/
QUEDIR      = $(MYDIR)

TIME = 2012,03,12,08,00

REALIZATIONS = 01,02,03,04,05,06,07,08,09,10,11,12

POYNTINGFLUX = 1.0e6

START_TIME       = $(shell echo ${TIME} | tr , ' ')
REALIZATIONLIST  = $(shell echo ${REALIZATIONS} | tr , ' ')


help : 
	@echo "make the AWSoM or AWSoM-R run with a ADAPT map"

awsom_adapt_harmonics:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make awsom_compile
	make awsom_rundir
	make awsom_run_harmonics
	@echo "Finished submitting AWSoM runs with a ADAPT map."

awsom_adapt_fdips:
	@echo "Submitting AWSoM runs with a ADAPT map."
	make awsom_compile
	make awsom_rundir
	make awsom_run_fdips
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
	)

awsom_rundir:
	@echo "Creating rundirs"
	if([ -d ${MYDIR}/run01 ]); then                         \
		rm -rf ${MYDIR}/run_backup;                     \
		mkdir -p ${MYDIR}/run_backup;                   \
		mv run[01]* ${MYDIR}/run_backup/;               \
	fi;							\
	cp PARAM/PARAM.in.awsom PARAM.in
	Scripts/change_param.py -t ${START_TIME} -p ${POYNTINGFLUX}
	for iRealization in ${REALIZATIONLIST}; do					\
		cd $(DIR); 								\
		make rundir RUNDIR=${MYDIR}/run$${iRealization}; 			\
		cp ${MYDIR}/PARAM.in ${MYDIR}/run$${iRealization}; 			\
		mv ${MYDIR}/map_$${iRealization}.out ${MYDIR}/run$${iRealization}/SC/;  \
	done
	rm PARAM.in

awsom_run_harmonics:
	@echo "Submitting jobs"
	for iRealization in ${REALIZATIONLIST}; do              	        	\
		cp ${MYDIR}/PARAM/HARMONICS.in ${MYDIR}/run$${iRealization}/SC/; 	\
		cd ${MYDIR}/run$${iRealization}/SC/; 					\
		sed -i '' "s/map_1/map_$${iRealization}/g" HARMONICS.in; 		\
		HARMONICS.exe; 								\
		mv harmonics_adapt.dat ${MYDIR}/run$${iRealization};			\
	done


awsom_run_fdips:
	@echo "Submitting jobs"
	for iRealization in ${REALIZATIONLIST}; do              	        	\
		cp ${MYDIR}/PARAM/FDIPS.in ${MYDIR}/run$${iRealization}/SC/; 		\
		cd ${MYDIR}/run$${iRealization}/SC/; 					\
		sed -i '' "s/map_1/map_$${iRealization}/g" HARMONICS.in; 		\
		HARMONICS.exe; 								\
		mv harmonics_adapt.dat ${MYDIR}/run$${iRealization};			\
	done