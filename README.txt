This is a development version of SeisSol.

================================================================
I. Folder Structure
================================================================

It contains the following folders:
- build/
  Files for compiling the optimized generated kernel version
- Documentation/   
  User Manual and tutorial can be found here
- examples/
  Some ready to go initial examples
- Maple/
  Includes precomputed basis functions and other Maple tools; folder is essential to run SeisSol
- postprocessing/
  - science
    Tool box of Matlab, Python scripts for postprocessing
  - visualization/
    - DGVisu/
      Contains source files for postprocessing the high-resolution output, readme included
    - tools
      Tool box for all kind of visualization support
- prepocessing/
  - seissol_kernels
    submodule which is used to generate, test and tune SeisSol computational backend
  - partitioning
    All kind of partitioning support files, including re-order approaches
  - science
    Tool box of Matlab, Python scripts for preprocessing
- src/
  SeisSol source files are here
- submodules/
  Libraries


================================================================
II. Compiling SeisSol
================================================================

In order to run SeisSol, you need to first install:
- Python
- SCons     (for instructions see below)
- hdf5      (for instructions see below)
- netcdf    (for instructions see below)
- Intel Compiler (icc/icpc/ifort) Suite (GCC support can be added manual)
- Some MPI implementation
- Metis for partitioning

A. Inital Adjustments to .bashrc
--------------------------------

1. add following lines to your .bashrc (vi ~/.bashrc), which should be on the NAS
<code>
# These are the versions we validated against
source /opt/intel/compiler/VERSION/bin/compilervars.sh intel64

# User specific aliases and functions
export PATH=$HOME/bin:$PATH
export LD_LIBRARY_PATH=$HOME/lib:$HOME/lib64:$LD_LIBRARY_PATH
export EDITOR=vi
export SCONS_LIB_DIR=$HOME/lib64/scons-2.2.0/
</code>


B. Installing SCons
-------------------

(0. wget http://prdownloads.sourceforge.net/scons/scons-2.2.0.tar.gz)
1. tar -xaf scons-2.2.0.tar.gz
2. cd scons-2.2.0
3. python setup.py install --prefix=$HOME
4. cd ..


C. Installing HDF5
------------------

(0. wget http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.11/src/hdf5-1.8.11.tar.bz2)
1. tar -xaf hdf5-1.8.11.tar.bz2
2. cd hdf5-1.8.11 
3. CC=mpiicc FC=mpiifort ./configure --enable-parallel --prefix=$HOME --with-zlib --disable-shared --enable-fortran
   NOTE: This is with Intel MPI, if you have to use a different MPI, please adjust mpiicc and mpiifort accordingly to
         the scripts that call icc and ifort!
   MPICH note: CC=mpicc FC=mpif90 ./configure --enable-parallel --prefix=$HOME --with-zlib --disable-shared --enable-fortran
4. make
5. make install
6. cd ..


D. Installing netCDF
--------------------

(0. wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-4.3.0.tar.gz)
1. tar -xaf netcdf-4.3.0.tar.gz
2. cd netcdf-4.3.0
3. CPPFLAGS=-I$HOME/include LDFLAGS=-L$HOME/lib CC=mpiicc ./configure --enable-shared=no --prefix=$HOME
   MPICH note: CPPFLAGS=-I$HOME/include LDFLAGS=-L$HOME/lib CC=mpicc ./configure --enable-shared=no --prefix=$HOME
   NOTE: Check for this line to make sure netCDF is build with parallel I/O: "checking whether parallel I/O features are to be included... yes"
         This line comes at the very end (last 50 lines of configure run)!
4. make
5. make install
6. cd ..


E. Compiling SeisSol
--------------------

1. scons -f SConstruct_generatedKernels buildVariablesFile=build/options/supermuc_mac_cluster.py compileMode=release arch=$ARCH numberOfTemporalIntegrationPoints=1 cppCompiler=mpiicpc fortranCompiler=mpiifort order=$ORDER generatedKernels=yes netcdf=yes netcdfDir=$HOME hdf5Dir=$HOME -j 32 

with:
ORDER convergence order you want to use
ARCH target architecture

NOTE: This is with Intel MPI, if you have to use a different MPI, please adjust mpiicc and mpiifort accordingly to
         the scripts that call icc and ifort!

you can run scons -f SConstruct_generatedKernels -h to get some help on options

Please note, this builds the generated kernel version of SeisSols. For SeisSol classic, please add 
the generatedKernels=no switch, however this result in roughly 6X less performance, but probably greater physics support.


================================================================
III. Running SeisSol
================================================================

1. mkdir -p launch_SeisSol
2. cp -r Maple/ launch_SeisSol/
3. cp build/SeisSol* launch_SeisSol/
4. cp preprocessing/matrices/*.xml launch_SeisSol/
5. echo $PWD/launch_SeisSol/Maple/ > launch_SeisSol/DGPATH
6. copy your input files (meshes, parameter file, etc.) to launch_SeisSol
6a. you can copy our small example, if you don't have own meshes right now:
    cp -r examples/small_example/* launch_SeisSol/
7. cd launch_SeisSol
8. run SeisSol version of interest
8a. To run the example: ./SeisSol_release_.... PARAMETER.PAR 

!!!!
Further information regarding meshing and parameter files etc. can be found
in the documentation folder.
!!!!

================================================================
IV. Adding a new backend
================================================================

High-level description to be added
please navitage to preprocessing/seissol_kernels for details

