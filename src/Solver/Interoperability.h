/**
 * @file
 * This file is part of SeisSol.
 *
 * @author Alex Breuer (breuer AT mytum.de, http://www5.in.tum.de/wiki/index.php/Dipl.-Math._Alexander_Breuer)
 * @author Sebastian Rettenberger (sebastian.rettenberger @ tum.de, http://www5.in.tum.de/wiki/index.php/Sebastian_Rettenberger)
 * 
 * @section LICENSE
 * Copyright (c) 2015, SeisSol Group
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
 * C++/Fortran-interoperability.
 **/

#ifndef INTEROPERABILITY_H_
#define INTEROPERABILITY_H_

#include <vector>
#include <Initializer/typedefs.hpp>
#include <Kernels/Time.h>

namespace seissol {
  class Interoperability;
}

/**
 *  C++ binding to all required fortran functions.
 **/
class seissol::Interoperability {
  // private:
    //! time kernel
    seissol::kernels::Time m_timeKernel;

    /* Brain dump of SeisSol's Fortran parts:
     * Raw fotran-pointer to cope with limited modularity of the
     * source, receiver and dynamic rupture functions.
     */
    //! domain (tDomain)
    void *m_domain;

    /*
     * Brain dump of SeisSol's C parts.
     */
    //! number of cells in the mesh
    unsigned int m_numberOfMeshCells;

    //! number of LTS cells
    unsigned int m_numberOfLtsCells;

    //! number of copy interior cells
    unsigned int m_numberOfCopyInteriorCells;

    //! cluster-local interior cell information
    struct CellLocalInformation *m_cellInformation;

    //! mapping from mesh to lts layout
    unsigned int *m_meshToLts;

    //! mapping from mesh to lts layout without ghost layers
    unsigned int *m_meshToCopyInterior;

    //! mapping from mesh to clusters
    unsigned int (*m_meshToClusters)[2];

    //! mapping from lts layout to mesh
    unsigned int *m_ltsToMesh;

    //! mapping from copy-interior id to mesh
    unsigned int *m_copyInteriorToMesh;

    //! cluster-local mesh structure
    struct MeshStructure *m_meshStructure;

    //! time stepping
    struct TimeStepping m_timeStepping;

    //! global data
    struct GlobalData *m_globalData;

    //! raw cell data: covering copy&interior of all clusters
    struct CellData *m_cellData;

    //! raw DOFs: covering copy&interior of all clusters
    real (*m_dofs)[NUMBER_OF_ALIGNED_DOFS];

    //! raw pointers to derivatives: covering all clusters and layers
    real **m_derivatives;

    //! raw pointers to buffers: covering all clusters and layers
    real **m_buffers;

    //! raw pointers to face neighbors: covering all clusters and layers.
    real *(*m_faceNeighbors)[4];

    //! mapping: point source id to cluster id [0] and to cluster-local point source id [1]
    unsigned (*m_pointSourceToCluster)[2];
    
    //! Point sources for each cluster
    PointSources* m_pointSources;
    
    //! Mapping of cells to point sources for each cluster
    CellToPointSourcesMapping** m_cellToPointSources;
    
    //! Number of mapping of cells to point sources for each cluster
    unsigned* m_numberOfCellToPointSourcesMappings;

 public:
   /**
    * Constructor.
    **/
   Interoperability();
   
   ~Interoperability();

   /**
    * Sets the fortran domain.
    *
    * @param i_domain domain.
    */
   void setDomain( void *i_domain );

   /**
    * Sets the time step width of a cell.
    *
    * @param i_meshId mesh id.
    * @param i_timeStepWidth time step width of the cell, Fortran notation is assumed (starting at 0).
    **/
   void setTimeStepWidth( int    *i_meshId,
                          double *i_timeStepWidth );

   /**
    * Initializes clustered local time stepping.
    *   1) Derivation of the LTS layout
    *   2) Memory Setup
    *   3) Generation of LTS computer clusters
    *
    * Clustering stategy is mapped as follows:
    *   1:  Global time stepping
    *   2+: Fixed rate between clusters
    *
    * @param i_clustering clustering strategy 
    **/
   void initializeClusteredLts( int *i_clustering );
  
   //! \todo Documentation
   void allocatePointSources( int* i_meshIds,
                              int* i_numberOfPointSources );
   
   //! \todo Documentation                          
   void setupPointSource( int* i_source,
                          double* i_mInvJInvPhisAtSources,
                          double* i_localMomentTensor,
                          double* i_strike,
                          double* i_dip,
                          double* i_rake,
                          double* i_samples,
                          int* i_numberOfSamples,
                          double* i_onsetTime,
                          double* i_samplingInterval );

   /**
    * Adds a receiver at the specified mesh id.
    *
    * @param i_receiverId pointer to the global id of the receiver.
    * @param i_meshId pointer to the mesh id.
    **/
   void addReceiver( int *i_receiverId,
                     int *i_meshId );

   /**
    * Sets the sampling of the receivers.
    *
    * @param i_receiverSampling sampling of the receivers.
    **/
   void setReceiverSampling( double *i_receiverSampling );

   /**
    * Enables dynamic rupture.
    **/
   void enableDynamicRupture();
   
   /**
    * Set material parameters for cell
    **/
   void setMaterial( int*    i_meshId,
                     int*    i_side,
                     double* i_materialVal,
                     int*    i_numMaterialVals );

   /**
    * Sets the intial loading for a cell (plasticity).
    *
    * @param i_meshId mesh id.
    * @param i_initialLoading initial loading (stress tensor).
    **/
#ifdef USE_PLASTICITY
   void setInitialLoading( int    *i_meshId,
                           double *i_initialLoading );
#endif
   
