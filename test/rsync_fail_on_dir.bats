#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test case rsync fails on dir copy" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "0,/foo,," > "$THE_TMP/bin/command.tasks"
  echo "0,26794 /foo,error," >> "$THE_TMP/bin/command.tasks"
  echo "0,,," >> "$THE_TMP/bin/command.tasks"
  echo "1,,rsync error," >> "$THE_TMP/bin/command.tasks"
  echo "1,,rsync error2," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -maxRetry 2 -sleepCmd /bin/true -sshCmd "$THE_TMP/bin/command" -duCmd "$THE_TMP/bin/command" -remoteHost war.crbs.ucsd.edu -rsyncCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]
  echoArray "${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]

  cat "$THE_TMP/$README_TXT"

  cat "$THE_TMP/$WORKFLOW_FAILED_TXT"

  # Verify we ran all the commands
  run wc -l "$THE_TMP/bin/command.tasks"
  [ "$status" -eq 0 ]
  echo "${lines[0]}"
  [[ "${lines[0]}" == "0 "* ]]


  # Verify we got a README.txt
  [ -s "$THE_TMP/$README_TXT" ]

  run cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "simple.error.message=Unable to copy data" ]
  [ "${lines[1]}" == "detailed.error.message=Non zero exit code from $THE_TMP/bin/command" ]
  
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ] 
 
  run egrep "^phase=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase=Transferring data retry" ]
  
  run egrep "^phase.help=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  echo "${lines[0]}"
  [ "${lines[0]}" == "phase.help=In this phase the workflow copies the data (26794 bytes) from (war.crbs.ucsd.edu:/foo/) to the output of this job" ]


  run egrep "^phase.list=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase.list=Examining data to transfer,Transferring data,Transferring data retry,Done" ]

  run egrep "^estimated.total.diskspace=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "estimated.total.diskspace=26794" ]

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
 
