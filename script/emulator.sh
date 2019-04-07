#!/usr/bin/env bash
set -x

# install and start emulator

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
#IFS=$'\n\t'

show_usage() {
  printf "usage: $0 [command]

Utility for managing emulator

Commands:
    --install-emulator-image
        installs emulator image
    --start-hot-emulator
        starts emulator with quickstart snapshot
    --stop-emulator
        stops emulator
    --avd
        creates avd 
    --snapshot
	creates quickstart snapshot 
    --archive
	archives avd with quickstart snapshot 
"
}

usage_fail() { echo "$@";  show_usage; exit 111; }

# check for required pre-defined vars
#check_predefined_vars(){
#  #required_vars=(android_home emu_name android_abi emulator_api emu_options)
#  required_vars=( hot_emulator_home_host hot_emulator_home_container docker_image android_tools_id flutter_home emulator_api android_abi emu_name emu_options )
#  for name in "${required_vars[@]}"; do 
#    eval var='$'$name
#    [ -z "${var}" ] && { echo "$name not defined"; exit 1; }
#  done
#  return 0
#}

# stop adb (if running)
stop_adb(){
  SERVICE="adb"
  if pgrep "$SERVICE" >/dev/null; then
    adb kill-server
  fi
}

# install emulator system image
install_emulator_image(){
  sdkmanager "system-images;android-$emulator_api;$android_abi" > /dev/null
  sdkmanager --list | head -15
}

# Starts hot emu
#start_emulator(){
#
#  #sudo su -c 'source ./build-vars-local.env && adb kill-server'
#  #adb devices
#
## start emulator from an existing avd with a default snapshot
##set -x
##set -e
#
## fix install of emulator (which was installed from host)
#sdkmanager --update
#
## redirect stdin, stdout and stderr to avoid hanging on exit of ssh
##rm -f foo.out foo.err
#$android_home/emulator/emulator -avd $emu_name $emu_options -no-snapshot-save > foo.out 2> foo.err < /dev/null &
#sleep 1
#ps ax | grep emu
#
#cat foo.out
#cat foo.err
#
#ls -la ~/.android/avd/test.avd/
#ls -la $android_home/system-images/android-22/default/armeabi-v7a/
#
#ANDROID_SDK_ROOT=$android_home
#$android_home/emulator/emulator -avd $emu_name $emu_options -no-snapshot-save > foo.out 2> foo.err < /dev/null &
#sleep 1
#ps ax | grep emu
#
#cat foo.out
#cat foo.err
#
#./script/android-wait-for-emulator.sh
##./script/wait-for-boot-completed.sh
#
#
#  #./script/android-wait-for-emulator.sh
#}

stop_emulator(){
  adb emu kill
}






# creates a new avd
create_avd(){
  echo creating avd...

  # stop emulator (if running)
  SERVICE="emulator"
  if pgrep "$SERVICE" >/dev/null; then
    adb emu kill
  fi

  # clear old avd directory
  rm -rf ~/.android/avd

  # Install system image and create avd
  sdkmanager "system-images;android-$emulator_api;$android_abi"
  sdkmanager --list | head -15
  echo no | avdmanager create avd --force -n $emu_name -k "system-images;android-$emulator_api;$android_abi"
  # increase avd ram (from 96 MB)
  echo "hw.ramSize=1024" >> $HOME/.android/avd/$emu_name.avd/config.ini
}

create_snapshot(){
  #create_avd
  echo creating quickstart snapshot...

  # start emu 
  # (note: redirects stdin, stdout and stderr to detach completely from current process -- otherwise will hang)
  #$android_home/emulator/emulator -avd $emu_name $emu_options -quit-after-boot 180 > emulator.out 2> emulator.err < /dev/null &
  $android_home/emulator/emulator -avd $emu_name $emu_options > emulator.out 2> emulator.err < /dev/null &
  sleep 1
  ps ax | grep emu

  cat emulator.out
  cat emulator.err
  
  # wait for emulator to start
  #./script/android-wait-for-emulator.sh
  ./script/wait-for-boot-completed.sh

  # stop emulator to create quickstart snapshot
  # todo: find better way to stop emu
  #adb emu kill

  #archive_avd
}

create_archive(){
  echo archiving avd with quickstart snapshot...
  (cd ~/.android; tar czvf avd.tar.gz avd)
  mv ~/.android/avd.tar.gz $hot_emulator_home_host

  # copy archive to web server
  #sudo cp avd.tar.gz /var/www/html
}

# start the hot emulator to confirm it is working
start_hot_emulator(){
  # redirect stdin, stdout and stderr to avoid hanging if called from ssh
  #emulator -avd $emu_name $emu_options -no-snapshot-save > emulator.out 2> emulator.err < /dev/null &
  #cat emulator.out
  #cat emulator.err
  $ANDROID_HOME/emulator/emulator -avd $emu_name $emu_options -no-snapshot-save &

  # wait for emulator to start
  #./script/android-wait-for-emulator.sh
  ./script/wait-for-boot-completed.sh

  # stop emulator 
  #adb emu kill

}

#source create-hot-emulator.env
#check_predefined_vars









# if no command passed
if [ -z $1 ]; then
  usage_fail Error: no command specified
fi

# set build env vars
source ./build-vars-local.env
check_predefined_vars

case $1 in
    --install-emulator-image)
  	install_emulator_image
        ;;
    --start-hot-emulator)
  	start_hot_emulator
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
    *)
        usage_fail Unknown command: $1
        ;;
esac
