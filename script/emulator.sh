#!/usr/bin/env bash

# install and start emulator

show_help() {
  printf "usage: $0 [command]

Utility for starting emulator container in local or CI/CD environment.

Commands:
    --stop
        stops and removes container.
        (otherwise creates and starts container)
"
}

start_container(){
  # in case adb server is running
  adb kill-server
  # spin up a container
  # with SSH
  docker run -d -p 5901:5901 -p 5037:5037 -p 2222:22 -v $(pwd)/sdk:/opt/android-sdk mmcc007/hot-emulator
}

stop_container(){
  container_name="hot-emulator"
  # stop and remove container
  docker stop $(docker ps -a | grep ${container_name} | awk '{ print $1 }') &> /dev/null && docker rm $(docker ps -a | grep ${container_name} | awk '{ print $1 }') &> /dev/null
}

init_ssh(){
  container_name="mmcc007/hot-emulator"

  # Create a local `authorized_keys` file, which contains the content from your `id_rsa.pub`
  rm -f my.key
  ssh-keygen -t rsa -N "" -f my.key
  cp my.key.pub authorized_keys

  # Run a container
  #docker run -d -p 2222:22 -v $(pwd)/sdk:/opt/android-sdk:ro thyrlian/android-sdk

  # Copy the just created local authorized_keys file to the running container
  docker cp $(pwd)/authorized_keys `docker ps -aqf "ancestor=${container_name}"`:/root/.ssh/authorized_keys
  #docker cp $(pwd)/authorized_keys `docker ps -aqf "ancestor=thyrlian/android-sdk"`:/root/.ssh/authorized_keys

  # Set the proper owner and group for authorized_keys file
  docker exec -it `docker ps -aqf "ancestor=${container_name}"` bash -c 'chown root:root /root/.ssh/authorized_keys'
  #docker exec -it `docker ps -aqf "ancestor=thyrlian/android-sdk"` bash -c 'chown root:root /root/
}

start_emulator(){
  # hot start emu
  ssh -i ./my.key root@127.0.0.1 -p 2222 /root/script/start-hot-emulator.sh
}

# if no command passed
if [ -z $1 ]; then
  stop_container
  start_container
  init_ssh
  start_emulator
else
  stop_container
fi