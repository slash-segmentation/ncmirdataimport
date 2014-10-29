#!/usr/bin/env bats

setup() {
  WF="${BATS_TEST_DIRNAME}/../src/ncmirdataimport.kar"
  KEPLER_SH="kepler.sh"
  WORKFLOW_FAILED_TXT="WORKFLOW.FAILED.txt"
  README_TXT="README.txt"
  WORKFLOW_STATUS="workflow.status"
  export THE_TMP="${BATS_TMPDIR}/"`uuidgen`
  /bin/mkdir -p $THE_TMP
  /bin/cp -a "${BATS_TEST_DIRNAME}/bin" "${THE_TMP}/."
  /bin/rm -rf ~/.kepler
}

teardown() {
  #echo "Removing $THE_TMP" 1>&2
  /bin/rm -rf $THE_TMP
}

#
# Verify $KEPLER_SH is in path if not skip whatever test we are in
#
skipIfKeplerNotInPath() {

  # verify $KEPLER_SH is in path if not skip this test
  run which $KEPLER_SH

  if [ "$status" -eq 1 ] ; then
    skip "$KEPLER_SH is not in path"
  fi

}

#
# Test 
#
@test "Test error when trying to get diskspace consumed in remote path" {
  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath
  # Run kepler.sh with no other arguments
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath foo -CWS_outputdir $THE_TMP -sshCmd /bin/false $WF 

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echo "Output from kepler.  Should only see this if something below fails ${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ] 

  # Check output of workflow failed txt file
  run cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  [ "$status" -eq 0 ] 
  [ "${lines[0]}" == "simple.error.message=Unable to get disk space consumed by path" ] 
  [[ "${lines[1]}" == "detailed.error.message=Non zero exit code received from du"* ]]

  # Check output of README.txt file
  [ -s "$THE_TMP/$README_TXT" ]
  run cat "$THE_TMP/$README_TXT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "NCMIR Data Import" ]
  [ "${lines[1]}" == "Job Name: jname" ]
  [ "${lines[2]}" == "User: joe" ] 
  [ "${lines[3]}" == "Workflow Job Id: 123" ]
  [ "${lines[5]}" == "Remote Path: foo" ]
  [ "${lines[6]}" == "Remote Host: war.crbs.ucsd.edu" ]

  # Check output of workflow.status file
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ]
  run cat "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "# Seconds since"* ]]
  [[ "${lines[1]}" == "time="* ]]
  [[ "${lines[3]}" == "phase=Examining"* ]]
  [[ "${lines[4]}" == "phase.help=In this phase"* ]]
  [[ "${lines[8]}" == "phase.list=Examining"* ]]
  
}

#
# Test
#
@test "Test case where dataset size exceeds 200gb" {
  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "0,30000000000000000   /foo,blah," > "$THE_TMP/bin/command.tasks"

  # Run kepler.sh with no other arguments
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -sshCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echo "Output from kepler.  Should only see this if something below fails ${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]

  # Check output of workflow failed txt file
  run cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "simple.error.message=Dataset to large to transfer to cluster" ]
  [[ "${lines[1]}" == "detailed.error.message=Remote path contains 3.0E16 bytes which exceeds threshold"* ]]

  # Check output of README.txt file
  [ -s "$THE_TMP/$README_TXT" ]

  # Check output of workflow.status file
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ]
  run cat "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" == "phase=Examining"* ]]

}

#
# Test
#
@test "Test case where rsync succeeds" {
  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath


  echo "0,100 /foo,," > "$THE_TMP/bin/command.tasks"
  echo "0,success,," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh with no other arguments
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -sshCmd "$THE_TMP/bin/command" -rsyncCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echo "Output from kepler.  Should only see this if something below fails ${lines[@]}"

  # Verify we got a workflow failed txt file
  [ ! -e "$THE_TMP/$WORKFLOW_FAILED_TXT" ]


  # Check output of README.txt file
  [ -s "$THE_TMP/$README_TXT" ]

  # Check output of workflow.status file
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ]
  run cat "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[3]}" == "phase=Done" ]

}

#
# Test
#
@test "Test case where 2nd rsync succeeds" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "0,100 /foo,," > "$THE_TMP/bin/command.tasks"
  echo "1,,fail," >> "$THE_TMP/bin/command.tasks"
  echo "0,success,,," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh with no other arguments
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -sshCmd "$THE_TMP/bin/command" -rsyncCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echo "Output from kepler.  Should only see this if something below fails ${lines[@]}"

  # Verify we got a workflow failed txt file
  [ ! -e "$THE_TMP/$WORKFLOW_FAILED_TXT" ]


  # Check output of README.txt file
  [ -s "$THE_TMP/$README_TXT" ]

  # Check output of workflow.status file
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ]
  run cat "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[3]}" == "phase=Done" ]
  [[ "${lines[8]}" == "estimated.total.diskspace="* ]]
  [ "${lines[9]}" == "estimated.total.diskspace.help=Number of bytes that will be copied to job from remote resource" ]
  run grep "Rsync Try #2" "$THE_TMP/$README_TXT"
  [ "$status" -eq 0 ]
  

}
 
#
# Test
#
@test "Test case where 2nd rsync fails" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  echo "0,100 /foo,," > "$THE_TMP/bin/command.tasks"
  echo "1,,fail," >> "$THE_TMP/bin/command.tasks"
  echo "1,fail2,,," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh with no other arguments
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath /foo -CWS_outputdir $THE_TMP -sshCmd "$THE_TMP/bin/command" -rsyncCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]

  echo "Output from kepler.  Should only see this if something below fails ${lines[@]}"

  # Verify we got a workflow failed txt file
  [ -s "$THE_TMP/$WORKFLOW_FAILED_TXT" ]


  # Check output of README.txt file
  [ -s "$THE_TMP/$README_TXT" ]

  # Check output of workflow.status file
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ]
  run cat "$THE_TMP/$WORKFLOW_STATUS"
  [ "$status" -eq 0 ]
  [ "${lines[3]}" == "phase=Transferring data retry" ]

  run grep "Rsync Try #2" "$THE_TMP/$README_TXT"
  [ "$status" -eq 0 ]

  # Check output of workflow failed txt file
  run cat "$THE_TMP/$WORKFLOW_FAILED_TXT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "simple.error.message=Error running $THE_TMP/bin/command" ]
  [[ "${lines[1]}" == "detailed.error.message=Received non zero exit code from "* ]]


}


