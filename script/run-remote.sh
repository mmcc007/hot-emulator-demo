#!/usr/bin/env bash

# runs a local script in container via ssh
runRemote() {
  local script=$1; shift
  local args
  local scriptStr
  local remoteMsg='running local script in container...'
  # escape args from shell by quoting if necessary
  printf -v args '%q ' "$@"

  # handle script passed as file or string
  if [ -f "$script" ]; then
    scriptStr=$(< "$script")
  else
    scriptStr="$script $args"
    remoteMsg='running command in container...'
  fi
  ssh -i ./my.key -T root@127.0.0.1 -p 2222 "bash -s" <<EOF

  # pass quoted arguments through for parsing by remote bash
  set -- $args

  # set environment
  source build-vars-local.env

  # print message
  echo $remoteMsg

  # substitute literal script text into heredoc
  $scriptStr

EOF
}

# copy local files to remote dir in container via scp
scpFiles(){
 local -n filesToScp=$1
 for localFile in "${!filesToScp[@]}"; do 
   remoteDir=${filesToScp[$localFile]}
   scp -i my.key -P 2222 $localFile root@127.0.0.1:$remoteDir > /dev/null 2>&1
 done
}

# create associative array (map) of local dependency files
declare -A dependencies
dependencies[build-vars-local.env]=/root
dependencies[docker-vars.env]=/root
dependencies[script/wait-for-boot-completed.sh]=/root/script

# copy dependencies to remote before running script
scpFiles dependencies

runRemote $@
