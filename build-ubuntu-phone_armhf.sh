#########################################################
# libusb and libftdi builder for Ubuntu phone (armhf)
# (C) BQ. March-2016
# Written by Juan Gonzalez (Obijuan)
#########################################################

VERSION=1
UPSTREAM=upstream
PACK_DIR=packages
ARCH=armhf
BUILD_DIR=build_$ARCH
PACKNAME=tools-usb-ftdi-$ARCH-$VERSION
TARBALL=$PACKNAME.tar.bz2
BUILD=x86-unknown-linux-gnu
HOST=arm-linux-gnueabihf
TARGET=arm-linux-gnueabihf
BUILD_DATA=build-data


# -- lIBUSB
LIBUSB_GIT_REPO=https://github.com/libusb/libusb/releases/download/v1.0.20
LIBUSB_FILENAME=libusb-1.0.20
LIBUSB_FILENAME_TAR=$LIBUSB_FILENAME.tar.bz2

# -- LIBFTDI
LIBFTDI_REPO=https://www.intra2net.com/en/developer/libftdi/download
LIBFTDI_FILENAME=libftdi1-1.2
LIBFTDI_FILENAME_TAR=$LIBFTDI_FILENAME.tar.bz2

# -- DEBUG
COMPILE_LIBUSB=1
COMPILE_LISTDEVS=1
COMPILE_LIBFTDI=1
COMPILE_FIND_ALL=1

# --------------------- LIBUSB ----------------------------------------

# Store current dir
WORK=$PWD
PREFIX=$WORK/$BUILD_DIR

# -- TARGET: CLEAN. Remove the build dir and the generated packages
# --  then exit
if [ "$1" == "clean" ]; then
  echo "-----> CLEAN"

  # -- Remove the build dir
  rm -rf $WORK/$BUILD_DIR

  # -- Remove the packages dir
  rm  -rf $WORK/$PACK_DIR

  exit
fi

# Install dependencies
echo "Instalando DEPENDENCIAS:"
sudo apt-get install libtool autoconf gcc-arm-linux-gnueabihf \
                     g++-arm-linux-gnueabihf libc6-dev-armhf-cross

# Create the upstream folder
mkdir -p $UPSTREAM

# Create the packages directory
mkdir -p $PACK_DIR
mkdir -p $PACK_DIR/$BUILD_DIR
mkdir -p $PACK_DIR/$BUILD_DIR/bin

# Create the build dir
mkdir -p $BUILD_DIR

# Create a link from the user home to the build_dir
ln -s $WORK/$BUILD_DIR $HOME/.$ARCH

#-- Download the src tarball, if it has not been done yet
cd $UPSTREAM
test -e $LIBUSB_FILENAME_TAR ||
    (echo ' ' && \
    echo '--> DOWNLOADING LIBUSB source package' && \
    wget $LIBUSB_GIT_REPO/$LIBUSB_FILENAME_TAR)

#-- Extract the src files, if it has not been done yet
test -e $LIBUSB_FILENAME ||
    (echo ' ' && \
    echo '--> UNCOMPRESSING LIBUSB package' && \
    tar vjxf $LIBUSB_FILENAME_TAR)

#-- Copy the upstream libusb into the build dir
cd $WORK
test -d $BUILD_DIR/$LIBUSB_FILENAME ||
     (echo ' ' && \
     echo '--> COPYING LIBUSB upstream into build_dir' && \
     cp -r $UPSTREAM/$LIBUSB_FILENAME $BUILD_DIR)

# -- Create the lib and include files
cd $BUILD_DIR
mkdir -p lib
mkdir -p include

# ---------------------------- Building the LIBUSB library
if [ $COMPILE_LIBUSB == "1" ]; then

    cd $LIBUSB_FILENAME

    # Prepare for building
    # No udev used
    ./configure --prefix=$PREFIX USE_UDEV=0 --build=$BUILD --host=$HOST \
                --target=$TARGET

    # Compile!
    make

    # -- Copy the dev files into $BUILD_DIR/include $BUILD_DIR/lbs
    make install

    if [ $COMPILE_LISTDEVS == "1" ]; then

        #-- Compile the listdevs-example
        cd examples
        $HOST-gcc -o listdevs listdevs.c -I $WORK/$BUILD_DIR/include/libusb-1.0/  \
                  -L $WORK/$BUILD_DIR/lib  -L /usr/arm-linux-gnueabihf/lib/ \
                  -static -lusb-1.0 -lpthread

        # -- Copy the executable into the packages/bin dir
        cp listdevs $WORK/$PACK_DIR/$BUILD_DIR/bin
    fi
fi

# ------------------------ LIBFTDI --------------------------------------

#-- Download the src tarball, if it has not been done yet
cd $WORK/$UPSTREAM
test -e $LIBFTDI_FILENAME_TAR ||
    (echo ' ' && \
    echo '--> DOWNLOADING LIBFTDI source package' && \
    wget $LIBFTDI_REPO/$LIBFTDI_FILENAME_TAR)


#-- Extract the src files, if it has not been done yet
test -e $LIBFTDI_FILENAME ||
    (echo ' ' && \
     echo '--> UNCOMPRESSING LIBFTDI package' && \
     tar vjxf $LIBFTDI_FILENAME_TAR)


#-- Copy the upstream libusb into the build dir
cd $WORK
test -d $BUILD_DIR/$LIBFTDI_FILENAME ||
      (echo ' ' && \
      echo '--> COPYING LIBFTDI upstream into build_dir' && \
      cp -r $UPSTREAM/$LIBFTDI_FILENAME $BUILD_DIR)


cp $WORK/$BUILD_DATA/$ARCH/toolchain-armhf.cmake.libftdi \
   $WORK/$BUILD_DIR/$LIBFTDI_FILENAME/toolchain-armhf.cmake

# ---------------------------- Building the LIBFTDI library

if [ $COMPILE_LIBFTDI == "1" ]; then

    cd $BUILD_DIR/$LIBFTDI_FILENAME

    mkdir -p build
    cd build

    # -- Configure the compilation
    cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
          -DCMAKE_TOOLCHAIN_FILE=toolchain-armhf.cmake ..

    # -- Let's compile
    make

    # -- Installation
    make install

    if [ $COMPILE_FIND_ALL == "1" ]; then

        # -- Compile the find_all example
        cd ../examples
        $HOST-gcc -o find_all find_all.c -I $PREFIX/include/libftdi1/ \
              -L $PREFIX/lib   -L /usr/arm-linux-gnueabihf/lib/ \
              -static -lftdi1 -lusb-1.0 -lpthread

        # -- Copy the executable into the packages/bin dir
        cp find_all $WORK/$PACK_DIR/$BUILD_DIR/bin
    fi
fi

# ---------------------------------- Create the package
cd $WORK/$PACK_DIR/$BUILD_DIR
tar vjcf $TARBALL bin
mv $TARBALL ..
