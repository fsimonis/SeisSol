/**
 * @file
 * This file is part of SeisSol.
 *
 * @author Carsten Uphoff (c.uphoff AT tum.de, http://www5.in.tum.de/wiki/index.php/Carsten_Uphoff,_M.Sc.)
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
 **/

#ifndef MODEL_SETUP_H_
#define MODEL_SETUP_H_

#include <Initializer/typedefs.hpp>
#include <Model/datastructures.hpp>
#include <Geometry/MeshDefinition.h>
#include <Numerical_aux/MatrixView.h>

namespace seissol {
  namespace model {
    /**
     * Returns the transposition of the matrices A, B, C of
     * dQp_dt + A_pq dQq_dx + B_pq dQq_dy + C_pq dQq_dz
     **/
    void getTransposedCoefficientMatrix( Material const& i_material,
                                         unsigned        i_dim,
                                         real            o_M[STAR_NNZ] );

    /**
     * Solves the Riemann problem at an interface. Note that this routine
     * returns the transposed flux solvers.
     **/
    void getTransposedRiemannSolver( seissol::model::Material const&                        local,
                                     seissol::model::Material const&                        neighbor,
                                     enum ::faceType                                        type,
                                     //real const                                             Atransposed[STAR_NNZ],
                                     MatrixView<NUMBER_OF_QUANTITIES, NUMBER_OF_QUANTITIES> Flocal,
                                     MatrixView<NUMBER_OF_QUANTITIES, NUMBER_OF_QUANTITIES> Fneighbor );

    /**
     * Converts the fortran material array to the C++ material struct.
     **/
    void setMaterial( double* i_materialVal,
                      int i_numMaterialVals,
                      seissol::model::Material* o_material );
                      
    /**
     * Returns the rotation and inverse rotation matrices in order to
     * rotate the equation system into a face-local coordinate system
     * that is aligned with the normal and tangents.
     **/
    void getFaceRotationMatrix( VrtxCoords const i_normal,
                                VrtxCoords const i_tangent1,
                                VrtxCoords const i_tangent2,
                                MatrixView<NUMBER_OF_QUANTITIES, NUMBER_OF_QUANTITIES> o_T,
                                MatrixView<NUMBER_OF_QUANTITIES, NUMBER_OF_QUANTITIES> o_Tinv );
                                
#ifdef REQUIRE_SOURCE_MATRIX
    void setSourceMatrix( seissol::model::Material const&                        local,
                          MatrixView<NUMBER_OF_QUANTITIES, NUMBER_OF_QUANTITIES> sourceMatrix );
#endif
  }
}

#endif
