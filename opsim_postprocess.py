#!/usr/bin/python
#################
# opsim_postprocess.py
#
# Called from opsim_monitor.py  after the end of the simulation has been
# detected
# Usage: opsim_postprocess.py
#
import sys 

def postprocess():
   print("Hello World\n")
   print("This is where the post-processing happens.\n")
   print("\n")

##########
### Create database files from MySQL OpsimDB
#  send out email message at start
#  this script calls $SIMS_OPERATIONS_DIR/tools/modifySchema.sh sessionID
#  and requires "source" and "setup" commands
#  progress should be tracked as well if possible and noted when done
##########
### Tidy output files
#  create zipped file
#!# gzip -c output/`hostname -s`_$id_sqlite.db  > output/`hostname -s`_$id_sqlite.db.gz
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
