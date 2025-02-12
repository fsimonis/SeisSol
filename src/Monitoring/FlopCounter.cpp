/**
 * @file
 * This file is part of SeisSol.
 *
 * @author Alex Breuer (breuer AT mytum.de, http://www5.in.tum.de/wiki/index.php/Dipl.-Math._Alexander_Breuer)
 *
 * @section LICENSE
 * Copyright (c) 2013, SeisSol Group
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @section DESCRIPTION
 * Counts the floating point operations in SeisSol.
 **/
#ifndef NDEBUG

#ifdef USE_MPI
#include <mpi.h>
#endif

#include "FlopCounter.hpp"

  // Define the FLOP counter.
  long long libxsmm_num_total_flops = 0;

  long long g_SeisSolNonZeroFlopsLocal = 0;
  long long g_SeisSolHardwareFlopsLocal = 0;
  long long g_SeisSolNonZeroFlopsNeighbor = 0;
  long long g_SeisSolHardwareFlopsNeighbor = 0;

  // prevent name mangling
  extern "C" {
    /**
     * Prints the measured FLOPS.
     */
    void printFlops() {
#ifdef USE_MPI
      MPI_Allreduce(MPI_IN_PLACE, &libxsmm_num_total_flops, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
      MPI_Allreduce(MPI_IN_PLACE, &g_SeisSolNonZeroFlopsLocal, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
      MPI_Allreduce(MPI_IN_PLACE, &g_SeisSolHardwareFlopsLocal, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
      MPI_Allreduce(MPI_IN_PLACE, &g_SeisSolNonZeroFlopsNeighbor, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
      MPI_Allreduce(MPI_IN_PLACE, &g_SeisSolHardwareFlopsNeighbor, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
      int rank;
      MPI_Comm_rank(MPI_COMM_WORLD, &rank);
#else
      int rank = 0;
#endif
      logInfo(rank) << "Total   measured HW-GFLOP: " << ((double)libxsmm_num_total_flops)/1e9;
      logInfo(rank) << "Total calculated HW-GFLOP: " << ((double)(g_SeisSolHardwareFlopsLocal+g_SeisSolHardwareFlopsNeighbor))/1e9;
      logInfo(rank) << "Total calculated NZ-GFLOP: " << ((double)(g_SeisSolNonZeroFlopsLocal+g_SeisSolNonZeroFlopsNeighbor))/1e9;
      logInfo(rank) << "Local calculated HW-GFLOP: " << ((double)g_SeisSolHardwareFlopsLocal)/1e9;
      logInfo(rank) << "Local calculated NZ-GFLOP: " << ((double)g_SeisSolNonZeroFlopsLocal)/1e9;
      logInfo(rank) << "Neigh calculated HW-GFLOP: " << ((double)g_SeisSolHardwareFlopsNeighbor)/1e9;
      logInfo(rank) << "Neigh calculated NZ-GFLOP: " << ((double)g_SeisSolNonZeroFlopsNeighbor)/1e9;
    }
  }
#endif
