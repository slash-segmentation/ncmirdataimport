#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test case where there is an error checking if path is a symlink" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "1,stdout,error," > "$THE_TMP/bin/command.tasks"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -sshCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echo "Output from kepler.  Should only see this if something below fails ${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]

  # Verify we got a README.txt
  [ -s "$THE_TMP/$README_TXT" ]

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

}
 
