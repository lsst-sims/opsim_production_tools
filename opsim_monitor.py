#!/usr/bin/python
"""
 opsim_monitor.py
 Usage : opsim_monitor.py pid

 Called from opsim_launch.sh to monitor the progress of the simulation
 Calls opsim_postprocess.py
"""

import sys
import os
import time

#import opsim_postprocess
from opsim_postprocess import postprocess
  
def check_pid(pid):        
    """ Check For the existence of a unix pid. """
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True

if __name__ == '__main__':
    
    print("This is opsim_monitor.py\n")

    if len(sys.argv) != 2:
        sys.stderr.write("Usage : %s process_id" % sys.argv[0])
        raise SystemExit(1)
    process_id = sys.argv[1]
    
    while check_pid(int(process_id)):
        print("This process exists")  # email the message to opsim-prod@lists.lsst.org
        time.sleep(5)
    else:
        print("This process does not exist")
        
    # test that the number of nights achieved corresponds to nights requested.
    #set maxnights
    #set nRun_nights = nRun * 365
    if max_nights != nRun_nights:
        print("There is a problem that needs to be tracked down")
        #find the traceback error
    else:
        print("The simulation has completed successfully")
        opsim_postprocess()


#  After the simulation ends then
#  opsim_postprocess()
#  os.system('python opsim_postprocess.py')
#  postprocess()

sys.exit(0)


"""
   
send out email message at start
   every 15min, check the progress (max(Session.night) compared to Session.nRun in nights) 
   and send a message to opsim-prod@lists.lsst.org
         e.g. subject could be "sessionID launched"; "sessionID finished"; "sessionID processed"
         add in errors later
   terminate this job when the simulation is complete ->
   process id doesn't exist && nRun should be maxNights   Error if pid is not there and maxNights
while pid.exists()
keep checking
  
  check maxnights != runN
   send out an error message (exerpt log file error - grep for Traceback, return line number, open file (not read it) and read from that line to the end and print - and print out)  and exit
   or run postprocessing as a callable
  # print section of file from regular expression to end of file
 sed -n '/regexp/,$p'
   
   IF there were observations on the last night
   maybe check TimeHistory instead

   could fail if the process-id ends & the last night is not reached (nRun)
"""
