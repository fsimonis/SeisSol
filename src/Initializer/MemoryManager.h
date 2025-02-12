/**
 * @file
 * This file is part of SeisSol.
 *
 * @author Alex Breuer (breuer AT mytum.de, http://www5.in.tum.de/wiki/index.php/Dipl.-Math._Alexander_Breuer)
 *
 * @section LICENSE
 * Copyright (c) 2013-2015, SeisSol Group
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
 * Memory management of SeisSol.
 **/

#ifndef MEMORYMANAGER_H_
#define MEMORYMANAGER_H_

#ifdef USE_MPI
#include <mpi.h>
#endif

#include <utils/logger.h>

#include <Initializer/typedefs.hpp>
#include "XmlParser.hpp"
#include "MemoryAllocator.h"

namespace seissol {
  namespace initializers {
    class MemoryManager;
  }
}

/**
 * Memory manager of SeisSol.
 **/
class seissol::initializers::MemoryManager {
  private: // explicit private for unit tests
    //! memory allocator
    seissol::MemoryAllocator m_memoryAllocator;

    /**
     * Sparse switch: -1 if matrix is dense, nnz if sparse
     *
     *    0-3:   \f$ M^{-1} F^{-, i}        \f$
     *    4:     \f$ M^{-1} F^+{+, 1, 1, 1} \f$
     *    5:     \f$ M^{-1} F^+{+, 1, 1, 2} \f$
     *    [..]
     *    51:    \f$ M^{-1} F^+{+, 4, 4, 3} \f$
     *    53-55: \f$ M^{-1} K_{\xi_c}       \f$
     *    56-58: \f$ M^{-1} (K_{\xi_c})^T   \f$
     *    52:    \f$ N_{k,i} A_k^+ N_{k,i}^{-1}\f$ or \f$ N_{k,i} A_{k(i)}^- N_{k,i}^{-1 \f$
     *    59:    \f$ A^{star, c} \f$
     **/
    int m_sparseSwitch[60];

    /**
     * Addresses of the global flux matrices (multiplied by the inverse diagonal mass matrix):
     *
     *    0:  \f$ M^{-1} F^{-, 1} \f$
     *    1:  \f$ M^{-1} F^{-, 2} \f$
     *    2:  \f$ M^{-1} F^{-, 3} \f$
     *    3:  \f$ M^{-1} F^{-, 4} \f$
     *    4:  \f$ M^{-1} F^+{+, 1, 1, 1} \f$
     *    5:  \f$ M^{-1} F^+{+, 1, 1, 2} \f$
     *    6:  \f$ M^{-1} F^+{+, 1, 1, 3} \f$
     *    7:  \f$ M^{-1} F^+{+, 1, 2, 1} \f$
     *    8:  \f$ M^{-1} F^+{+, 1, 1, 2} \f$
     *    9:  \f$ M^{-1} F^+{+, 1, 1, 3} \f$
     *    [..]
     *    51: \f$ M^{-1} F^+{+, 4, 4, 3} \f$
     *    52: \f$ N_{k,i} A_k^+ N_{k,i}^{-1}\f$ or \f$ N_{k,i} A_{k(i)}^- N_{k,i}^{-1} \f$
     *
     **/ 
    real** m_fluxMatrixPointers;

    /**
     * Addresses of the global stiffness matrices (multiplied by the inverse diagonal mass matrix):
     *
     *    0:  \f$ M^{-1} K^\xi \f$
     *    1:  \f$ M^{-1} K^\eta \f$
     *    2:  \f$ M^{-1} K^\zeta f$
     *    3:  \f$ M^{-1} ( K^\xi )^T \f$
     *    4:  \f$ M^{-1} ( K^\eta )^T \f$
     *    5:  \f$ M^{-1} ( K^\zeta )^T \f$
     *
     **/ 
    real** m_stiffnessMatrixPointers;
    
    /**
     * Address of the global inverse mass matrix
     **/ 
    real* m_inverseMassMatrixPointer;

    //! LTS mesh structure
    struct MeshStructure *m_meshStructure;

    //! number of time stepping clusters
    unsigned int m_numberOfClusters;

    //! total number of cells in all layers and clusters.
    unsigned int m_totalNumberOfCells;

    //! total number of interior cells across all clusters.
    unsigned int m_totalNumberOfInteriorCells;

    //! total number of ghost cells across all clusters.
    unsigned int m_totalNumberOfGhostCells;

    //! total number of copy cells across all clusters
    unsigned int m_totalNumberOfCopyCells;

