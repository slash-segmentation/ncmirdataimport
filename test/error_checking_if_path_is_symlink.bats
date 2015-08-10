#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test case where there is an error checking if path is a symlink" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "1,stdout,error," > "$THE_TMP/bin/command.tasks"
  echo "1,stdout,error," > "$THE_TMP/bin/command.tasks"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -maxRetry 2 -sleepCmd /bin/true -remoteHost war.crbs.ucsd.edu -sshCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echoArray "${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]

  # Verify we got a README.txt
  [ -s "$THE_TMP/$README_TXT" ]

  # Verify we ran all the commands
  run wc -l "$THE_TMP/bin/command.tasks"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "0 "* ]]

  # Check read me header
  run cat "$THE_TMP/$README_TXT"
  [ "$status" -eq 0 ] 
  [ "${lines[0]}" == "NCMIR Data Import" ]
  [ "${lines[1]}" == "Job Name: jname" ] 
  [ "${lines[2]}" == "User: joe" ]
  [ "${lines[3]}" == "Workflow Job Id: 123" ] 
  [ "${lines[5]}" == "Remote Path: /foo" ] 
  [ "${lines[6]}" == "Remote Host: war.crbs.ucsd.edu" ] 

  run cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  [ "$status" -eq 0 ]
  echo "WORKFLOW FAILED"
  cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  echo ""
  cat "$THE_TMP/$README_TXT"
  [ "${lines[0]}" == "simple.error.message=Unable to determine if remote path is a symlink" ]
  [ "${lines[1]}" == "detailed.error.message=Non zero exit code (1) while trying to see if /foo is a symlink" ]
  
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ] 
  
  run egrep "^phase=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase=Examining data to transfer" ]

  run egrep "^phase.help=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  echo "${lines[0]}"
  [ "${lines[0]}" == "phase.help=In this phase the workflow connects to war.crbs.ucsd.edu and examines how much diskspace the path /foo consumes" ]

 
  run egrep "^phase.list=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase.list=Examining data to transfer,Transferring data,Transferring data retry,Done" ]
     
  run egrep "^estimated.total.diskspace=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "estimated.total.diskspace=unknown" ]

  run egrep "^estimated.total.diskspace.help=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "estimated.total.diskspace.help=Number of bytes that will be copied to job from war.crbs.ucsd.edu" ]

  run egrep "^disk.space.consumed=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "disk.space.consumed=unknown" ]

  run egrep "^disk.space.consumed.help=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "disk.space.consumed.help=Disk space in bytes" ]

   
}
 