   /**
    * \todo Move this somewhere else when we have a C++ main loop.
    **/
   void initializeCellLocalMatrices();


   /**
    * Synchronizes the cell local material data.
    **/
   void synchronizeMaterial();

   /**
    * Synchronizes the DOFs in the copy layer.
    **/
   void synchronizeCopyLayerDofs();

   /**
    * Enable wave field plotting.
    *
    * @param i_waveFieldInterval plotting interval of the wave field.
    * @param i_waveFieldFilename file name prefix of the wave field.
    **/
   void enableWaveFieldOutput( double *i_waveFieldInterval, const char *i_waveFieldFilename );

   /**
    * Enable checkpointing.
    *
    * @param i_checkPointInterval check pointing interval.
    * @param i_checkPointFilename file name prefix for checkpointing.
    * @param i_checkPointBackend name of the checkpoint backend
    **/
   void enableCheckPointing( double *i_checkPointInterval,
		   const char *i_checkPointFilename, const char* i_checkPointBackend );

   void initializeIO(double* mu, double* slipRate1, double* slipRate2,
			  double* slip1, double* slip2, double* state, double* strength,
			  int numSides, int numBndGP);

   /**
    * Get the current dynamic rupture time step
    *
    * @param o_timeStep The dynamic rupture time step
    */
   void getDynamicRuptureTimeStep(int &o_timeStep);

   /**
    * Adds the specified update to dofs.
    *
    * @param i_mesh mesh id of the cell, Fortran notation is assumed - starting at 1 instead of 0.
    * @param i_update update which is applied.
    **/
   void addToDofs( int    *i_meshId,
                   double  i_update[NUMBER_OF_DOFS] );

   /**
    * Writes the receivers.
    *
    * @param i_fullUpdateTime full update time of the DOFs relevant to the receivers.
    * @param i_timeStepWidth time step width of the next update.
    * @param i_receiverTime time of the receivers / last write.
    * @param i_receiverIds global ids of the receivers.
    **/
   void writeReceivers( double              i_fullUpdateTime,
                        double              i_timeStepWidth,
                        double              i_receiverTime,
                        std::vector< int > &i_receiverIds );

   /**
    * Gets the time derivatives (recomputed from DOFs).
    *
    * @param i_meshId mesh id.
    * @param o_timeDerivatives time derivatives in deprecated full storage scheme (including zero blocks).
    **/
   void getTimeDerivatives( int    *i_meshId,
                            double  o_timeDerivatives[CONVERGENCE_ORDER][NUMBER_OF_DOFS] );

   /**
    * Gets the time derivatives and integrated DOFs of two face neighbors.
    *
    * @param i_meshId mesh id.
    * @param i_localFaceId local id of the face neighbor.
    * @param i_timeStepWidth time step width used for the time integration.
    * @param o_timeDerivativesCell time derivatives of the cell in deprecated full storage scheme (including zero blocks).
    * @param o_timeDerivativesNeighbor time derivatives of the cell neighbor in deprecated full storage scheme (including zero blocks).
    * @param o_timeIntegratedCell time integrated degrees of freem of the cell.
    * @param o_timeIntegratedNeighbor time integrated degrees of free of the neighboring cell.
    **/
   void getFaceDerInt( int    *i_meshId,
                       int    *i_localFaceId,
                       double *i_timeStepWidth,
                       double  o_timeDerivativesCell[CONVERGENCE_ORDER][NUMBER_OF_DOFS],
                       double  o_timeDerivativesNeighbor[CONVERGENCE_ORDER][NUMBER_OF_DOFS],
                       double  o_timeIntegratedCell[NUMBER_OF_DOFS],
                       double  o_timeIntegratedNeighbor[NUMBER_OF_DOFS] );

   /**
    * Gets the DOFs.
    *
    * @param i_meshId mesh id.
    * @param o_dofs degrees of freedom.
    **/
   void getDofs( int    *i_meshId,
                 double  o_dofs[NUMBER_OF_DOFS] );

   /**
    * Gets the DOFs from the derivatives.
    * Assumes valid storage of time derivatives.
    *
    * @param i_meshId mesh id.
    * @param o_dofs degrees of freedom.
    **/
   void getDofsFromDerivatives( int    *i_meshId,
                                double  o_dofs[NUMBER_OF_DOFS] );

   /**
    * Gets the neighboring DOFs from the derivatives.
    * Assumes valid storage of time derivatives.
    *
    * @param i_meshId mesh id.
    * @param i_localFaceId local id of the face neighbor.
    * @param o_dofs degrees of freedom.
    **/
   void getNeighborDofsFromDerivatives( int    *i_meshId,
                                        int    *i_localFaceId,
                                        double  o_dofs[NUMBER_OF_DOFS] );

   /**
    * Computes dynamic rupture on the faces.
    *
    * @param i_fullUpdateTime full update time of the respective DOFs.
    * @param i_timeStepWidth time step width of the next full update.
    **/
   void computeDynamicRupture( double i_fullUpdateTime,
                               double i_timeStepWidth );

   /**
    * Computes platisticity.
    *
    * @param i_timeStep time step of the previous update.
    * @param i_initialLoading initial loading of the associated cell.
    * @param io_dofs degrees of freedom (including alignment).
    **/
#ifdef USE_PLASTICITY
   void computePlasticity( double   i_timeStep,
                           double (*i_initialLoading)[NUMBER_OF_BASIS_FUNCTIONS],
                           double  *io_dofs );
#endif

   /**
    * Simulates until the final time is reached.
    *
    * @param i_finalTime final time to reach.
    **/
   void simulate( double *i_finalTime );

   /**
    * Finalizes I/O
    */
   void finalizeIO();
};

#endif
