#!/usr/bin/env bash 

# conda 
# conda create -n caffe_python2 -c intel hdf5 git cmake lmdb snappy boost numpy python=2.7
# source activate caffe_python2 

# module 
# module load intel/18.0.3 impi/18.0.3

ROOT=$(dirname $(readlink -f $0))
CONDA_ENV=/scratch/pop19/.pyenv/caffe_python2

function build_opencv 
{ 
    name="opencv"
    version="3.4.8"

    if [ ! -d ${name}-${version} ]
    then
        wget -O ${name}-${version}.tar.gz https://github.com/opencv/opencv/archive/$version.tar.gz
        tar xf ${name}-${version}.tar.gz 
    fi
        
    mkdir -p ${name}-${version}/build 
    cd ${name}-${version}/build 
    cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_ENV 
   
    make -j 
    make install 

    cd $ROOT
}

function build_glog 
{ 
    name="glog"
    version="0.4.0"

    if [ ! -d ${name}-${version} ]
    then
        wget -O ${name}-${version}.tar.gz https://github.com/google/glog/archive/v$version.tar.gz
        tar xf ${name}-${version}.tar.gz 
    fi
        
    mkdir -p ${name}-${version}/build 
    cd ${name}-${version}/build 
    cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_ENV

    make -j 
    make install 

    cd $ROOT
} 

function build_gflags 
{ 
    name="gflags"
    version="2.2.2"

    if [ ! -d ${name}-${version} ]
    then
        wget -O ${name}-${version}.tar.gz https://github.com/gflags/gflags/archive/v$version.tar.gz
        tar xf ${name}-${version}.tar.gz 
    fi

    mkdir -p ${name}-${version}/build 
    cd ${name}-${version}/build 

    cmake .. -DCMAKE_BUILD_TYPE=Release        \
             -DCMAKE_INSTALL_PREFIX=$CONDA_ENV \
             -DCMAKE_CXX_FLAGS="-fPIC"         \
             -DBUILD_SHARED_LIBS=ON            \
             -DBUILD_STATIC_LIBS=ON            \
             -DBUILD_GFLAGS_LIB=ON

    make -j 
    make install
    
    cd $ROOT
} 

function build_leveldb
{ 
    name="leveldb"
    version="1.22"

    if [ ! -d ${name}-${version} ]
    then
        wget -O ${name}-${version}.tar.gz https://github.com/google/leveldb/archive/$version.tar.gz
        tar xf ${name}-${version}.tar.gz 
    fi
        
    mkdir -p ${name}-${version}/build 
    cd ${name}-${version}/build 

    cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_ENV \
             -DCMAKE_CXX_FLAGS=-fPIC

    make -j 
    make install
    
    cd $ROOT
} 

function build_protobuf
{ 
    name="protobuf"
    version="3.5.1"

    if [ ! -d ${name}-${version} ]
    then
        wget -O ${name}-${version}.tar.gz https://github.com/protocolbuffers/protobuf/archive/v$version.tar.gz
        tar xf ${name}-${version}.tar.gz 
    fi

    cd ${name}-${version}

    ./autogen.sh
    ./configure --prefix=$CONDA_ENV

    make -j 
    make install
    
    cd $ROOT
} 

function build_mlsl 
{ 
    wget https://github.com/intel/MLSL/releases/download/v2018.1-Preview/l_mlsl_2018.1.005.tgz
    tar -xzvf l_mlsl_2018.1.005.tgz

    cd l_mlsl_2018.1.005
    tar -xzvf files.tar.gz

    yes y | sh install.sh -d $CONDA_ENV/intel_mlsl
    
    cd $ROOT
} 

function build_caffe 
{ 
    name='caffe'
    version='1.1.5'

    if [ ! -d ${name}-${version} ]
    then
        wget -O ${name}-${version}.tar.gz https://github.com/intel/caffe/archive/$version.tar.gz
        tar xf ${name}-${version}.tar.gz
    fi

    mkdir -p ${name}-${version}/build 
    cd ${name}-${version}/build 

    cmake .. -DCPU_ONLY=1                      \
             -DBLAS=mkl                        \
             -DUSE_MLSL=1                      \
             -DBOOST_ROOT=$CONDA_ENV           \
             -DMLSL_ROOT=$CONDA_ENV/intel_mlsl \
             -DCMAKE_INSTALL_PREFIX=$CONDA_ENV 

    make -j
    make install
    
    cd $ROOT
} 

build_opencv
build_glog 
build_gflags
build_leveldb
build_protobuf
build_mlsl
build_caffe
