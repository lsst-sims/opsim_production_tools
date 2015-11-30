#!/bin/bash
#################
# opsim_launch.sh - this file, the opsim production process
#
# Usage: opsim_launch.sh "my startup comment"
# opsim_launch.sh "startup comment" ./conf/LSST.conf >& ./log/myRun$nextId.log &
# Run from $RUN_DIR 
#
# test for arguments
if [ $# -ne 1 ] ; then
    printf "%s\n" "Usage:  opsim_launch.sh \"my startup comment\" \
    [--config=conf/survey/LSST.conf] [--version 3.3.3]"
    #  config path no leading chars (./) ; version only numbers and periods
    exit 192
else   
    set startup_comment = $1
fi
#     starts up an opsim simulation
#     needs the path of the LSST.conf file
#
# Calls or depends on scripts:
# opsim_monitor.py - keeps track of the progress of the simulation, 
#     and other activities sending messages as appropriate
# opsim_postprocess.py - creates the database files needed for analysis (MAF)
# maf_watcher.py - cron job to start & monitor MAF
#################
# Assumptions
# - this script will be called from machines ops1, ops2, enigma, minion,
#   ursula, etc.
# - configuration files for each machine will exist (as part of installation)
#   in /usr/local/etc/conf/opsim/launch.conf (symlink to hostname-launch.conf)
# - mysql should be running  (mysqld start in .cshrc)
# - sims_operations is installed in the standard way
# - sims_operations local directory is setup up in the standard way
# - assumes a call from the "local" directory - /lsst/opsim_3.x.y/
# - this is bash script and can be executed from a tcsh shell.
# - lines containing "NOTE" are installation notes
##########
### Setup
# MySQL:
# need to have mysql and access to the DB setup (might need to start mysqld)
# On Ursula, put this in terminal startup script or .cshrc file
# ${HOME}/opsim-db/etc/init.d/mysqld start
#
# Configs:
# Configuration parameters needed by this script are stored in
# /local/usr/bin/machine.conf
# There is a configuration file for each machine and each installation of lsst
#      ???? ask Michael about multiple versions and file location
# source /usr/local/etc/opsim/launch.conf  # NOTE: this is a symlink to
# hostname-launch.conf
source ./launch.conf  # testing

# User reviews parameters in all configuration files (/lsst/opsim_3_x_y/conf/*).
# User reviews file names specified in LSST.conf
# (or other name specified by --config).
# User needs ssh keys set up between relevant machines.
printf "\n"
printf "%s\n" "Please note that:"
printf "%s\n" "    1 - You have copied the \$SIMS_OPERATIONS_DIR/conf structure"
printf "%s\n" "        to your \$RUN_DIR".
printf "%s\n" "    2 - You have made any changes to LSST.conf and configuration"
printf "%s\n" "        files specified therein."
printf "%s\n" "    3 - You have ssh keys set up between the machine you are"
printf "%s " "        running on and the repository machine"
printf ", %s.\n" $REPO_MACHINE
printf "\n"


# Setup EUPS
printf "Sourcing %s.\n\n" ${LSST_HOME}/loadLSST.bash
source ${LSST_HOME}/loadLSST.bash
#printf "%s\n" $EUPS_DIR

# Setup sims_operations
# from $version - create OPSIM_TAG and OPSIM_DIR
# $version & $config will be read in as an argument;
# set here for testing purposes
version=3.3.3             # for testing

opsim_dir="opsim_"${version}
# create the eups tag from the directory name by substituting "." with "_"
opsim_tag=$(echo $opsim_dir | sed 's/\./_/g')

printf "OpSim will be executing with the version tagged %s.\n\n" ${opsim_tag}
setup sims_operations -t ${opsim_tag}

# Determine sessionID for this simulation
# for an empty database this returns NULL and can't do +1
session_id=`mysql -u www --password=zxcvbnm --skip-column-names -e "select max(SessionID)+1 from OpsimDB.Session"`
#echo session_id is $session_id
if [ "$session_id" = "NULL" ] ; then
   session_id="1000"
fi
printf "This session ID will be %s_%d.\n\n" ${OPSIM_HOSTNAME} ${session_id}

config=conf/survey/LSST.conf          # for testing as input in argument
# Save configuration files called by opsim.py to repository machine
# Set up distribution machine directories
repo_conf_dir=${REPO_PATH}/${OPSIM_HOSTNAME}_${session_id}/conf
ssh ${REPO_MACHINE} "mkdir -p ${repo_conf_dir}/system ${repo_conf_dir}/survey ${repo_conf_dir}/scheduler"
#
#scp -r ./conf ops2.lsst.org:$confdir &   # this runs in background; copies ALL files/directories in ./conf
#
# Read LSST.conf (or other name specified by --config) to select only the configuation files that are used.
printf "The following files will be saved to %s:%s:\n\n" ${REPO_MACHINE} ${repo_conf_dir}

survey_confs=$(sed '/^#/d' ${RUN_DIR}/${opsim_dir}/$config | sed '/survey.*conf/!d' | sed 's/^.*= //' | \
             awk -v a=${RUN_DIR} -v b=${opsim_dir} '{printf "%s/%s/%s ", a, b, $1}')
system_confs=$(sed '/^#/d' ${RUN_DIR}/${opsim_dir}/$config | sed '/system.*conf/!d' | sed 's/^.*= //' | \
             awk -v a=${RUN_DIR} -v b=${opsim_dir} '{printf "%s/%s/%s ", a, b, $1}')
scheduler_confs=$(sed '/^#/d' ${RUN_DIR}/${opsim_dir}/$config | sed '/scheduler.*conf/!d' | sed 's/^.*= //' | \
             awk -v a=${RUN_DIR} -v b=${opsim_dir} '{printf "%s/%s/%s ", a, b, $1}')
#
#printf "%s\n" $survey_confs
#printf "%s\n" $system_confs
#printf "%s\n" $scheduler_confs

printf "%s\n" ${survey_confs}
scp ${survey_confs} ${REPO_MACHINE}:${repo_conf_dir}/survey

printf "%s\n" ${system_confs}
scp ${system_confs} ${REPO_MACHINE}:${repo_conf_dir}/system

printf "%s\n" ${scheduler_confs}
scp ${scheduler_confs} ${REPO_MACHINE}:${repo_conf_dir}/scheduler

printf "\n"


##########
### Start simulation
# source loadLSST.bash and setup sims_operations already done; local $RUN_DIR defined in config file
# should already be in $RUN_DIR
# usage: opsim.py [--profile=yes] [--verbose=yes] [--track=no] [--config=conf/survey/LSST.conf] [--startup_comment="comment"]
#background? redirect stdout and stderr
# check for $# that startup comment exists
#opsim.py --config=conf/survey/LSST.conf --startup_comment="${startup_comment}" >& log/${session_id}.log &
# capture process id here  newid=$!
./sim_opsim.py &
process_id=$!
ps aux | grep sim_opsim
echo sim_opsim is $process_id
printf "as an integer %d\n\n" $process_id
which python
echo that was python


#   wait for about 10 min to make sure opsim.py has done all it's preparatory work and nRun is populated
printf "Waiting for Godot...\n\n"
sleep 3   # change to 600 for 10 minutes; 3sec is for testing

#   capture job-id and process-id from opsim.py and run opsim_monitor.py
printf "%s\n\n" "Starting Monitor"  #NOTE: install in and call from  /usr/local/bin/opsim_monitor.py
./opsim_monitor.py ${process_id} &

# Cleanup
printf "%s\n\n" "Ending opsim_launch.sh"
exit 0