    /*
     * Interior
     */
    //! number of buffers in the interior per cluster
    unsigned int *m_numberOfInteriorBuffers;

    //! number of derivatives in the interior per cluster
    unsigned int *m_numberOfInteriorDerivatives;

    //! interior information
    CellLocalInformation **m_interiorCellInformation;

#ifdef USE_MPI
    /*
     * Ghost layer
     */
    //! number of buffers in the ghost layer per cluster
    unsigned int  *m_numberOfGhostBuffers;

    //! number of buffers in the ghost regions per cluster
    unsigned int **m_numberOfGhostRegionBuffers;

    //! number of derivatives in the ghost layer per cluster
    unsigned int  *m_numberOfGhostDerivatives;

    //! number of derivatives in the ghost regions per cluster
    unsigned int **m_numberOfGhostRegionDerivatives;

    //! ghost information
    CellLocalInformation **m_ghostCellInformation;

    /*
     * Copy Layer
     */
    //! number of buffers in the copy layer per cluster
    unsigned int  *m_numberOfCopyBuffers;

    //! number of buffers in the copy regions per cluster
    unsigned int **m_numberOfCopyRegionBuffers;

    //! number of derivatives in the copy layer per cluster
    unsigned int  *m_numberOfCopyDerivatives;

    //! number of derivatives in the copy regionsper cluster
    unsigned int **m_numberOfCopyRegionDerivatives;

    //! copy information
    CellLocalInformation **m_copyCellInformation;
#endif

    /*
     * Cross-cluster
     */
    //! global data
    struct GlobalData     m_globalData;

#ifdef USE_MPI
    struct CellData      *m_copyCellData;
#endif

    //! cell data per cluster
    struct CellData      *m_interiorCellData;

    //! internal state
    struct InternalState  m_internalState;

    //! cells per cluster
    struct Cells         *m_cells;

    /**
     * Initializes a global matrix with the given values.
     *
     * @param i_sparse true if sparse, false if dense.
     * @param i_leadingDimension leading dimension.
     * @param i_numberOfColumns number of columns.
     * @param i_rows rows in sparse coordinate format.
     * @param i_columns columns in sparse coordinate format.
     * @param i_values values in sparse coordinate format.
     * @param o_matrix global matrix, which values are set.
     **/
    void initializeGlobalMatrix(       int                        i_sparse,
                                       unsigned int               i_leadingDimension,
                                       unsigned int               i_numberOfColumns,
                                 const std::vector<unsigned int> &i_rows,
                                 const std::vector<unsigned int> &i_columns,
                                 const std::vector<double>       &i_values,
                                       real*                      o_matrix );

    /**
     * Allocates memory for the global matrices and initializes it.
     *
     * @param i_matrixReader XML matrix reader.
     **/
    void initializeGlobalMatrices( const seissol::XmlParser &i_matrixReader );

    /**
     * Sets up the layers: Total number of ghost, copy and interior cells & cell information per layer.
     **/
    void setUpLayers( struct CellLocalInformation* i_cellLocalInformation );

    /**
     * Corrects the LTS Setups (buffer or derivatives, never both) in the ghost region
     *
     * @param io_cellLocalInformation cell local information.
     **/
    void correctGhostRegionSetups( struct CellLocalInformation *io_cellLocalInformation ); 

    /**
     * Derives the layouts -- number of buffers and derivatives -- of the layers.
     **/
    void deriveLayerLayouts();

    /**
     * Allocates memory for the constant data.
     **/
    void allocateConstantData();

    /**
     * Touches / zeros the constant data using OMP's first touch policy.
     *
     * @param i_numberOfCells number of cells (split statically by the number of threads).
     * @param o_local local data to initialize.
     * @param o_neighboring neighboring data to initialize.
     **/
    void touchConstantData( unsigned int                i_numberOfCells,
                            LocalIntegrationData*       o_local,
                            NeighboringIntegrationData* o_neighboring );

    /**
     * Initializes the constant data.
     **/
    void initializeConstantData();

    /**
     * Allocates memory for the internal state
     **/
    void allocateInternalState();

    /**
     * Initializes the face neighbor pointers of the internal state.
     **/
    void initializeFaceNeighbors();

    /**
     * Initializes the pointers of the internal state.
     **/
    void initializeInternalState();

    /**
     * Allocates the cells.
     **/
    void allocateCells();

