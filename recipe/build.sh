mkdir -p build; cd $_

cmake .. \
   -DCMAKE_C_COMPILER=mpicc \
   -DCMAKE_CXX_COMPILER=mpicxx \
   -DCMAKE_MAKE_PROGRAM=make \
   -DENABLE_ZOLTAN=ON \
   -DMETIS_LIBRARY=$PREFIX/lib/libmetis${SHLIB_EXT} \
   -DPARMETIS_LIBRARY=$PREFIX/lib/libparmetis${SHLIB_EXT} \
   -DPARMETIS_INCLUDE_DIR=$PREFIX/include \
   -DZOLTAN_LIBRARY=${PREFIX}/lib/libzoltan.a \
   -DBUILD_SHARED_LIBS=True \
   -DCMAKE_INSTALL_PREFIX=$PREFIX
   -DMESHES=${SRC_DIR}/pumi-meshes \

make VERBOSE=1
make install
