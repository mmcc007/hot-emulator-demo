#!/usr/bin/env bash

# install and start emulator

show_help() {
  printf "usage: $0 [command]

Utility for starting emulator container in local or CI/CD environment.

Commands:
    --start-container
        creates and starts container
    --stop-container
        stops and removes container.
    --stop-all-containers
        stops and removes all containers.
    --start-emulator
        starts emulator
    --stop-emulator
        stops emulator
    --avd
        creates avd in container
    --snapshot
	creates quickstart snapshot in container
    --archive
	archives and downloads avd with quickstart snapshot from container
"
}

start_container(){
  # in case adb server is running
  #adb kill-server
  # spin up a container
  # with SSH
  #docker run -d -p 5901:5901 -p 5037:5037 -p 2222:22 -v $(pwd)/sdk:/opt/android-sdk mmcc007/hot-emulator
  docker run -d -p 5901:5901 -p 5037:5037 -p 2222:22 -v $(pwd)/sdk:/opt/android-sdk ${container_name}
  docker ps -a
}

stop_container(){
  #container_name="hot-emulator"
  # stop and remove container
  docker stop $(docker ps -a | grep ${container_name} | awk '{ print $1 }') &> /dev/null && docker rm $(docker ps -a | grep ${container_name} | awk '{ print $1 }') &> /dev/null
}

# stops and removes all containers
stop_all_containers(){
  container_ids=$(docker ps -a | grep --invert-match CONTAINER | awk '{ print $1 }')
  if [ ! -z "$container_ids" ]; then
    docker stop $container_ids
    docker rm $container_ids
  fi
}

init_ssh(){
  #container_name="mmcc007/hot-emulator:0.0.1"

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
  ssh -i ./my.key root@127.0.0.1 -p 2222 /root/script/start-hot-emulator.sh &
  # check emulator is found and ready
  #ssh -i ./my.key root@127.0.0.1 -p 2222 flutter devices
  flutter devices
}

stop_emulator(){
  ssh -i ./my.key root@127.0.0.1 -p 2222 adb emu kill
}

create_avd(){
  echo creating avd...
  ssh -i ./my.key root@127.0.0.1 -p 2222 /root/script/create-hot-emulator.sh --avd
}

create_snapshot(){
  echo creating snapshot...
  ssh -i ./my.key root@127.0.0.1 -p 2222 /root/script/create-hot-emulator.sh --snapshot
}

create_archive(){
  echo creating archive...
  ssh -i ./my.key root@127.0.0.1 -p 2222 /root/script/create-hot-emulator.sh --archive
  scp -i my.key -P 2222 root@127.0.0.1:~/.android/avd.tar.gz .
  # for local docker image builds
  cp avd.tar.gz ~/dev/github.com/mmcc007/hot-emulator
  # for travis docker image builds
  sudo cp avd.tar.gz /var/www/html
  rm avd.tar.gz
}

# if no command passed
if [ -z $1 ]; then
  echo Error: no command specified
  show_help
  exit 1
fi

. ./docker-vars.env
container_name="$DOCKER_USERNAME/$DOCKER_IMAGE:$DOCKER_TAG"

case $1 in
    --start-container)
  	stop_container
        start_container
        init_ssh
        ;;
    --stop-container)
  	stop_container
        ;;
    --stop-all-containers)
  	stop_all_containers
        ;;
    --start-emulator)
  	start_emulator
        ;;
    --stop-emulator)
  	stop_emulator
        ;;
    --avd)
  	create_avd
        ;;
    --snapshot)
  	create_snapshot
        ;;
    --archive)
  	create_archive
        ;;
    --dev)
        ssh -i ./my.key root@127.0.0.1 -p 2222 apt-get install -y vim
        ;;
    *)
        echo Unknown command: $1
        show_help
        ;;
esac
