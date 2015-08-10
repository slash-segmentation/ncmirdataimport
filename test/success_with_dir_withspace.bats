#!/usr/bin/env bats

load test_helper

#
# Test
#
@test "Test success case with directory with space in name" {

  # verify $KEPLER_SH is in path if not skip this test
  skipIfKeplerNotInPath

  # ssh readlink call
  echo "0,/foo hi,," > "$THE_TMP/bin/command.tasks"            
  # ssh du call
  echo "0,26794 /foo hi,error," >> "$THE_TMP/bin/command.tasks"
  # ssh directory test
  echo "0,,," >> "$THE_TMP/bin/command.tasks"
  # ssh rsync
  echo "0,,rsync error2,echo RSYNC_UNIT_TEST" >> "$THE_TMP/bin/command.tasks"
  # du of data/
  echo "0,40000 $THE_TMP/data,," >> "$THE_TMP/bin/command.tasks"

  # Run kepler.sh
  run $KEPLER_SH -runwf -redirectgui $THE_TMP -CWS_jobname jname -CWS_user joe -CWS_jobid 123 -remotePath "/foo hi" -CWS_outputdir $THE_TMP -maxRetry 2 -sleepCmd /bin/true -sshCmd "$THE_TMP/bin/command" -duCmd "$THE_TMP/bin/command" -rsyncCmd "$THE_TMP/bin/command" -remoteHost war.crbs.ucsd.edu -mkdirCmd "$THE_TMP/bin/command" $WF

  # Check exit code
  [ "$status" -eq 0 ]

  # Check output from kepler.sh
  [[ "${lines[0]}" == "The base dir is"* ]]
  echoArray "${lines[@]}"

  cat "$THE_TMP/$README_TXT"

  # Verify we didnt get a workflow failed file
  [ ! -e "$THE_TMP/$WORKFLOW_FAILED_TXT" ]


  # Verify we ran all the commands
  run wc -l "$THE_TMP/bin/command.tasks"
  [ "$status" -eq 0 ]
  echo "${lines[0]}"
  [[ "${lines[0]}" == "0 "* ]]


  # Verify we got a README.txt
  [ -s "$THE_TMP/$README_TXT" ]

  # Verify arguments are correct for rsync
  # Using a little trick with bin/command where we
  # prefix RSYNC_UNIT_TEST to echo which will be run by
  # command script and be given all the arguments passed in
  run egrep "RSYNC_UNIT_TEST" "$THE_TMP/$README_TXT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "RSYNC_UNIT_TEST war.crbs.ucsd.edu:/foo hi/ $THE_TMP/data" ]

  
  [ -s "$THE_TMP/$WORKFLOW_STATUS" ] 
 
}
 
