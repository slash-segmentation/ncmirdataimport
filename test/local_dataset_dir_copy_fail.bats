#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test case where local dir copy fails" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath
  mkdir -p "$THE_TMP/foo"
  echo "hi" >> "$THE_TMP/foo/file"

  echo "1,,error," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath "$THE_TMP/foo" -CWS_outputdir $THE_TMP -maxRetry 2 -cpCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]
  echoArray "${lines[@]}"

  cat "$THE_TMP/$README_TXT"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]


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
  [ "${lines[1]}" == "detailed.error.message=Nonzero exit code (1) from $THE_TMP/bin/command -Lr $THE_TMP/foo $THE_TMP/data : error" ]
  
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ] 
  
  run egrep "^phase=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase=Transferring data" ]

  [ ! -d "$THE_TMP/data" ]  
}
 