    /**
     * Touches / zeros the DOFs using OMP's first touch policy.
     *
     * @param i_numberOfCells number of cells (split statically by the number of threads).
     * @param o_dofs dofs which are touched.
     **/
    void touchDofs( unsigned int   i_numberOfCells,
                    real         (*o_dofs)[NUMBER_OF_ALIGNED_DOFS] );

    /**
     * Touches / zeros the buffers and derivatives of the cells using OMP's first touch policy.
     *
     * @param i_numberOfCells number of cells which are touched.
     * @param o_buffers buffers which are touched.
     * @param o_derivatives derivatives which are touched. 
     **/
    void touchTime( unsigned int   i_numberOfCells,
                    real         **o_buffers,
                    real         **o_derivatives );

    /**
     * Initializes the cell data.
     **/
    void initializeCells();

#ifdef USE_MPI
    /**
     * Initializes the communication structure.
     **/
    void initializeCommunicationStructure();
#endif

  public:
    /**
     * Constructor, which allocates memory for the global matrices and initializes them.
     *
     * @param i_matrixReader XML matrix reader.
     **/
    MemoryManager( const seissol::XmlParser &i_matrixReader );

    /**
     * Destructor, which frees all allocated memory.
     **/
    ~MemoryManager();

    /**
     * Gets the pointers to the 52 memory chunks of the flux matrices.
     * Additionally the 53rd pointer gives the address of the stiffness matrix \f$ M^{-1} K^\xi \f$. 
     *
     * @return 52 pointers to the memory chunks of the flux matrices (and as 53rd pointer \f$ M^{-1} K^\xi \f$).
     **/
    real** getFluxMatrixPointers() const;

    /**
     * Get the pointers to the 2*3 (non-transposed and transposed) memory chunks of the stiffness matrices.
     * Additionally the seventh pointer gives the address of the flux matrix \f$ M^{-1} F^{-, 1} \f$.
     *
     * @return 6 pointers to the memory chunks of the flux matrices (and as 7th pointer \f$ M^{-1} F^{-, 1} \f$).
     **/    
    real** getStiffnessMatrixPointers() const;

    /**
     * Set the pointers to the stiffness matrices (multiplied in by \f$M^-1\f$)
     *
     * @param o_stiffnessMatrices pointers, which will be set.
     */
    void setStiffnessMatrices( real *o_stiffnessMatrices[3] );
    
    /**
     * Set the pointers to the transposed stiffness matrices (multiplied in by \f$M^-1\f$)
     *
     * @param o_stiffnessMatricesTransposed pointers, which will be set.
     */
    void setStiffnessMatricesTransposed( real *o_stiffnessMatricesTransposed[3] );

    /**
     * Set the pointers to the flux matrices (multiplied in by \f$M^-1\f$)
     *
     * @param o_fluxMatrices pointers, which will be set.
     */
    void setFluxMatrices( real *o_fluxMatrices[52] );

    /**
     * Set the pointers to the inverse matrix
     *
     * @param o_inverseMassMatrix pointer, which will be set.
     */
    void setInverseMassMatrix( real* o_inverseMassMatrix );

    /**
     * Set up the internal structure, allocate memory, set up the pointers and intializes the data to zero or NULL.
     *
     * @param i_timeStepping time stepping.
     * @param i_meshStructrue mesh structure.
     * @param io_cellLocalInformation cells local information.
     **/
    void initializeMemoryLayout( struct TimeStepping         &i_timeStepping,
                                 struct MeshStructure        *i_meshStructure,
                                 struct CellLocalInformation *io_cellLocalInformation );

    /**
     * Gets the memory layout of a time cluster.
     *
     * @param i_cluster local id of the time cluster.
     * @param o_meshStructure mesh structure.
     * @param o_copyCellInformation cell information in the copy layer.
     * @param o_interiorCellInformation cell information in the interior.
     * @param o_globalData global data.
     * @param o_copyCellData cell data of the copy layer.
     * @param o_interiorCellData cell data in the interior.
     * @param o_cells cells.
     **/
    void getMemoryLayout( unsigned int                    i_cluster,
                          struct MeshStructure          *&o_meshStructure,
#ifdef USE_MPI
                          struct CellLocalInformation   *&o_copyCellInformation,
#endif
                          struct CellLocalInformation   *&o_interiorCellInformation,
                          struct GlobalData             *&o_globalData,
#ifdef USE_MPI
                          struct CellData               *&o_copyCellData,
#endif
                          struct CellData               *&o_interiorCellData,
                          struct Cells                  *&o_cells );
};

#endif
