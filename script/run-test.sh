#!/usr/bin/env bash

# run flutter test using hot emulator in container

# fail on any error
set -e

show_help() {
  printf "usage: $0 <app-name>

Utility for running a flutter integration test in a docker container in local or CI/CD environment.
Note: must run in container because 'flutter driver' uses an arbitrary port to access observatory.

where
    <app-name>
        is the directory containing the app project
"
}

flutter_dir="flutter"
sdk_dir="sdk"
docker_sdk_dir="/opt/android-sdk"

# copy the test and flutter install to sdk volume
copy(){
  app_name=$1
  sudo rm -rf $sdk_dir/$flutter_dir $sdk_dir/$app_name
  cp -r $app_name $flutter_dir $sdk_dir
}

# wait for emulator to start (just in case)
wait_emu(){
  ssh -i ./my.key root@127.0.0.1 -p 2222 /root/script/android-wait-for-emulator.sh
}

# run the test in the container
run(){
  app_name=$1
  ssh -i ./my.key root@127.0.0.1 -p 2222 "set +e; PATH=$docker_sdk_dir/flutter/bin:$PATH; cd $docker_sdk_dir/$app_name; flutter doctor -v; flutter driver"
}

# if no command passed
if [ -z $1 ]; then
  echo Error: app name is required
  show_help
  exit 1
fi

copy $1
wait_emu
run $1
