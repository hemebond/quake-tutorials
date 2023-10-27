.PHONY : clean build dist run

# directory where the qc files are compiled
DIR_BUILD=$(CURDIR)/build
# directory where release artifacts are placed
DIR_DIST=$(CURDIR)/dist
# location of quakec source code
DIR_QC=$(CURDIR)/qc
# location of compilers
DIR_COMPILERS=$(CURDIR)/compilers
# specify preferred quakec compiler
C=fteqcc64
CFLAGS=-Wall



build:
	# Compile QuakeC code
	mkdir -p ${DIR_BUILD}

	cp ${CURDIR}/src/* ${DIR_BUILD}
	cp ${CURDIR}/tutorials/${TUTORIAL}/src/* ${DIR_BUILD}

	cd ${DIR_BUILD}; ${C} ${CFLAGS}; cd -
	cd ${DIR_BUILD}; qbsp -nopercent ${CURDIR}/tutorials/${TUTORIAL}/example.map example.bsp; cd -



dist: clean build
	mkdir -p ${DIR_DIST}/maps
	cp ${DIR_BUILD}/*.dat ${DIR_DIST}
	cp ${DIR_BUILD}/*.bsp ${DIR_DIST}/maps/



archive: clean build



install: clean build
	mkdir -p ${DIR_DIST}
	cp ${DIR_BUILD}/*.dat ${DIR_DIST}/



clean:
	rm -rf ${DIR_BUILD}
	rm -rf ${DIR_DIST}



run: clean build install



ifndef TUTORIAL
	$(error TUTORIAL is undefined)
endif
