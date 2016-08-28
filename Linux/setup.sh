#!/bin/bash

setup_full=false
setup_type="partial"
if [ "${1,,}" == "complete" ]
then
  setup_full=true
  setup_type="complete"
fi

sigserver_install_path=~/sigverse-2.3.5

OK_COLOR='\033[0;32m'
ERROR_COLOR='\033[0;31m'
NO_COLOR='\033[0m'
function log_ok {
    echo -e "${OK_COLOR}$1${NO_COLOR}"
}

function log_err {
    echo -e "${ERROR_COLOR}$1${NO_COLOR}"
}

function chkErr {
  if [ "$1" == 0 ]
  then
    log_ok "Success"
  else
    log_err $2
    exit $1
  fi
}

log_ok "\t+-------------------------------------------------+"
log_ok "\t  SIGVerse Setup             "
log_ok "\t   -Setup Type: $setup_type  "
log_ok "\t   - Setup Dir: $PWD         "
log_ok "\t                             "
log_ok "\t            Continue? (y/n)  "
log_ok "\t+-------------------------------------------------+"

read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo
  log_ok "Quitting..."
  echo
  exit
fi

# Install easy deps
log_ok "Installing packaged libs..."
sudo apt-get update
sudo apt-get install g++ git cmake default-jdk freeglut3 freeglut3-dbg freeglut3-dev libxerces-c3.1 libxerces-c-dev openssh-server wget

chkErr $? "ERROR Installing packaged deps!"

# Rearrange JDK headers
log_ok "Copy JDK headers to /usr/local/include/ ..."
sudo cp /usr/lib/jvm/default-java/include/* /usr/local/include/
sudo cp /usr/lib/jvm/default-java/include/linux/* /usr/local/include/

chkErr $? "Error copying files!"

# Move to temp directory to set up downloaded deps
tmp_dir=`mktemp -d`
log_ok "Switching to temp directory: $tmp_dir"
pushd $tmp_dir

# Install ODE
log_ok "Downloading ODE..."
wget http://downloads.sourceforge.net/project/opende/ODE/0.13/ode-0.13.tar.bz2
chkErr $? "Error downloading ODE!"

log_ok "Compiling ODE..."
tar -xvf ./ode-0.13.tar.bz2
cd ./ode-0.13
./configure --disable-tests --without-x --enable-double-precision --with-trimesh=opcode --enable-release --enable-shared
make
chkErr $? "Error building ODE!"

log_ok "Installing ODE..."
sudo make install
chkErr $? "Error installing ODE!"

# Install Xj3D
log_ok "Downloading Xj3D..."
wget http://www.vrspace.org/sdk/vrml/browsers/Xj3D/Xj3D-1-0-linuxx86.jar
chkErr $? "Error downloading Xj3D!"

sudo java -jar ./Xj3D-1-0-linuxx86.jar

# Get back to where we were
popd

# Get SIGServer
if [ -d "SIGServer" ]
then
  log_ok "SIGServer directory already exists..."
  log_ok "Leaving it as-is. Please use git pull to update."
else
  log_ok "Cloning SIGServer..."
  git clone --recursive https://github.com/noirb/sigverse-SIGServer.git SIGServer
fi

chkErr $? "Error cloning SIGServer!"

pushd SIGServer

log_ok "Configuring SIGServer..."
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

if [ -d "build" ]
then
  log_ok "Trashing existing build directory..."
  rm -rf ./build
fi

mkdir build && cd build
cmake ..

chkErr $? "Failed to configure SIGServer!"

log_ok "Building SIGServer"
make

chkErr $? "Failed to build SIGServer!"

log_ok "Installing SIGServer"
make install

chkErr $? "Failed to install SIGServer!"

popd

# Check for previous configuration in .bashrc
log_ok "Checking for existing SIGServer config in .bashrc..."
grep -rin "SIGVERSE_PATH=" ~/.bashrc

if [ $? -eq 0 ]
then
  log_ok "Updating..."
  sed -Ei "s/(SIGVERSE_PATH=)(.*)/\1$sigserver_install_path/g" ~/.bashrc
else
  log_ok "Adding SIGVerse Path to .bashrc"
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc
  echo "export SIGVERSE_PATH=\$sigserver_install_path" >> ~/.bashrc
  echo "export PATH=\$PATH:\$SIGVERSE_PATH/bin" >> ~/.bashrc
fi

source ~/.bashrc

# Additional projects/deps beyond the server
if [ $setup_full ]
then
  # Plugins
  if [ -d "Plugins" ]
  then
    log_ok "SIGVerse Plugins directory already exists"
    log_ok "Leaving it as-is. Please use git pull to update."
  else
    log_ok "Cloning SIGVerse Plugins"
    git clone --recursive https://github.com/noirb/sigverse-plugin.git Plugins
    chkErr $? "ERROR Cloning SIGVerse Plugins!"
  fi

  log_ok "Configuring Plugins..."
  pushd Plugins

  if [ -d "build" ]
  then
    log_ok "Trashing existing build directory..."
    rm -rf ./build
  fi

  mkdir build && cd build
  cmake ..
  chkErr $? "ERROR Configuring SIGVerse Plugins!"

  log_ok "Building sigplugin.so..."
  make
  chkErr $? "ERROR building sigplugin.so!"

  log_ok "Installing sigplugin.so..."
  make install
  chkErr $? "ERROR Installing sigplugin.so!"

  popd


  # Extra shape files
  log_ok "Getting additional model and shape files..."
  if [ -d "model" ]
  then
    log_ok "Model repository already exists."
    log_ok "Leaving it as-is. Please use git pull to update"
  else
    git clone --recursive https://github.com/SIGVerse/model.git model
  fi

  cp ./model/shapes/* $SIGVERSE_PATH/share/data/xml/
  chkErr $? "ERROR Copying extra shape files to $SIGVERSE_PATH"

fi

log_ok "\t================="
log_ok "\t Setup Complete!"
log_ok "\t================="
