FROM debian:latest

RUN apt-get update -y && \
  apt-get install -y \
    build-essential wget python git \
    libglfw3-dev libglew-dev libfreetype6-dev libfontconfig1-dev uuid-dev libxcursor-dev libxinerama-dev libxi-dev libasound2-dev libexpat1-dev \
    libnss3-dev libxcomposite-dev libxtst-dev libxss-dev libdbus-1-dev libpango-1.0-0 libpangocairo-1.0-0 libatk1.0-0 libatk-bridge2.0-0 default-jdk \
    unzip

ADD . /app
WORKDIR /app

RUN \
  set -x && \
  wget "https://nodejs.org/dist/v11.6.0/node-v11.6.0-linux-x64.tar.gz" -O node.tar.gz && \
  tar -zxf node.tar.gz && \
  rm node.tar.gz && \
  mv node-v11.6.0-linux-x64 node
RUN \
  wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
  unzip sdk-tools-linux-4333796.zip && \
  rm sdk-tools-linux-4333796.zip && \
  mkdir android-sdk && \
  export ANDROID_HOME=$(pwd)/android-sdk && \
  mv tools android-sdk/tools && \
  yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses && \
  sync

RUN \
  set -x && \
  export ANDROID_HOME=$(pwd)/android-sdk && \
  $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "platforms;android-28" && \
  $ANDROID_HOME/tools/bin/sdkmanager "ndk-bundle" && \
  export PATH="$PATH:$(pwd)/node/bin" && \
  sync

RUN \
  set -x && \
  ls scripts && \
  export PATH="$PATH:$(pwd)/node/bin" && \
  export ANDROID_HOME=$(pwd)/android-sdk && \
  bash -x scripts/make-toolchain-android.sh && \
  bash -x scripts/build-android.sh && \
  export TEST_ENV=ci && \
  npm run test
RUN \
  set -x && \
  mv android/app/build/outputs/apk/debug/app-debug.apk ./app.apk
