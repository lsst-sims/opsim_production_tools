#!/usr/bin/python
#################
# opsim_monitor.py
#
# Called from opsim_launch.sh to monitor the progress of the simulation
# Calls opsim_postprocess.py
# Usage: opsim_launch.sh "my startup comment"
#
import sys
import os
#import opsim_postprocess
from opsim_postprocess import postprocess

if __name__ == '__main__':
   print("\n")
   print("Hello World\n")
   print("This is where the simulation is monitored.\n")
   print("\n")
#  After the simulation ends then
#  opsim_postprocess()
#   os.system('python opsim_postprocess.py')


   postprocess()
   
   sys.exit(0)
   
# send out email message at start
#   every 15min, check the progress (max(Session.night) compared to Session.nRun in nights) 
#   and send a message to opsim-prod@lists.lsst.org
#         e.g. subject could be "sessionID launched"; "sessionID finished"; "sessionID processed"
#         add in errors later
#   terminate this job when the simulation is complete ->
#   process id doesn't exist && nRun should be maxNights   Error if pid is not there and maxNights
while pid.exists()
keep checking
  
  check maxnights != runN
   send out an error message (exerpt log file error - grep for Traceback, return line number, open file (not read it) and read from that line to the end and print - and print out)  and exit
   or run postprocessing as a callable
   # print section of file from regular expression to end of file
 sed -n '/regexp/,$p'
   
#   IF there were observations on the last night
#   maybe check TimeHistory instead
#
#   could fail if the process-id ends & the last night is not reached (nRun)
    
