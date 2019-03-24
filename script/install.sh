#!/usr/bin/env bash

# install flutter dependencies

# fail on any error
set -e

show_help() {
  printf "usage: $0 [command]

Utility for installing Flutter dependencies on local or CI/CD environment.

Commands:
    --local
        installs dependencies on local machine.
        (otherwise assumes running on CI/CD machine)
"
}

install_dependencies(){
  echo Installing dependencies...
#  echo android_home=$android_home
#  echo flutter_home=$flutter_home
#  echo PATH=$PATH

  install_android_tools
  install_emulator_image
  install_flutter
  install_docker_image
}

# installs the android sdk tools in specified directory
install_android_tools(){
    android_tools_id=4333796 # android-28

    # download android SDK tools
    if isMacOS ; then
        sdk_filename=https://dl.google.com/android/repository/sdk-tools-darwin-$android_tools_id.zip
    else
        sdk_filename=https://dl.google.com/android/repository/sdk-tools-linux-$android_tools_id.zip
    fi

    # install android SDK tools
    wget -q $sdk_filename -O android-sdk-tools.zip
    unzip -qo android-sdk-tools.zip -d ${android_home}
    rm android-sdk-tools.zip
    # Silence warning.
    mkdir -p ~/.android
    touch ~/.android/repositories.cfg
    # install correct version of java on osx
    if isMacOS ; then
        if [[ $(java -version 2>&1) != *"java version \"1.8."* ]]; then
            echo Install java ??
            # skip brew update
#            HOMEBREW_NO_AUTO_UPDATE=1
#            brew cask uninstall java; brew tap caskroom/versions; brew cask install java8;
        fi
    fi
    # Accept licenses before installing components, no need to echo y for each component
    yes | sdkmanager --licenses > /dev/null
    # install android tools
    sdkmanager "emulator" "tools" "platform-tools" > /dev/null
    sdkmanager --list | head -15
}

# install emulator system image
install_emulator_image(){
  sdkmanager "platform-tools" "platforms;android-$emulator_api" "emulator"
  sdkmanager "system-images;android-$emulator_api;$android_abi" > /dev/null
  sdkmanager --list | head -15
}

install_flutter(){
  # install pre-compiled flutter
  sdkmanager "platforms;android-28" "build-tools;28.0.3" > /dev/null # required by flutter
  sdkmanager --list | head -15
  FLUTTER_CHANNEL=stable
  FLUTTER_VERSION=1.2.1-${FLUTTER_CHANNEL}
  if isMacOS ; then
    wget --quiet --output-document=flutter.zip https://storage.googleapis.com/flutter_infra/releases/${FLUTTER_CHANNEL}/macos/flutter_macos_v${FLUTTER_VERSION}.zip && unzip -qq flutter.zip > /dev/null && rm flutter.zip
  else
    #sudo apt-get install -y --no-install-recommends lib32stdc++6 libstdc++6 > /dev/null
    wget --quiet --output-document=flutter.tar.xz https://storage.googleapis.com/flutter_infra/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_v${FLUTTER_VERSION}.tar.xz && tar xf flutter.tar.xz > /dev/null && rm flutter.tar.xz
  fi
  flutter doctor -v
}

install_docker_image(){
  docker pull $image_name
  docker images
}

isMacOS() {
echo OSTYPE=$OSTYPE
  #[[ $OSTYPE == "darwin"* ]]
  #[ $OSTYPE =~ "darwin" ]
  [ $OSTYPE == "darwin"* ]
  #if [ $OSTYPE =~ "darwin" ]
  #if [[ $OSTYPE =~ "darwin" ]]
}

#if isMacOS; then
  #echo is mac
#else
  #echo is not mac
#fi
#exit

. docker-vars.env
image_name="$DOCKER_USERNAME/$DOCKER_IMAGE:$DOCKER_TAG"

# if no command passed
if [ -z $1 ]; then
  #. ./build-vars-ci.env
  . ./build-vars-local.env
  install_dependencies
else
  case $1 in
    --local)
        . ./build-vars-local.env
        install_dependencies
        ;;
    *)
        echo Unknown command: $1
        show_help
        ;;
  esac
fi
