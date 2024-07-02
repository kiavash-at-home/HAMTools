#!/usr/bin/env bash
: '
Copyright 2024 by Kiavash

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'
PACKAGE_NAME=HAMTools
PACKAGE_VERSION=20240702

# Array holding list of MSDOS tools inside this package
TOOLS_INCLUDED_IN_PACKAGE=( SEDIF LINPLAN HEAD ASP PCAAD SNAPmax RASCAL YAGIMAX ANTMAKER LPCAD )

declare -A COMPRESSED_TOOLS			# need to declare this array differently to use text indexes.
COMPRESSED_TOOLS=( ['ASP']='ASP40.ZIP' ['RASCAL']='RASEXE.EXE' )

# if an argument is passed to the script and if it is "clean" command,
# then instead of building the deb package, clean the previously made files
if [ ! -z "${1}" ];
then if [ "${1}" == "clean" ];
    then
        echo "Removing built files ..."
        rm -f ./${PACKAGE_NAME}/usr/local/bin/{xseticon,vhfprop,puff,post-puff}
		rm -rf ./${PACKAGE_NAME}/usr/share/{puff,doc}
		rm -rf ./${PACKAGE_NAME}/opt/${PACKAGE_NAME}.MSDOS/Apps
        rm -rf ./${PACKAGE_NAME}*.deb
        sed -r "s/(Installed-Size:).*/\1/" -i ./${PACKAGE_NAME}/DEBIAN/control
        sed -r "s/(Version:).*/\1/" -i ./${PACKAGE_NAME}/DEBIAN/control
        sed -r "s/(Architecture:).*/\1/" -i ./${PACKAGE_NAME}/DEBIAN/control
    fi
    echo "... done!"
    exit
fi

##Check build dependencies
LIST_NEEDED_PACKGES=( build-essential fpc lcl-units libgtk2.0-dev libxmu-headers libgd-dev libxmu-dev libglib2.0-dev libncurses5-dev )
TO_INSTALL_PACKAGES=""

for NEEDED_PACKAGE in "${LIST_NEEDED_PACKGES[@]}"
do
    dpkg -s ${NEEDED_PACKAGE} &> /dev/null
    if [ $? -ne 0 ]; then
        TO_INSTALL_PACKAGES="${TO_INSTALL_PACKAGES} ${NEEDED_PACKAGE}"
    fi
done

if [ -n "${TO_INSTALL_PACKAGES}" ]; then
    echo "The packages ${TO_INSTALL_PACKAGES}, need to be installed."
    exit 1
fi

# find out linux type
# Use what is dpkg reporting
ARCH=$(dpkg --print-architecture)
echo "This build is for" ${ARCH} "arch."

# Build xseticon executable
# xseticon is needed to set the icons properly for DOSBox
echo "Building xsecticon..."
	pushd ../third_party/xseticon &> /dev/null
	make xseticon
	mkdir -p ../../src/${PACKAGE_NAME}/usr/local/bin/
	cp xseticon ../../src/${PACKAGE_NAME}/usr/local/bin/
	make clean
	popd &> /dev/null
echo "... done!"

# Build VHFProp executable
echo "Building VHFProp..."
	pushd ../third_party/VHFProp &> /dev/null
	make
	mkdir -p ../../src/${PACKAGE_NAME}/usr/local/bin/
	cp vhfprop ../../src/${PACKAGE_NAME}/usr/local/bin/
	make clean
	popd &> /dev/null
echo "... done!"

# Build PUFF executable
echo "Building PUFF..."
	pushd ../third_party/puff &> /dev/null
	make puff

	# Copy compiles executable to the package structure
	mkdir -p ../../src/${PACKAGE_NAME}/usr/local/bin/
	cp puff ../../src/${PACKAGE_NAME}/usr/local/bin/

	# Copy the documents to the package structure
	mkdir -p ../../src/${PACKAGE_NAME}/usr/share/doc/puff/
	cp {changelog.txt,Puff_Manual.pdf,README.txt,LICENSE} ../../src/${PACKAGE_NAME}/usr/share/doc/puff/

	# Copy the config files to the package structure
	mkdir -p ../../src/${PACKAGE_NAME}/usr/share/puff/config/
	cp orig_dev_and_puf_files/* ../../src/${PACKAGE_NAME}/usr/share/puff/config/
	make clean
	popd &> /dev/null
echo "... done!"

# Build PUFF executable
echo "Building Post-PUFF..."
	pushd ../third_party/post-puff &> /dev/null
	make post-puff

	# Copy compiles executable to the package structure
	mkdir -p ../../src/${PACKAGE_NAME}/usr/local/bin/
	cp post-puff ../../src/${PACKAGE_NAME}/usr/local/bin/

	# Copy the documents to the package structure
	mkdir -p ../../src/${PACKAGE_NAME}/usr/share/doc/post-puff/
	cp {bbv_test.puf,README.md,LICENSE} ../../src/${PACKAGE_NAME}/usr/share/doc/post-puff/
	make clean
	popd &> /dev/null
echo "... done!"

echo "Copying third party programs to the package structure..."
	for TOOL in "${TOOLS_INCLUDED_IN_PACKAGE[@]}"
	do
		mkdir -p ./${PACKAGE_NAME}/opt/${PACKAGE_NAME}.MSDOS/Apps/${TOOL}/

		# some 3rd party packages must be distributed in compressed format
		# Check if this TOOL is compressed format?
		if [[ " ${!COMPRESSED_TOOLS[@]} " =~ " ${TOOL} " ]]; then   # '${!array[@]}' lists indexes of an array
			echo -e '\t' $TOOL "is compressed."
			COMPRESSED_FILE=${COMPRESSED_TOOLS[${TOOL}]}	# Associated compressed file
			unzip -q -o ../third_party/${TOOL}/${COMPRESSED_FILE} \
				-d ./${PACKAGE_NAME}/opt/${PACKAGE_NAME}.MSDOS/Apps/${TOOL}/
		else
			# otherwise it is not in compress format and copy files.
			echo -e '\t' $TOOL "is not compressed."
			cp ../third_party/${TOOL}/* ./${PACKAGE_NAME}/opt/${PACKAGE_NAME}.MSDOS/Apps/${TOOL}/
		fi
	done
echo "... done!"

## post processing if needed
echo "Patching RASCAL to remove exit image..."
    patch ${PACKAGE_NAME}/opt/${PACKAGE_NAME}.MSDOS/Apps/RASCAL/RASCAL.BAT patches/RASCAL.BAT.patch
    rm ${PACKAGE_NAME}/opt/${PACKAGE_NAME}.MSDOS/Apps/RASCAL/END.EXE
echo "... done."

## Build debian package
# calculate uncompressed space of the package
PACKAGE_SIZE=$(du ${PACKAGE_NAME}/ -s | cut -f1)
# update control files accordingly
sed -r "s/(Installed-Size:).*/\1 ${PACKAGE_SIZE}/" -i ${PACKAGE_NAME}/DEBIAN/control
sed -r "s/(Version:).*/\1 ${PACKAGE_VERSION}/" -i ${PACKAGE_NAME}/DEBIAN/control
sed -r "s/(Architecture:).*/\1 ${ARCH}/" -i ${PACKAGE_NAME}/DEBIAN/control

# build the deb binary package
dpkg-deb --root-owner-group --build ${PACKAGE_NAME}/ ${PACKAGE_NAME}_${PACKAGE_VERSION}_${ARCH}.deb
ln -s ${PACKAGE_NAME}_${PACKAGE_VERSION}_${ARCH}.deb ${PACKAGE_NAME}.deb
