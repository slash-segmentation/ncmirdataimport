#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test case where there is an error running du on path" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "0,/foo,," > "$THE_TMP/bin/command.tasks"
  echo "2,,error," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -maxRetry 1 -sleepCmd /bin/true -sshCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echoArray "${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]

  # Verify we ran all the commands
  run wc -l "$THE_TMP/bin/command.tasks"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "0 "* ]]


  # Verify we got a README.txt
  [ -s "$THE_TMP/$README_TXT" ]

  run cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  [ "$status" -eq 0 ]
  echo "WORKFLOW FAILED"
  cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  echo ""
  cat "$THE_TMP/$README_TXT"
  [ "${lines[0]}" == "simple.error.message=Unable to get size of dataset" ]
  [ "${lines[1]}" == "detailed.error.message=Non zero exit code (2) while trying to obtain size of data" ]
  
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ] 
  
  run egrep "^phase=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase=Examining data to transfer" ]
   
}
 
