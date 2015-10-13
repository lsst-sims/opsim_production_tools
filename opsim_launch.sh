#!/bin/bash
#################
# opsim_launch.sh - this file, the opsim production process
#
# opsim_launch.sh $1 = startup comment
# usage is opsim_launch.sh "my startup comment"
# test for 
#  not $# -eq 1 then give a usage comment and exit
# else  startup_comment = $1
#     starts up an opsim simulation
#     needs the path of the LSST.conf file
#  install in /local/usr/bin 
#  or /usr/local/etc/conf/opsim/launch.conf softname create as part of installation process
#     assumes a call from the "local" directory - /lsst/opsim_3.x.y/
#     ./opsim_launch.sh ./conf/LSST.conf >& ./log/myRun$nextId.log &
# opsim_monitor.py - keeps track of the progress of the simulation, 
#     and other activities sending messages as appropriate
# opsim_postprocess.py - creates the database files needed for analysis (MAF)
# maf_watcher.py - cron job to start & monitor MAF
#################
# Assumptions
# - this script will be called from ops1, ops2, enigma, minion, ursula, etc.
#   and will be installed in /local/usr/bin 
# - configuration files for each machine will exist 
#   in /usr/local/etc/conf/opsim/launch.conf (symlink to hostname-launch.conf)
# - mysql should be running  (mysqld start in .cshrc)
# - sims_operations is installed in the standard way
# - sims_operations local directory is setup up in the standard way
##########
### Setup 
# User reviews parameters in all configuration files (/lsst/opsim_3_x_y/conf/*) print reminder?
# User reviews file names specified in LSST.conf (or other name) print reminder?
# User needs keys set up on relevant machines.
##
# need to have mysql and access to the DB setup (might need to start mysql or )
# e.g. ursula uses the stack installed mysql so setup is necessary
#      different machines have loadLSST.bash in different places (do we allow for tcsh?)
#      how do we know the current tag or just use "sims"?

# configuration file for minion lsst_home = /Users/petry/lsst
#   export LSST_HOME = /USER/cpetry/lsst
#  single config file for each machine, for each install
#export LSST_HOME=${HOME}/lsst
# also
# export OPSIM_HOST=`hostname -s`
# export OPSIM_HOST=$(hostname -s)
source config_file
source ${LSST_HOME}/loadLSST.bash
# full directory and extract version tag from pwd and replace '.' as '_'
setup sims_operations -t ${tag}

# put this in my terminal startup script
${HOME}/opsim-db/etc/init.d/mysqld start

# Determine sessionID for this simulation
# this returns NULL and can't do +1
id=`mysql -u www --password=zxcvbnm --skip-column-names -e "select max(SessionID)+1 from OpsimDB.Session"`

# Set up distribution machine directories
set confdir = /home/lsst/runs/`hostname -s`_${id}/conf
#ssh lsst@ops2.lsst.org "mkdir -p $confdir"  # don't think we need to use a username if keys are set up 
ssh ops2.lsst.org "mkdir -p $confdir"

# Save configuration files
#    assess LSST.conf (or other name) for configuation files used
#    save all relevant configuration files to distribution machine (include system & survey?)
#       use sftp?
#       make sure user has ssh-keys set up to get to dist-machine
# transferring one file for testing
scp ./conf/survey/LSST.conf ops2.lsst.org:$confdir
#scp -r ./conf ops2.lsst.org:$confdir &   # run in background

##########
### Start simulation
# source loadLSST.bash and setup sims_operations already done
# localdir="/lsst/opsim_3.3.2"
# should already be in localdir - not the same for all machines
# usage: opsim.py [--profile=yes] [--verbose=yes] [--track=no] [--config=conf/survey/LSST.conf] [--startup_comment="comment"]
#background? redirect stdout and stderr
# check for $# that startup comment exists
opsim.py --config=conf/survey/LSST.conf --startup_comment="${startup_comment}" >& log/${id}.log &

#   wait for about 10 min to make sure opsim.py has done all it's preparatory work and nRun is populated
#   capture job-id and process-id from opsim.py and run opsim_monitor.py

##########
#this is the last line0
### Monitor progress of opsim.py
# send out email message at start
opsim_monitor.py &  #needs opsim.py processID as an argument /run in background?
#   every 15min, check the progress (max(Session.night) compared to Session.nRun in nights) 
#   and send a message to opsim-prod@lists.lsst.org
#         e.g. subject could be "sessionID launched"; "sessionID finished"; "sessionID processed"
#         add in errors later
#   terminate this job when the simulation is complete ->
#   process id doesn't exist && nRun should be maxNights 
#   IF there were observations on the last night
#   maybe check TimeHistory instead
#
#   could fail if the process-id ends & the last night is not reached (nRun)

#monitor calls this one
##########
### Create database files from MySQL OpsimDB
# send out email message at start
opsim_postprocess.py &
#  this script calls $SIMS_OPERATIONS_DIR/tools/modifySchema.sh sessionID
#  and requires "source" and "setup" commands
#  Add this to opsim_launch since this is already done? 
#  progress should be tracked as well if possible and noted when done
##########
### Tidy output files
#  create zipped file
gzip -c output/`hostname -s`_$id_sqlite.db  > output/`hostname -s`_$id_sqlite.db.gz
#  make sure export files are gzipped as well.
#  move (or copy & delete) all output files (5) to distribution machine using
#  sftp .....
#  move (or copy & delete) 2 log files (?? maybe? only if space is needed)
#  send out email message when this is done
#  send email start notification (write a function with an argument/message?)
#  mail -s "Run `hostname -s`_$id has started" opsim-prod@lists.lsst.org
#

##########
### leave a bread crumb for the MAF-watcher to pickup
#  MAF-watcher is a cron job and when it finds a tag it starts a set of MAF scripts
#  MAF assembler
#     moves MAF output to repository location
#     adds run to MAF trackingDB (all runs catalog)
#     shut down and restart showMaf.py on appropriate port
#     optionally create an offline version


#Test as petry from tcsh
