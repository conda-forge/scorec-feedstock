mkdir -p build; cd $_

# SCOREC's CMakeLists.txt declares cmake_minimum_required(VERSION 3.0), which
# CMake 4.x (this build image) hard-rejects rather than just warns about --
# support for <3.5 was fully removed, not merely deprecated.
#
# Do NOT use mpicc/mpicxx as CMAKE_C_COMPILER/CMAKE_CXX_COMPILER. openmpi's
# wrappers are real compiled binaries (mpich's are portable shell scripts), so
# under the osx-arm64 cross-compile the target-arch mpicxx cannot execute on the
# osx-64 build host and CMake dies identifying the compiler:
#   mpicxx: Bad CPU type in executable
# That is the sole reason osx-arm64+openmpi was skipped. SCOREC needs no MPI
# wrapper: it has no find_package(MPI) and never links MPI explicitly, it just
# expects mpi.h and -lmpi to be available. Supplying those to the ordinary conda
# cross-compilers works for every platform/MPI combination and removes the skip.
#
# -isystem, not -I: CMake emits $(CXX_INCLUDES) ahead of $(CXX_FLAGS), so a plain
# -I here loses to any include dir CMake discovered itself. Verified locally: a
# stray second mpi.h won the race and produced an MPI_Comm ABI mismatch
# (undefined pcu::PCU::DupComm(int*) -- MPICH's `int` vs openmpi's pointer type).
#
# ZOLTAN_INCLUDE_DIR is passed explicitly for the same reason: left unset, SCOREC
# searches for it and can settle on an unrelated prefix whose mpi.h then wins.
cmake .. \
   -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
   -DCMAKE_C_COMPILER="${CC}" \
   -DCMAKE_CXX_COMPILER="${CXX}" \
   -DCMAKE_C_FLAGS="${CFLAGS} -isystem ${PREFIX}/include" \
   -DCMAKE_CXX_FLAGS="${CXXFLAGS} -isystem ${PREFIX}/include" \
   -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS} -lmpi" \
   -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS} -lmpi" \
   -DMPIRUN=$PREFIX/bin/mpirun \
   -DCMAKE_MAKE_PROGRAM=make \
   -DENABLE_ZOLTAN=ON \
   -DMETIS_LIBRARY=$PREFIX/lib/libmetis${SHLIB_EXT} \
   -DPARMETIS_LIBRARY=$PREFIX/lib/libparmetis${SHLIB_EXT} \
   -DPARMETIS_INCLUDE_DIR=$PREFIX/include \
   -DZOLTAN_LIBRARY=${PREFIX}/lib/libzoltan.a \
   -DZOLTAN_INCLUDE_DIR=${PREFIX}/include \
   -DBUILD_SHARED_LIBS=True \
   -DCMAKE_INSTALL_PREFIX=$PREFIX \
   -DMESHES="${SRC_DIR}/pumi-meshes" \
   -DCMAKE_BUILD_TYPE=Debug \
   -DSCOREC_CXX_FLAGS="-g"

make VERBOSE=1
make install
