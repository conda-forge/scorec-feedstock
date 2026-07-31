mkdir -p build; cd $_

# SCOREC's CMakeLists.txt declares cmake_minimum_required(VERSION 3.0), which
# CMake 4.x (this build image) hard-rejects rather than just warns about --
# support for <3.5 was fully removed, not merely deprecated.
cmake .. \
   -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
   -DCMAKE_C_COMPILER=mpicc \
   -DCMAKE_CXX_COMPILER=mpicxx \
   -DCMAKE_MAKE_PROGRAM=make \
   -DENABLE_ZOLTAN=ON \
   -DMETIS_LIBRARY=$PREFIX/lib/libmetis${SHLIB_EXT} \
   -DPARMETIS_LIBRARY=$PREFIX/lib/libparmetis${SHLIB_EXT} \
   -DPARMETIS_INCLUDE_DIR=$PREFIX/include \
   -DZOLTAN_LIBRARY=${PREFIX}/lib/libzoltan.a \
   -DBUILD_SHARED_LIBS=True \
   -DCMAKE_INSTALL_PREFIX=$PREFIX \
   -DMESHES="${SRC_DIR}/pumi-meshes" \
   -DCMAKE_BUILD_TYPE=Debug \
   -DSCOREC_CXX_FLAGS="-g"

make VERBOSE=1
make install
