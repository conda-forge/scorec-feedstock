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
# The MPI include dir goes in SCOREC_CXX_FLAGS, NOT CMAKE_C_FLAGS/CMAKE_CXX_FLAGS.
# cmake/bob.cmake discards whatever is passed in CMAKE_<LANG>_FLAGS:
# bob_begin_cxx_flags() starts from set(FLAGS "") and then overwrites
# CMAKE_CXX_FLAGS with it, and bob_end_cxx_flags() replaces the result outright
# when SCOREC_CXX_FLAGS is set. CMakeLists.txt:53 then copies CMAKE_CXX_FLAGS
# into CMAKE_C_FLAGS, so this one variable covers both languages.
# Passing it any other way gives "pcu_defines.h:6:10: fatal error: 'mpi.h' file
# not found": in conda-build the compiler lives in $BUILD_PREFIX while mpi.h is
# in $PREFIX, so nothing puts the host include dir on the default search path.
# -isystem rather than -I keeps it out of the way of SCOREC's own headers.
#
# ZOLTAN_INCLUDE_DIR is passed explicitly for the same reason: left unset, SCOREC
# searches for it and can settle on an unrelated prefix whose mpi.h then wins.
cmake .. \
   -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
   -DCMAKE_C_COMPILER="${CC}" \
   -DCMAKE_CXX_COMPILER="${CXX}" \
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
   -DSCOREC_CXX_FLAGS="-g -isystem ${PREFIX}/include"

make VERBOSE=1
make install
