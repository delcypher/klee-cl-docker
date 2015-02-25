###############################################################################
# This builds KLEE-CL based on instructions from
#
# http://www.pcc.me.uk/~peter/klee-fp/
#
###############################################################################
FROM ubuntu:12.04
MAINTAINER Dan Liew <daniel.liew@imperial.ac.uk>

ENV LLVM_CLANG_REVISION=146372

# Setup tools needs for build and very basic development
RUN apt-get update && apt-get -y --no-install-recommends install \
    python \
    python-dev \
    python-pip \
    cmake \
    zlib1g-dev \
    zlib1g \
    git \
    make \
    patch \
    libedit-dev \
    vim \
    gcc \
    gcc-4.6 \
    g++ \
    g++-4.6 \
    subversion \
    less \
    flex \
    bison

# Add a non-root user
RUN useradd -m kleecl
USER kleecl
WORKDIR /home/kleecl

# Get klee-cl
RUN mkdir klee-cl & git clone https://github.com/delcypher/klee-cl.git klee-cl/src

# Get LLVM and Clang
RUN mkdir llvm_and_clang && \
    cd llvm_and_clang && \
    svn co -r ${LLVM_CLANG_REVISION} http://llvm.org/svn/llvm-project/llvm/trunk src && \
    cd src/tools/ && \
    svn co -r ${LLVM_CLANG_REVISION} http://llvm.org/svn/llvm-project/cfe/trunk clang

# Patch LLVM and clang and then build
RUN cd llvm_and_clang/src/ && \
    patch -p1 -i ~/klee-cl/src/patches/llvm-Define-the-KLEE-OpenCL-target.patch && \
    patch -p1 -i ~/klee-cl/src/patches/llvm-build-python.patch && \
    cd tools/clang && \
    patch -p1 -i ~/klee-cl/src/patches/clang-Define-the-KLEE-OpenCL-target.patch && \
    cd ~/llvm_and_clang/ && \
    mkdir build && \
    cd build && \
    ../src/configure --enable-debug-symbols --enable-assertions && \
    make

# Get klee-uclibc
# Note the first make is expected to fail according to Peter Collingbourne's  instruction
ENV C_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
ENV CPLUS_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
RUN git clone git://git.pcc.me.uk/~peter/klee-uclibc.git && \
    cd klee-uclibc && \
    python configure --with-llvm=/home/kleecl/llvm_and_clang/build && \
    make -i && \
    touch lib/crtn.o && \
    make

# STP. Use r940
# FIXME: Should just use latest upstream
# old STP is really gross
RUN mkdir stp && cd stp && \
    git clone git://github.com/stp/stp.git src_build && \
    cd src_build && \
    git checkout bc78d1f9f06fc095bd1ddad90eacdd1f05f64dae && \
    mkdir bin && \
    mkdir install && \
    ./scripts/configure --with-prefix=`pwd`/install --with-cryptominisat2 && \
    make OPTIMIZE=-O2 CFLAGS_M32= install

# Build KLEE-CL
RUN cd klee-cl && \
    mkdir build && \
    cd build && \
    ../src/configure --enable-posix-runtime --enable-opencl \
    --with-uclibc="/home/kleecl/klee-uclibc" \
    --with-stp="/home/kleecl/stp/src_build/install" \
    --with-llvmsrc="/home/kleecl/llvm_and_clang/src" \
    --with-llvmobj="/home/kleecl/llvm_and_clang/build" && \
    make

# Add to PATH
RUN echo 'PATH=/home/kleecl/klee-cl/build/Debug+Asserts/bin:$PATH' >> ~/.bashrc
