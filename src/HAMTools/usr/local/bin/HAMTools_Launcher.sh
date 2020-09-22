#!/bin/bash
: '
Copyright 2020 by Kiavash

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
# check to make sure an argument is passed
if [ -z "${4}" ];
    then
    echo "Missed correct inputs!"
    echo "Exiting!"
    exit 1
fi

RFTOOLS_BASE_LOCATION=/opt/HAMTools.MSDOS
RFTOOLS_CONFIG_LOCATON=${RFTOOLS_BASE_LOCATION}/dosbox.conf.d
RFTOOLS_LOCATION=${RFTOOLS_BASE_LOCATION}/Apps
MAIN_CONFIG=HAMTools.conf
TOOL=${1}
TOOL_CONFIG=${TOOL}.conf
TOOL_ICON=${2}
DELAY=${3}
SEARCH_TITLE=${4}
USER_FOLDER=.HAMTools

# Does User have the local RF Tools folder?
if [ ! -d "$HOME/${USER_FOLDER}/${TOOL}" ]; then
    # no we don't have the folder
    # I guess it is the 1st time that we are running an RF Tools (or maybe user deleted that folder)
    # let's make it
    mkdir -p $HOME/${USER_FOLDER}/${TOOL}

    # Some files needs to be copied to local user folder with edit access
    cp ${RFTOOLS_LOCATION}/${TOOL}/*.FON  $HOME/${USER_FOLDER}/${TOOL} 2>/dev/null

    # SNAPmax setting is needs to be copied locally
    cp ${RFTOOLS_LOCATION}/${TOOL}/*.QTH  $HOME/${USER_FOLDER}/${TOOL} 2>/dev/null
    cp ${RFTOOLS_LOCATION}/${TOOL}/*.INI  $HOME/${USER_FOLDER}/${TOOL} 2>/dev/null

    # YAGIMAX Design files copied to local folder
    cp ${RFTOOLS_LOCATION}/${TOOL}/*.INP  $HOME/${USER_FOLDER}/${TOOL} 2>/dev/null

    # LPCAD Design files copied to local folder
    cp ${RFTOOLS_LOCATION}/${TOOL}/*.LPA  $HOME/${USER_FOLDER}/${TOOL} 2>/dev/null


    # and link the default files there (no overwrite)
    ln -s ${RFTOOLS_LOCATION}/${TOOL}/* $HOME/${USER_FOLDER}/${TOOL}
fi
# now we have the default folder for sure.

# Check if configs exit
if [ -f ${RFTOOLS_CONFIG_LOCATON}/${MAIN_CONFIG} -a -f ${RFTOOLS_CONFIG_LOCATON}/${TOOL_CONFIG} ]; then
    dosbox -conf ${RFTOOLS_CONFIG_LOCATON}/${MAIN_CONFIG} -conf ${RFTOOLS_CONFIG_LOCATON}/${TOOL_CONFIG} &
    sleep ${DELAY}
    # find the tid for the dosbox with the tool running
    tid="$( xwininfo -root -children -all | grep -iE "dosbox.*${SEARCH_TITLE}.*" | awk '{print $1}' )"
    echo "modifying id ${tid}"
    # change the icon to the tool's
    xseticon -id "${tid}" "${TOOL_ICON}"
    # change the window name to tool's
    xdotool set_window --name "${TOOL}" "${tid}"
    # it is important to 'windowunmap windowmap' otherwise the new name won't take effect.
    xdotool search --name "${TOOL}" set_window --classname "${TOOL}" --class "${TOOL}" windowunmap windowmap
    exit 0
else
    echo "Re-installe the package!"
    exit 1
fi