#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test case where local symlink dir success" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath
  mkdir -p "$THE_TMP/orig"
 
  echo "hi" >> "$THE_TMP/orig/file"
  ln -s "$THE_TMP/orig" "$THE_TMP/foo"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath "$THE_TMP/foo" -CWS_outputdir $THE_TMP -maxRetry 2 $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]
  echoArray "${lines[@]}"

  cat "$THE_TMP/$README_TXT"

  # Verify we got a workflow failed txt file
  [ ! -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]


  # Verify we got a README.txt
  [ -s "$THE_TMP/$README_TXT" ]
  
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ] 
  
  run egrep "^phase=" "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "phase=Done" ]

  [ -s "$THE_TMP/data/file" ]  
}
 
