!>
!! @file
!! This file is part of SeisSol.
!!
!! @author Cristobal E. Castro (ccastro AT uc.cl https://sites.google.com/a/uc.cl/cristobal-e-castro/)
!!
!! @section LICENSE
!! Copyright (c) 2008-2014, SeisSol Group
!! All rights reserved.
!! 
!! Redistribution and use in source and binary forms, with or without
!! modification, are permitted provided that the following conditions are met:
!! 
!! 1. Redistributions of source code must retain the above copyright notice,
!!    this list of conditions and the following disclaimer.
!! 
!! 2. Redistributions in binary form must reproduce the above copyright notice,
!!    this list of conditions and the following disclaimer in the documentation
!!    and/or other materials provided with the distribution.
!! 
!! 3. Neither the name of the copyright holder nor the names of its
!!    contributors may be used to endorse or promote products derived from this
!!    software without specific prior written permission.
!! 
!! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
!! AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
!! IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
!! ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
!! LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!! CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!! SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!! INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!! CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!! ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!! POSSIBILITY OF SUCH DAMAGE.

#include <Initializer/preProcessorMacros.fpp>


MODULE TypesDef
#ifdef GENERATEDKERNELS
  use iso_c_binding, only: c_double, c_int
#endif
  !<--------------------------------------------------------------------------
#ifdef HDF
  USE HDF5
#endif
  !<--------------------------------------------------------------------------
  IMPLICIT NONE
  !<--------------------------------------------------------------------------
  PUBLIC
  !<--------------------------------------------------------------------------
  !<
  !<--- Global variables -----------------------------------------------------
  !<
  integer myrank ! required for logging

  !<--------------------------------------------------------------------------
  !<
  !<--- General types  -------------------------------------------------------
  !<
  TYPE tSparseVector
     INTEGER                                :: m                                !<Dimension of the original vector
     INTEGER                                :: nNonZero                         !<Number of non-zero entries
     INTEGER, POINTER                       :: NonZeroIndex(:)                  !< Indices into non-zero elements
     REAL, POINTER                          :: NonZero(:)                       !<Values
  END TYPE tSparseVector

  TYPE tSparseMatrix
     INTEGER                                :: m,n                              !<Dimension of the original matrix
     INTEGER, POINTER                       :: nNonZero(:)                      !<Number of non-zero entries
     INTEGER, POINTER                       :: NonZeroIndex1(:)                 !<Index 1 into non-zero elements
     INTEGER, POINTER                       :: NonZeroIndex2(:)                 !<Index 2 into non-zero elements
     REAL, POINTER                          :: NonZero(:)                       !<Values
  END TYPE tSparseMatrix

  TYPE tSparseMatrix2
     INTEGER                                :: m,n                              !<Dimension of the original matrix
     TYPE(tSparseVector), POINTER           :: RowVector(:)                     !<Sparse row vectors of the matrix
  END TYPE tSparseMatrix2

  TYPE tSparseTensor3
     REAL, POINTER                          :: NonZero(:)                       !<Values
     INTEGER, POINTER                       :: NonZeroIndex1(:)                 !<Index 1 into non-zero elements
     INTEGER, POINTER                       :: NonZeroIndex2(:)                 !<Index 2 into non-zero elements
     INTEGER, POINTER                       :: NonZeroIndex3(:)                 !<Index 3 into non-zero elements
     INTEGER, POINTER                       :: Index3(:)
     INTEGER                                :: p,q,l                            !<Dimension of the original tensor
     INTEGER                                :: nNonZero                         !<Number of non-zero entries
     INTEGER                                :: nIndex3
  END TYPE tSparseTensor3

  TYPE tSparseTensor3b
     TYPE(tSparseMatrix), POINTER           :: SpSubMatrix(:)                   !<Sparse sub matrices
     INTEGER                                :: p,q,l                            !<Dimension of the original tensor
  END TYPE tSparseTensor3b

  TYPE tSparseTensor4
     INTEGER                                :: p,q,l,m                          !<Dimension of the original tensor
     INTEGER                                :: nNonZero                         !<Number of non-zero entries
     INTEGER, POINTER                       :: NonZeroIndex(:,:)                !<Indices into non-zero elements
     REAL, POINTER                          :: NonZero(:)                       !<Values
  END TYPE tSparseTensor4

  !< General pointer to a OneD field
  TYPE tPointerToField
     REAL                         , POINTER :: PTR(:)
  END TYPE tPointerToField

  TYPE tVector
     INTEGER                                :: VecLength
     REAL                         , POINTER :: x(:)
     REAL                         , POINTER :: y(:)
     REAL                         , POINTER :: z(:)
  END TYPE tVector
  !<--------------------------------------------------------------------------
  !<
  !<
  !<--- Description of the unstructured geometry  ----------------------------
  !<
  !< Description of all elements in the domain (the first index runs from 1 to nElem)
  !<
  TYPE tElement
!< unused variables commented!<
!<     INTEGER                      , POINTER :: Type(:)                          !<Element type: 3=triangle, 4=quad
     INTEGER                      , POINTER :: Type3D(:)                        !<3D Element type: 4=Tetrahedron,5=Pyramide,6=Prism,8=Cuboid
     REAL                         , POINTER :: xyBary(:,:)                      !<Coordinates of the barycenters
     REAL                         , POINTER :: Volume(:)                        !<Element volumes (=surfaces in 2D)
!<     REAL                         , POINTER :: UpdateCoeff(:,:)                 !<FluxSign/Volume*Area
     REAL                         , POINTER :: MinDistBarySide(:)               !<Min. distance from barycenter to sides
     INTEGER                      , POINTER :: Vertex(:,:)                      !<Connection index to element's vertices
!<     INTEGER                      , POINTER :: Edge(:,:)                        !< Connection index to element's edges
!<     INTEGER                      , POINTER :: Side(:,:)                        !< Connection index to element's sides
     INTEGER                      , POINTER :: SideNeighbor(:,:)                !<Connection index to element's side neighbor elements
     INTEGER                      , POINTER :: ncNeighbor(:,:)                  !<Non-conforming side neighbor for each Quadrature Point
     INTEGER                      , POINTER :: ncBndNeighbor(:,:)               !<Non-conforming side neighbor for each Quadrature Point
     INTEGER                      , POINTER :: NCB_IndexList(:,:)               !<searches iElem for iNCboundary
     INTEGER                      , POINTER :: ncBndNeighborSide(:,:)           !<Non-conforming neighbor side for each Quadrature Point
     REAL                         , POINTER :: ncGaussP(:,:,:)                  !<Non-conforming Quadrature Point Coordinates
     REAL                         , POINTER :: ncBndGaussP(:,:,:)               !<Non-conforming Quadrature Point Coordinates
     REAL                         , POINTER :: GP_Tri(:,:)                      !<GaussPoints in Tetrahedron (Reference element)
     REAL                         , POINTER :: GW_Tri(:)                        !<Non-conforming Quadrature Weights
     REAL                         , POINTER :: GP_Quad(:,:)                      !<GaussPoints in Hexahedral (Reference element)
     REAL                         , POINTER :: GW_Quad(:)                        !<Non-conforming Quadrature Weights
!<     REAL                         , POINTER :: BndGP_Tri(:,:,:)                 !< GaussPoints in boundary of Tetrahedron (Reference element)
!<     REAL                         , POINTER :: BndGP_Quad(:,:,:)                 !< GaussPoints in boundary of Hexahedron (Reference element)
     REAL                         , POINTER :: BF_GP_Tri(:,:)                   !<Value of basis function at GaussPoints of Quadrilateral (Reference element)
     REAL                         , POINTER :: BF_GP_Quad(:,:)                   !<Value of basis function at GaussPoints of Quadrilateral (Reference element)
     REAL                         , POINTER :: BF_Grad_GP_Tri(:,:,:)            !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: BF_Grad_GP_Quad(:,:,:)           !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: GP_Quad_Nod(:,:)                 !<GaussPoints in Quadrilateral (Reference element) for nodal basis
     REAL                         , POINTER :: GW_Quad_Nod(:)                   !<Non-conforming Quadrature Weights for nodal basis
     REAL                         , POINTER :: BndGP_Quad(:,:)                  !<GaussPoints in 2D boundary
     REAL                         , POINTER :: BndGP_Tri(:,:)                   !<GaussPoints in 2D boundary
!<     REAL                         , POINTER :: BndGP(:,:)  ´                    !< GaussPoints in 1D boundary
     REAL                         , POINTER :: BndGW_Tri(:)                     !<GaussWeights in 2D boundary
     REAL                         , POINTER :: BndGW_Quad(:)                    !<GaussWeights in 2D boundary
     REAL                         , POINTER :: BndGP_Nod(:,:)                   !<GaussPoints in 1D boundary for nodal basis
     REAL                         , POINTER :: BndGW_Nod(:)                     !<GaussWeights in 1D boundary for nodal basis
     REAL                         , POINTER :: BndBF_GP_Tri(:,:,:)              !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: BndBF_GP_Quad(:,:,:)             !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: GP_Tet(:,:)                      !<GaussPoints in Tetrahedron (Reference element)
     REAL                         , POINTER :: GW_Tet(:)                        !<Non-conforming Quadrature Weights
     REAL                         , POINTER :: GP_Hex(:,:)                      !<GaussPoints in Hexahedral (Reference element)
     REAL                         , POINTER :: GW_Hex(:)                        !<Non-conforming Quadrature Weights
     REAL                         , POINTER :: BndGP_Tet(:,:,:)                 !<GaussPoints in boundary of Tetrahedron (Reference element)
     REAL                         , POINTER :: BndGP_Hex(:,:,:)                 !<GaussPoints in boundary of Hexahedron (Reference element)
     REAL                         , POINTER :: BF_GP_Tet(:,:)                   !<Value of basis function at GaussPoints of Quadrilateral (Reference element)
     REAL                         , POINTER :: BF_GP_Hex(:,:)                   !<Value of basis function at GaussPoints of Quadrilateral (Reference element)
     REAL                         , POINTER :: BF_Grad_GP_Tet(:,:,:)            !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: BF_Grad_GP_Hex(:,:,:)            !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: BndBF_GP_Tet(:,:,:)              !<GaussPoints in boundary of Quadrilateral (Reference element)
     REAL                         , POINTER :: BndBF_GP_Hex(:,:,:)              !<GaussPoints in boundary of Quadrilateral (Reference element)
     INTEGER                      , POINTER :: ncIndex(:,:)                     !<Index of non-conforming elements
!     REAL                         , POINTER :: ncVrtx(:,:,:)                    !<Vertices of mirrored element
!<     INTEGER                      , POINTER :: nSide(:)                         !< Number of Sides per Element
!<     INTEGER                      , POINTER :: nEdge(:)                         !< Number of Edges per Element
     INTEGER                      , POINTER :: LocalNeighborSide(:,:)           !<Which are the local sides of the neighbor connected to the local sides of the element ?
     INTEGER                      , POINTER :: LocalNeighborVrtx(:,:)           !<Local neighbor side vertex number at local side vertex 1 for each element and each side
!<     INTEGER                      , POINTER :: VertexNeighbor(:,:)              !< Connection index to element's vertex neighbors
!<     INTEGER                      , POINTER :: NrOfVertexNeighbors(:)           !< Number of vertex neighbors for all elements
!<     INTEGER                      , POINTER :: FluxSign(:,:)                    !< Obsolete, sign contained in UpdateCoeff
!<     INTEGER                      , POINTER :: InnerToGlobal(:)                 !< Mapping from inner index to global index
!<     INTEGER                      , POINTER :: BoundaryToGlobal(:)              !< Mapping from boundary index to global index
     INTEGER                      , POINTER :: Reference(:,:)                   !<Reference code for boundary conditions (GlobalElemtype,iElem)
     INTEGER                      , POINTER :: MPIReference(:,:)                !<MPI Reference array (MESH%nVertexMax,MESH%nElem)
     INTEGER                      , POINTER :: MPINumber(:,:)                   !<Index into MPI communication structure
     INTEGER                      , POINTER :: MPI_NCNumber(:,:)                !<Index into MPI communication structure for non-conforming elements
     INTEGER                      , POINTER :: BoundaryToObject(:,:)            !<Mapping from element and side index to boundary object nr
     INTEGER                      , POINTER :: NC_BoundaryToObject(:,:)         !<Mapping from element, side and Gausspoint index to boundary object nr
     INTEGER                      , POINTER :: MPINumber_DR(:,:)                  !<Index into MPI communication structure for dynamic rupture
     END TYPE tElement

  !< Dynamic rupture mesh-based information on the fault
  TYPE tFault
     INTEGER                                :: nElem                            !<Num. of elements with a fault side
     INTEGER                                :: nSide                            !<Num. of fault sides
     INTEGER, POINTER                       :: Face(:,:,:)                      !<Assigns each element's side in domain a fault-plane-index
     INTEGER                                :: nPlusSide                        !< Num. of fault sides "+"

     !< Geometry
     REAL, POINTER                          :: geoNormals(:,:)                  !< Side normal vectors
     REAL, POINTER                          :: geoTangent1(:,:)                 !< Vector 1 in the side plane
     REAL, POINTER                          :: geoTangent2(:,:)                 !< Vector 2 in the side plane

     real*8, allocatable, dimension( :, :, : )    :: forwardRotation  !< forward rotation matrix from xyz- to face-normal-space
     real*8, allocatable, dimension( :, :, : )    :: backwardRotation !< backward rotation matrix from face-normal-space to x-y-z space

     real*8, allocatable, dimension( :, :, :, : ) :: fluxSolver !< jacobian of the plus(1)/minus(2) side multiplid by the back rotation matrix from face-normal-space to xyz-space and the determinant of jacobian of the transformation from x-y-z to xi-eta-zeta space
  END TYPE tFault
  
  !< Description of all the vertices in the domain (the first index runs from 1 to MESH%nNode)
  TYPE tVertex
     REAL                         , POINTER :: xyNode(:,:)                      !<Coordinates of the nodes
     REAL                         , POINTER :: temp_xyzNode(:,:)                !<temporary storage of nodes
     REAL                         , POINTER :: mdca(:)                          !<median dual cell area around a node (RD-Schemes)
     REAL                         , POINTER :: inwNormals(:,:,:,:)              !<side scaled inward normal of the opposite side of a node
     INTEGER                      , POINTER :: Element(:,:)                     !<Connection index to elements containing a node
     INTEGER                      , POINTER :: NrOfEdgesConnected(:)            !<Number of edges connected to each node
     INTEGER                      , POINTER :: AddressOfEdgesConnected(:)       !<Address of first connected edge index in AddressOfElementsConnected
     INTEGER                      , POINTER :: IndexOfEdgesConnected(:)         !<List runs from 1 to AddressOfEdgesConnected(MESH%nElementsToNodes)
     INTEGER                      , POINTER :: NrOfSidesConnected(:)            !<Number of sides on each node
     INTEGER                      , POINTER :: AddressOfSidesConnected(:)       !<Address of first connected side index in AddressOfElementsConnected
     INTEGER                      , POINTER :: IndexOfSidesConnected(:)         !<List runs from 1 to AddressOfSidesConnected(MESH%nElementsToNodes)
     INTEGER                      , POINTER :: NrOfElementsConnected(:)         !<Number of elements on each node
     INTEGER                      , POINTER :: AddressOfElementsConnected(:)    !<Address of first connected element index in AddressOfElementsConnected
     INTEGER                      , POINTER :: IndexOfElementsConnected(:)      !<List runs from 1 to AddressOfElementsConnected(MESH%nElementsToNodes)
     INTEGER                      , POINTER :: Reference(:)                     !<Reference code for boundary conditions
     INTEGER                      , POINTER :: BoundaryToObject(:)              !<Mapping from boundary side index to boundary object nr
     LOGICAL                                :: severalPoints(8)                 !<TRUE for more than one nearest Point
   END TYPE tVertex

  !< Description of all the sides in the domain (the first index runs from 1 to MESH%nSide !<NOT for BoundaryToObjec(nBoundSides))
  TYPE tSide
     REAL                         , POINTER :: xyMidSide(:,:)                   !<Coordinates of the side's midpoint
     REAL                         , POINTER :: Area(:)                          !<Area of the side (length in 2D)
     REAL                         , POINTER :: NormVec(:,:)                     !<Normal vector coordinates
     REAL                         , POINTER :: BaryVec(:,:,:)                   !<Vector from side midpoint to cell barycenter
     REAL                         , POINTER :: MinDistBaryEdge(:)               !<Min. distance from side barycenter to edge (inner circle radius)
     REAL                         , POINTER :: cosTheta(:)                      !<cosinus of Eularian nutation angel
     REAL                         , POINTER :: sinTheta(:)                      !<sinus of Eularian nutation angel
     REAL                         , POINTER :: cosPsi(:)                        !<cosinus of Eularian precession angel
     REAL                         , POINTER :: sinPsi(:)                        !<sinus of Eularian precession angel
     REAL                         , POINTER :: cosPhi(:)                        !<cosinus of Eularian rotation angel
     REAL                         , POINTER :: sinPhi(:)                        !<sinus of Eularian rotation angel
     REAL                         , POINTER :: FluxSignElement(:,:)             !<FluxSign to Element 1 or 2
     REAL                         , POINTER :: PosOfGaussPointNbr(:,:,:)        !<x,y,z Positions of the Gausspoints for each Side(SideNbr,GaussPointNbr,1:3)
     REAL                         , POINTER :: GhostCellxyBary(:,:)             !<BaryCenter position of GhostCell connected to corresponding BoundarysideNbr (1:nBoundSides,3)
     INTEGER                      , POINTER :: Element(:,:)                     !<Connection index to side's neighbor elements
     INTEGER                      , POINTER :: Vertex(:,:)                      !<Connection index to side's vertices
     INTEGER                      , POINTER :: Edge(:,:)                        !<Connection index to side edges (only available in 3D)
     INTEGER                      , POINTER :: InnerToGlobal(:)                 !<Mapping from inner side index to global side index
     INTEGER                      , POINTER :: LocalToGlobalNode(:,:)           !<Mapping from local node index to global node index
     INTEGER                      , POINTER :: LocalToGlobalEdge(:,:)           !<Mapping from local edge index to global edge index
     INTEGER                      , POINTER :: GlobalToBoundary(:)              !<Mapping from global side index to boundary side index
     INTEGER                      , POINTER :: BoundaryToGlobal(:)              !<Mapping from boundary side index to global side index
     INTEGER                      , POINTER :: BoundaryToGlobalElement(:)       !<Mapping from boundary side index to global element idx.
     INTEGER                      , POINTER :: BoundaryToObjectSide(:)          !<Mapping from boundary side index to boundary object nr
     INTEGER                      , POINTER :: Reference(:)                     !<Reference code for boundary conditions
     INTEGER                      , POINTER :: nNode(:)                         !<Number of Nodes for this Side
     LOGICAL                      , POINTER :: InnerSide(:)                     !<InnerSide = TRUE, Boundary = FALSE
     TYPE(tVector)                          :: NormVec3D                        !<Normal vector coordinates in 3D
     TYPE(tVector)                          :: TangVec3D                        !<Tangetial vector coordinates (from Midpoint to local 1.st Vertex)
     TYPE(tVector)                          :: BinoVec3D                        !<Binormal vector coordinates (cross product of NormVec, TangVec)
  END TYPE tSide

  !< Description of all the edges in the domain
  TYPE tEdge
     INTEGER                      , POINTER :: Vertex(:,:)                      !<Connection index to edge nodes
     REAL                         , POINTER :: xyzMidEdge(:,:)                  !<Coordinates of the edge midpoint
     REAL                         , POINTER :: Length(:)                        !<Length of the edge
  END TYPE tEdge

  !< Data type containing the information about the unstructured mesh (variable name : MESH)
  TYPE tUnstructMesh
     INTEGER                      , POINTER :: TetElemType(:)                   !<Type of element (elements with same transf. to ref. element are of same type)
     INTEGER                      , POINTER :: NeighbourType(:,:)               !<Type of element of neighbour of a given element type
     INTEGER                      , POINTER :: TetElemEx(:)                     !<Which element is an example of a given element type
     INTEGER                                :: GlobalElemType                   !<Triangle=3, quads=4, tets = 4, hex = 6, mixed = 7
     INTEGER                                :: nVertexMax                       !<Triangle=3, quads=4, tets = 4, hex = 8 , mixed = 4,8
     INTEGER                                :: nSideMax                         !<Tets = 4, Hexas = 6
     INTEGER, ALLOCATABLE                   :: LocalElemType(:)                 !<Triangle=3, quads=4, tets = 4, hex = 6
     INTEGER, ALLOCATABLE                   :: LocalVrtxType(:)                 !<Tet: 4, Hex: 8
     INTEGER, ALLOCATABLE                   :: LocalElemIndex_Tri(:)            !<Relates every element in the total mesh to a local element
     INTEGER, ALLOCATABLE                   :: LocalElemIndex_Quad(:)           !<Relates every element in the total mesh to a local element
     INTEGER, ALLOCATABLE                   :: LocalElemIndex_Tet(:)
     INTEGER, ALLOCATABLE                   :: LocalElemIndex_Hex(:)
     INTEGER                                :: GlobalVrtxType                   !<Triangle=3, quads=4, tets = 4, hex = 8
     INTEGER                                :: GlobalSideType                   !<Triangle=2, quads=2, tets = 3, hex = 4
     INTEGER                                :: Dimension                        !<Dimension of mesh (redundant with EQN%Dimension)
     INTEGER                                :: nElem                            !<Total number of elements in the domain
     INTEGER                                :: nSides_Tet = 4                   !<Number of sides of tetrahedron
     INTEGER                                :: nSides_Hex = 6                   !<Number of sides of hexahedron
     INTEGER                                :: nVertices_Tri = 3                !<Number of vertices of triangle
     INTEGER                                :: nVertices_Quad = 4               !<Number of vertices of quadrilateral
     INTEGER                                :: nVertices_Tet = 4                !<Number of vertices of tetrahedron
     INTEGER                                :: nVertices_Hex = 8                !<Number of vertices of hexahedron
     INTEGER                                :: nElem_Tet                        !<Total number of tets in the domain
     INTEGER                                :: nElem_Hex                        !<Total number of hexas in the domain
     INTEGER                                :: nSide                            !<Total number of sides in the domain
     INTEGER                                :: nEdge                            !<Total number of edges in the domain
     INTEGER                                :: nNode                            !<Total number of nodes (vertices) in the domain
     INTEGER                                :: nGroup                           !<Number of groups
     INTEGER                                :: nZones                           !<Number of material zones
     INTEGER                                :: nZonesTotal                      !<Number of blocks in ICEM .neu files
     INTEGER                                :: nIcemElem                        !<Total number of ICEM elements, i.e. tetrahedra + boundary triangles
     INTEGER                                :: nTriElem                         !<For non-pure grids: number of triangles
     INTEGER                                :: nQuadElem                        !<For non-pure grids: number of quads
     INTEGER                                :: nInnerElem                       !<Number of inner elements
     INTEGER                                :: nInnerSide                       !<Number of inner sides
     INTEGER                                :: nBndrElem                        !<Number of boundary elements
     INTEGER                                :: nEdgesToNodes                    !<Sum of all connected Edges for all Nodes
     INTEGER                                :: nSidesToNodes                    !<Sum of all connected Sides for all Nodes
     INTEGER                                :: nElementsToNodes                 !<Sum of all connected Elements for all Nodes
     INTEGER                                :: nNonConformingEdges              !<Number of non-conforming elements
     INTEGER                                :: MaxElementsOnVertex              !<Maximum of elements connected to a single vertex
     INTEGER                                :: MinElementsOnVertex              !<Minimum of elements connected to a single vertex
     LOGICAL                                :: ADERDG3D                         !<Use ADERDG 3D discretization ?
     LOGICAL                                :: IniSquareMesh                    !<Is mesh an internally generated square-mesh? (T/F)
     LOGICAL                                :: IniDiscMesh                      !<Is mesh an internally generated disc-mesh?   (T/F)
     LOGICAL                                :: IniUnstructCubus3D               !<Is mesh an internally generated 3D unstructured cubical-mesh?   (T/F)
     LOGICAL                                :: Changed                          !<Is mesh changed?
     LOGICAL, POINTER                       :: IncludesFSRP(:)                  !<Includes a subfault of a Finite Source Rupture Plane?
     TYPE(tVertex)                          :: VRTX                             !<Vertex data structure
     TYPE(tEdge)                            :: EDGE                             !<Edge data structure
     TYPE(tSide)                            :: SIDE                             !<Side data structure
     TYPE(tElement)                         :: ELEM                             !<Element data structure
     TYPE(tFault)                           :: Fault                            !<Fault geometry mesh data structure
     REAL                                   :: min_h, max_h                     !<Min. and max. incircle
     REAL                                   :: MaxSQRTVolume                    !<Maximum of SQRT(volume) of the domain
     REAL                                   :: MaxCircle                        !<Maximum distance between barycenter and nodes in the domain
     REAL                                   :: MESHversionID                    !<Version ID Number of MESH input part in parameterfile Version .ge.25
     REAL, POINTER                          :: Displacement(:)                  !<Initial displacement of the grid
     REAL, POINTER                          :: ScalingMatrix(:,:)               !<Scaling matrix of all vertex coordinates (for unit conversion and rotation)
     INTEGER                                :: nOutBnd                          !<Number of elements with 105 boundaries
     ! For gambit3dtetra_geizig
     INTEGER, POINTER          :: NodeLocal2Global(:)
     INTEGER, POINTER          :: NodeGlobal2Local(:)
     INTEGER, POINTER          :: ElemLocal2Global(:)
     INTEGER, POINTER          :: ElemGlobal2Local(:)
#ifdef HDF
     INTEGER                   :: nodeOffset                               !Offset from which they hyperslab for a particular process starts for the nodes.
     INTEGER                   :: elemOffset                               !Offset from which they hyperslab for a particular process starts for the elements.
     INTEGER                   :: nNode_total                                   !Total number of nodes in the mesh. This is also used in hdf5 to allocate the file for writing
     INTEGER                   :: nElem_total                                   !Total number of nodes in the mesh. This is also used in hdf5 to allocate the file for writing
#endif
  END TYPE tUnstructMesh

  TYPE tDGSponge
    INTEGER                                :: SpongeObject                        !<Object of sponge BND
    INTEGER                                :: SpongeBND                           !<Inflow (4) or outflow (5) sponge
    INTEGER                                :: SpongePower                         !<Power of sponge layer
    INTEGER                                :: nSpongeElements                     !<Number of elements affected by the sponge layer
    REAL                                   :: SpongeDelta                         !<Sponge thickness
    REAL                                   :: SigmaMax                            !<Max. sigma of sponge layer
    INTEGER, POINTER                       :: SpongeElements(:)                   !<List of elements inside the sponge layer
    REAL, POINTER                          :: SpongeDistances(:,:)                !<Distances for all elements and GPs in sponge
  END TYPE tDGSponge

 Type tPMLayer
    INTEGER                                :: nPMLElements                        !<number of PMLElements
    INTEGER, POINTER                       :: PMLElements(:)                      !<lists element number (referred to mesh) for PML element
    INTEGER, POINTER                       :: PMLList(:)                          !<-1 within interior, number of PMLElem within layer
    INTEGER, POINTER                       :: PMLIndexList(:)                     !<List of element numbers that are inside PML
    INTEGER, ALLOCATABLE                   :: PMLFacetList(:,:,:)                 !<Nearest facet (iElem,x and y,1:2) => (Element,Side)
    REAL                                   :: PMLDelta                            !<PML thicknesses
    REAL                                   :: PMLPrefactor                        !<Prefactor for damping term
    REAL                                   :: Refl_Coeff                          !<Reflection Coefficient
    REAL                                   :: PMLFrequency                        !<Frequency  for alpha
    REAL                                   :: Ekin                                !<Energy of wavefield
    REAL, POINTER                          :: PMLDamping(:,:)                     !<Damping term for PML
    REAL, POINTER                          :: PML_Beta(:,:)                       !<Parameter Beta inside PML
    REAL, POINTER                          :: PML_a(:,:)
    REAL, POINTER                          :: PML_b(:,:)
    REAL, POINTER                          :: PML_Psi(:,:)
    REAL                                   :: strain(2,2)
    Integer                                :: PMLstop
 END TYPE tPMLayer

  TYPE tGalerkin
    INTEGER           :: DGMethod                    !<0 = RKDG with quadrature
                                                     !<1 = quadrature free RKDG
                                                     !<2 = ADER DG
                                                     !<3 = rec ADER DG
                                                     !< 4 = rec RK DG
                                                     !< 5 = Nonlinear ADER DG
                                                     !< 6 = local RK-DG, ADD eqn.
    integer           :: clusteredLts                !< 0 = file, 1 = GTS, 2-n: multi-rate
    INTEGER           :: CKMethod                    !< 0 = regular CK
                                                     !< 1 = local space-time DG
                                                     !<
    INTEGER           :: FluxMethod                  !< 0 = Godunov
                                                     !< 1 = Rusanov
    !< Important numbers
    INTEGER           :: nMinPoly                    !< Min. deg. of basis poly.
    INTEGER           :: nMaxPoly                    !< Max. deg. of basis poly.
    INTEGER           :: nPoly                       !< Degree of the polynomials
    INTEGER           :: nPolyRec                    !< Degree of rec. polynomials
    INTEGER           :: nPolyMatOrig                !< Degree of A,B,C polynomial
    INTEGER           :: nPolyMap                    !< Degree of mapping
    INTEGER           :: nPolyMat                    !< Degree of A*,B*,C* poly.
    INTEGER           :: nDegFrMat                   !< # DOF of A*,B*,C* poly.
    INTEGER           :: nDegFr                      !< Nr of degrees of freedom
    INTEGER           :: nDegFr_Nod                  !< Nr of degrees of freedom for nodal basis
    INTEGER           :: nDegFrRec                   !< # DOF of reconst. poly.
    INTEGER           :: nDegFrST                    !< # DOF of local s-t DG
    INTEGER           :: nRK                         !< Nr of temp RK variables
    INTEGER           :: nIntGP                      !< Nr of internal Gausspoints
    INTEGER           :: nIntGP_Nod                  !< Nr of internal Gausspoints for nodal basis
    INTEGER           :: nRecIntGP                   !< Nr of internal Gausspoints
    INTEGER           :: nBndGP                      !< Nr of boundary Gausspoints
    INTEGER           :: nBndGP_Nod                  !< Nr of boundary Gausspoints for nodal basis
    INTEGER           :: nTimeGP                     !< Nr of time Gausspoints
    LOGICAL           :: init = .FALSE.              !< Initialization status
    LOGICAL           :: linearLW                    !< Use linear LW procedure ?
    !< DG main array which stores the degrees of freedom
#ifdef GENERATEDKERNELS
    ! Interoperability with C needs continuous arrays in memory.
    !   Reference: Intel® Fortran Compiler XE 13.0 User and Reference Guides
    !              "Because its elements do not need to be contiguous in memory, a Fortran pointer target or assumed-shape array cannot be passed to C.
    !               However, you can pass an allocated allocatable array to C, and you can associate an array allocated in C with a Fortran pointer."
    real*8, allocatable   :: dgvar(:,:,:,:)            !< storage of all unknowns (solution).
#else
    REAL, POINTER         :: dgvar(:,:,:,:)              !< Data-array for expansion
#endif
! never used    REAL, POINTER     :: dgvar_ane(:,:,:,:)          !< Data-array for expansion (Anel.)
    REAL, POINTER         :: DOFStress(:,:,:)      !< DOF's for the initial stress loading for the plastic calculations
    REAL, POINTER         :: pstrain(:,:)          !< plastic strain
#ifdef GENERATEDKERNELS
!    integer              :: nSourceTermElems !< number of elemens having a source term
!    real*8, allocatable  :: dgsourceterms(:,:,:)            !< storage of source terms
!    integer, allocatable :: indicesOfSourceTermsElems(:) !< indices of elements having a source term
#else
    REAL, POINTER     :: DGwork(:,:,:)               !< Work array for DG method
#endif
    REAL, POINTER     :: DGTaylor(:,:,:,:)           !< Work array for local dt DG
! never used    REAL, POINTER     :: AneWork(:,:,:,:)            !< As above, but for ane. variables
    real              :: totcputime
    REAL, POINTER     :: OutFlow(:,:,:,:)            !< Outflowing flux for backpropagation
    !< Geometry
    REAL, POINTER     :: geoNormals(:,:,:)           !< Side normal vectors
    REAL, POINTER     :: geoTangent1(:,:,:)          !< Vector 1 in the side plane
    REAL, POINTER     :: geoTangent2(:,:,:)          !< Vector 2 in the side plane
    REAL, POINTER     :: geoSurfaces(:,:)            !< Cell side lengths in 2D
    !< Other variables related to the DG - Method
    REAL, ALLOCATABLE :: cPoly(:,:,:,:)              !< Coeff. of base polynomials
    REAL, ALLOCATABLE :: cPoly_Tri(:,:,:,:)          !< Coeff. of base polynomials
    REAL, ALLOCATABLE :: cPoly_Quad(:,:,:,:)         !< Coeff. of base polynomials
    REAL, POINTER     :: cPoly3D(:,:,:,:,:)          !< Coeff. of base polynomials
    REAL, POINTER     :: cPoly3D_Tet(:,:,:,:,:)      !< Coeff. of base polynomials
    REAL, POINTER     :: cPoly3D_Hex(:,:,:,:,:)      !< Coeff. of base polynomials
    REAL, POINTER     :: cPolyRec(:,:,:,:)           !< Coeff. of rec. polynomials
    REAL, POINTER     :: KMatrix(:,:)                !< Precalculated i. integrals
    REAL, POINTER     :: F1Matrix(:,:)               !< Precalculated b. integrals
    REAL, POINTER     :: F2Matrix(:,:)               !< Precalculated b. integrals
    REAL, POINTER     :: F3Matrix(:,:)               !< Precalculated b. integrals
    REAL, POINTER     :: F4Matrix(:,:)               !< Precalculated b. integrals
    REAL, POINTER     :: InvA(:,:)
    REAL, POINTER     :: A(:,:)                      !< Jacobian in x-dir
    REAL, POINTER     :: B(:,:)                      !< Jacobian in y-dir
    REAL, POINTER     :: RKalpha(:)                  !< Alpha values for RK (y)
    REAL, POINTER     :: RKbeta(:)                   !< Beta values for RK (t)
    REAL, POINTER     :: TimeGaussP(:)               !< Gausspoints in time
    REAL, POINTER     :: TimeGaussW(:)               !< Gaussweights in time
    REAL, POINTER     :: intGaussP(:,:)              !< Internal GP coordinates
    REAL, POINTER     :: intGaussW(:)                !< Internal Gaussweights
    REAL, POINTER     :: intGaussP_Tet(:,:)          !< Internal GP coordinates
    REAL, POINTER     :: intGaussW_Tet(:)            !< Internal Gaussweights
    REAL, POINTER     :: intGaussP_Hex(:,:)          !< Internal GP coordinates
    REAL, POINTER     :: intGaussW_Hex(:)            !< Internal Gaussweights
    REAL, POINTER     :: RecIntGaussP(:,:)           !< Internal GP coordinates
    REAL, POINTER     :: RecIntGaussW(:)             !< Internal Gaussweights
    REAL, POINTER     :: bndGaussP(:,:,:)            !< Boundary GP (ref. xi/eta)
    REAL, POINTER     :: bndGaussP3D(:,:)            !< Boundary GP (ref. xi/eta)
    REAL, POINTER     :: bndGaussP_Tet(:,:)          !< Boundary GP (ref. xi/eta)
    REAL, POINTER     :: bndGaussP_Hex(:,:)          !< Boundary GP (ref. xi/eta)
    REAL, POINTER     :: bndGaussW(:)                !< Gaussweights on boundary
    REAL, POINTER     :: bndGaussW_Tet(:)            !< Gaussweights on boundary
    REAL, POINTER     :: bndGaussW_Hex(:)            !< Gaussweights on boundary
    REAL, POINTER     :: FR_GP(:,:)                  !< Neighbor flux of GP of nc edge
    !<
    REAL, ALLOCATABLE :: MassMatrix(:,:,:)           !< Mass Matrix
    REAL, ALLOCATABLE :: iMassMatrix(:,:,:)          !< Inverse Mass Matrix
    REAL, POINTER     :: MassMatrix_Tet(:,:,:)       !< Mass Matrix
    REAL, POINTER     :: iMassMatrix_Tet(:,:,:)      !< Inverse Mass Matrix
    REAL, POINTER     :: MassMatrix_Hex(:,:,:)       !< Mass Matrix
    REAL, POINTER     :: iMassMatrix_Hex(:,:,:)      !< Inverse Mass Matrix
    REAL, POINTER     :: MassMatrix_Tri(:,:,:)       !< Mass Matrix
    REAL, POINTER     :: iMassMatrix_Tri(:,:,:)      !< Inverse Mass Matrix
    REAL, POINTER     :: MassMatrix_Quad(:,:,:)      !< Mass Matrix
    REAL, POINTER     :: iMassMatrix_Quad(:,:,:)     !< Inverse Mass Matrix
    REAL, POINTER     :: FMatrix(:,:,:,:)            !< Flux matrices (Quadfree)
    REAL, POINTER     :: FMatrix_Tri(:,:,:,:)        !< Flux matrices (Quadfree)
    REAL, POINTER     :: FMatrix3D(:,:,:,:,:)        !< Flux matrices (Quadfree)
    REAL, POINTER     :: FMatrix3D_Tet(:,:,:,:,:,:)  !< Flux matrices (Quadfree)
    REAL, POINTER     :: FMatrix3D_Hex(:,:,:,:,:,:)  !< Flux matrices (Quadfree)
    REAL, POINTER     :: Kxi(:,:)                    !< Stiffness Matrix (xi)
    REAL, POINTER     :: Keta(:,:)                   !< Stiffness Matrix (eta)
    REAL, POINTER     :: Kzeta(:,:)                  !< Stiffness Matrix (zeta)
    REAL, POINTER     :: Coeff_level0(:,:,:,:)       !< ADER DG Coefficients
    REAL, POINTER     :: Coeff_level03D(:,:,:,:,:)   !< ADER DG Coefficients
    REAL, POINTER     :: Coeff_level03D_Tet(:,:,:,:,:)   !< ADER DG Coefficients
    REAL, POINTER     :: Coeff_level03D_Hex(:,:,:,:,:)   !< ADER DG Coefficients
    TYPE(tSparseVector), POINTER :: Sp_Coeff_level03D(:,:,:,:) !< ADER DG Coefficients
    TYPE(tSparseVector), POINTER :: Sp_Coeff_level02D(:,:,:)
    TYPE(tSparseVector), POINTER :: Sp_Coeff_level03D_Tet(:,:,:,:) !< ADER DG Coefficients
    TYPE(tSparseVector), POINTER :: Sp_Coeff_level03D_Hex(:,:,:,:) !< ADER DG Coefficients
    INTEGER           :: NonZeroCoeff                !< Number of non-zero coeffs
    INTEGER, POINTER  :: NonZeroCoeffIndex(:,:)      !< Index into "
    INTEGER           :: NonZeroCoeff_Tet            !< Number of non-zero coeffs
    INTEGER, POINTER  :: NonZeroCoeffIndex_Tet(:,:)  !< Index into "
    INTEGER           :: NonZeroCoeff_Hex            !< Number of non-zero coeffs
    INTEGER, POINTER  :: NonZeroCoeffIndex_Hex(:,:)  !< Index into "
    INTEGER, POINTER  :: NonZeroCPoly(:,:)       !< Non zero coeff in cpoly
    INTEGER, POINTER  :: NonZeroCPoly_Tet(:,:)   !< Non zero coeff in cpoly
    INTEGER, POINTER  :: NonZeroCPoly_Hex(:,:)   !< Non zero coeff in cpoly
    INTEGER, POINTER  :: NonZeroCPolyIndex(:,:,:,:)
    INTEGER, POINTER  :: NonZeroCPolyIndex_Tet(:,:,:,:)
    INTEGER, POINTER  :: NonZeroCPolyIndex_Hex(:,:,:,:)      !<
    INTEGER, ALLOCATABLE  :: NonZeroCPoly_Tri(:,:)           !< Non zero coeff in cpoly
    INTEGER, ALLOCATABLE  :: NonZeroCPolyIndex_Tri(:,:,:,:)  !<
    INTEGER, ALLOCATABLE  :: NonZeroCPoly_Quad(:,:)          !< Non zero coeff in cpoly
    INTEGER, ALLOCATABLE  :: NonZeroCPolyIndex_Quad(:,:,:,:) !<

    !<
    REAL              :: intGaussWSum                !< Sum of int. Gaussweights
    REAL              :: bndGaussWSum                !< Sum of ext. Gaussweights
    REAL              :: refFactor                   !< Factor for ref. element
    REAL              :: CFL                         !< CFL number
    !<
    REAL, POINTER     :: BasisToTaylor(:,:)          !< Basis to Taylor series
    REAL, POINTER     :: invBasisToTaylor(:,:)       !< Taylor series to basis
    REAL, POINTER     :: Faculty(:)                  !< Precalculated Faculties...
    REAL, POINTER     :: dtPowerFactor(:,:)          !< dt^k/k!< for Taylor series
    REAL, POINTER     :: dtPowerFactorInt(:,:)       !< dt^(k+1)/(k+1)!< for Taylor series
    REAL, POINTER     :: IntGPBaseFunc(:,:,:)        !< Precalc. basis functions
    REAL, POINTER     :: IntGPBaseGrad(:,:,:,:)      !< Precalc. basis gradients
    REAL, POINTER     :: BndGPBaseFunc(:,:,:,:)      !< Precalc. basis functions
    REAL, POINTER     :: BndGPBaseFunc3D(:,:,:)      !< Precalc. basis functions
    REAL, POINTER     :: IntGPBaseFunc_Tet(:,:,:)        !< Precalc. basis functions
    REAL, POINTER     :: IntGPBaseGrad_Tet(:,:,:,:)      !< Precalc. basis gradients
    REAL, POINTER     :: BndGPBaseFunc_Tet(:,:,:,:)      !< Precalc. basis functions
    REAL, POINTER     :: BndGPBaseFunc3D_Tet(:,:,:)      !< Precalc. basis functions
    REAL, POINTER     :: IntGPBaseFunc_Hex(:,:,:)        !< Precalc. basis functions
    REAL, POINTER     :: IntGPBaseGrad_Hex(:,:,:,:)      !< Precalc. basis gradients
    REAL, POINTER     :: BndGPBaseFunc_Hex(:,:,:,:)      !< Precalc. basis functions
    REAL, POINTER     :: BndGPBaseFunc3D_Hex(:,:,:)      !< Precalc. basis functions
    REAL, POINTER     :: RecIntGPBaseFunc(:,:)       !< Precalc. basis functions
    INTEGER, POINTER  :: SectorPoints(:,:)
    REAL, POINTER     :: UnitElementPoints(:,:)
    REAL, POINTER     :: SectorVectors(:,:,:)
    REAL, POINTER     :: Sector_iR(:,:,:)
    !<
    REAL, POINTER     :: IntMonomial(:,:)            !< Factors for integrating 2D 
    !<                                                !< monomials over ref. elem.
    !< Now, all variables for the quadrature-free nonlinear ADER-DG follow:        
    REAL, POINTER     :: LocalBinomialCoeff(:,:)     !< Bico. with higher order    
    REAL, POINTER     :: Kxi_loc( :,:,:)             !< xi stiffness, nl. ADER-DG  
    REAL, POINTER     :: Keta_loc(:,:,:)             !< eta stiffness, nl. ADER-DG  
    REAL, POINTER     :: Flux_loc(:,:,:)             !< flux-matrix, nl. ADER-DG   
    REAL, POINTER     :: CNonZero_Kxi(:)             !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Keta(:)            !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Kzeta(:)           !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Kxi_Tet(:)             !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Keta_Tet(:)            !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Kzeta_Tet(:)           !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Flux(:,:)          !< Sparsity coefficients      
    REAL, POINTER     :: CNonZero_Flux3D(:,:,:,:)    !< Sparsity coefficients      
    INTEGER           :: NonZero_Kxi                 !< No. of nonzero elements    
    INTEGER           :: NonZero_Keta                !< No. of nonzero elements    
    INTEGER           :: NonZero_Kzeta               !< No. of nonzero elements    
    INTEGER           :: NonZero_Kxi_Tet             !< No. of nonzero elements    
    INTEGER           :: NonZero_Keta_Tet            !< No. of nonzero elements    
    INTEGER           :: NonZero_Kzeta_Tet           !< No. of nonzero elements    
    INTEGER, POINTER  :: NonZero_Flux(:)             !< No. of nonzero elements    
    INTEGER, POINTER  :: NonZero_Flux3D(:,:,:)       !< No. of nonzero elements    
    INTEGER, POINTER  :: IndexNonZero_Kxi(:,:)       !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Keta(:,:)      !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Kzeta(:,:)     !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Kxi_Tet(:,:)       !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Keta_Tet(:,:)      !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Kzeta_Tet(:,:)     !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Flux(:,:,:)    !< Sparsity: non-zero indices  
    INTEGER, POINTER  :: IndexNonZero_Flux3D(:,:,:,:,:)!< Sparsity: non-zero indices  

    REAL, POINTER     :: NC_BndBF_GP(:,:,:)          !<Precomputed basis functions at Gauss Point of non-conforming elements
    !< ---------------------------------------------------------------------------
    !< Galerkin fine output
    !< To recover the full quality of the numerical DG solution,
    !< u_h can be written into a file for more than one point per element.         !
    INTEGER           :: DGFineOut1D                 !< Number of 1D Gausspoints
    INTEGER           :: DGFineOut2D                 !< Number of 2D Gausspoints
    REAL, POINTER     :: DGFineOutPoints(:,:)        !< locations for fine output
    REAL, POINTER     :: DGFineOutWeights(:)         !< weights (dummy variable)
    REAL, POINTER     :: DGFineOutPhi(:,:)           !< Basis functions at points
    !<
    REAL, POINTER     :: MaxWaveSpeed(:,:)           !< Max. wavespeed over edges
    REAL, POINTER     :: WaveSpeed(:,:,:)            !< All Wavespeeds over edges
    REAL, POINTER     :: cTimePoly(:,:,:)            !< Coefficients and matrices
    REAL, POINTER     :: TimeMassMatrix(:,:,:)       !< for projection on series
    REAL, POINTER     :: iTimeMassMatrix(:,:,:)      !< in time. Basis: Legendre
    REAL, POINTER     :: dPsi_dt(:,:)                !< Time der. of time basefun
    REAL, POINTER     :: mdtr(:)                     !< Aux. factor for CK proc.

    !<
    REAL, POINTER     :: AStar(:,:), BStar(:,:)        !< A and B star matrices
    INTEGER, POINTER  :: IndexNonZeroADERDG2_Kxi(:,:)  !< Sparsity: non-zero indices
    INTEGER           :: nNonZeroADERDG2_Kxi           !< Sparsity: non-zero entries
    INTEGER, POINTER  :: IndexNonZeroADERDG2_Keta(:,:) !< Sparsity: non-zero indices
    INTEGER           :: nNonZeroADERDG2_Keta          !< Sparsity: non-zero entries
    INTEGER, POINTER  :: IndexNonZeroADERDG2_AB(:,:)   !< Sparsity: non-zero indices
    INTEGER           :: nNonZeroADERDG2_AB            !< Sparsity: non-zero entries
    !<
    TYPE(tSparseMatrix), POINTER   :: ASpStar(:)       !< Sparse star matrix A
    TYPE(tSparseMatrix), POINTER   :: BSpStar(:)       !< Sparse star matrix B
    TYPE(tSparseMatrix), POINTER   :: CSpStar(:)       !< Sparse star matrix C
    TYPE(tSparseMatrix), POINTER   :: ESpStar(:)       !< Sparse star matrix E
    TYPE(tSparseMatrix), POINTER   :: ASp(:)           !< Sparse matrix A
    TYPE(tSparseMatrix), POINTER   :: BSp(:)           !< Sparse matrix B
    TYPE(tSparseMatrix), POINTER   :: CSp(:)           !< Sparse matrix C
    TYPE(tSparseMatrix), POINTER   :: A_ane(:)         !< Sparse matrix A  (ane part)
    TYPE(tSparseMatrix), POINTER   :: B_ane(:)         !< Sparse matrix B  (ane part)
    TYPE(tSparseMatrix), POINTER   :: C_ane(:)         !< Sparse matrix C  (ane part)
    TYPE(tSparseMatrix), POINTER   :: ASpPlus(:,:)     !< Sparse + matrix (flux)
    TYPE(tSparseMatrix), POINTER   :: ASpMinus(:,:)    !< Sparse - matrix (flux)
    TYPE(tSparseMatrix), POINTER   :: FMatrix3DSp(:,:,:) !< Sparse 3D Flux matrices
    TYPE(tSparseMatrix), POINTER   :: FMatrix3DSp_Tet(:,:,:) !< Sparse 3D Flux matrices
    TYPE(tSparseMatrix)            :: KxiSp            !< Sparse stiffness matrix
    TYPE(tSparseMatrix)            :: KetaSp           !< Sparse stiffness matrix
    TYPE(tSparseMatrix)            :: KzetaSp          !< Sparse stiffness matrix
    TYPE(tSparseMatrix)            :: KxiSp_Tet        !< Sparse stiffness matrix
    TYPE(tSparseMatrix)            :: KetaSp_Tet       !< Sparse stiffness matrix
    TYPE(tSparseMatrix)            :: KzetaSp_Tet      !< Sparse stiffness matrix
    TYPE(tSparseTensor4), POINTER  :: I_pqlm(:)        !< ADER-DG time int. tensor
    TYPE(tSparseMatrix)            :: ADG_xi
    TYPE(tSparseMatrix)            :: ADG_Eta
    TYPE(tSparseMatrix)            :: ADG_Zeta
    TYPE(tSparseMatrix)            :: ADG_xi_Tet
    TYPE(tSparseMatrix)            :: ADG_Eta_Tet
    TYPE(tSparseMatrix)            :: ADG_Zeta_Tet
    !TYPE(tSparseMatrix)            :: ADGklm_Tet       !< ADER-DG tensor for space dependent reaction term (= identical to identity matrix for constant material per element -> to be optimized!)

    !<
    INTEGER                          :: ADERDG_TimeMult
    INTEGER                          :: ADERDG_KxiMult
    INTEGER                          :: ADERDG_KetaMult
    INTEGER                          :: ADERDG_KzetaMult
    INTEGER                          :: ADERDG_AStarMult
    INTEGER                          :: ADERDG_BStarMult
    INTEGER                          :: ADERDG_CStarMult
    INTEGER                          :: ADERDG_FluxMult
    INTEGER                          :: ADERDG_PlusMult
    INTEGER                          :: ADERDG_MinusMult
    INTEGER                          :: ADERDG_TotalMult
    !<
    LOGICAL           :: TensorInit
    REAL              :: Previous_dt                   !< Previous timestep
    !<
    !< DG sponge layer for general 3D domains
    !<
    INTEGER                           :: nDGSponge     !< Number of sponged boundaries
    REAL                              :: DGSpongeTol   !< Tolerance for search algorithm
    TYPE(tDGSponge), POINTER          :: DGSponge(:)   !< Sponge data structure
    TYPE(tPMLayer)                    :: PMLayer       !< PML data structure
    !< p-adaptivity related variables
    REAL, POINTER                     :: LocPoly(:)      !< Local polynomial degree
    INTEGER                           :: pAdaptivity     !< 0=no, 1=yes
    INTEGER                           :: ZoneOrderFlag   !< Flag for dependence of local polynomial degree on zones
    INTEGER                           :: nPolyLayers     !< Number of zones
    REAL, POINTER                     :: ZonePower(:)    !< Power for p-distribution (linear,degressive,progressive...)
    INTEGER, POINTER                  :: ZoneOrder(:)    !< Local ordering of p-distribution (1=ascending with size, -1 = descending with size)
    INTEGER, POINTER                  :: ZoneMinPoly(:)  !< Local polynomial degree depending on zone
    INTEGER, POINTER                  :: ZoneMaxPoly(:)  !< Local polynomial degree depending on zone
    CHARACTER(LEN=600)                :: OrderFileName   !< Filename for zone orders
    !<
    INTEGER                           :: nMPIRecValues        !< Number of communication elements for reconstruction
    REAL, POINTER                     :: MPIRecValues(:,:,:)  !< Communicated values entering the reconstruction
    !<
    !< Stuff for hexahedrons
    !<
    REAL, POINTER                     :: KxiHexa(:,:,:)     !< Stiffness in xi
    REAL, POINTER                     :: KetaHexa(:,:,:)    !< Stiffness in eta
    REAL, POINTER                     :: KzetaHexa(:,:,:)   !< Stiffness in zeta
    REAL, POINTER                     :: KxiHexa2(:,:,:)    !< Stiffness in xi
    REAL, POINTER                     :: KetaHexa2(:,:,:)   !< Stiffness in eta
    REAL, POINTER                     :: KzetaHexa2(:,:,:)  !< Stiffness in zeta
    TYPE(tSparseTensor3b)             :: KxiHexa_Sp         !< Stiffness in xi (sparse)
    TYPE(tSparseTensor3b)             :: KetaHexa_Sp        !< Stiffness in eta (sparse)
    TYPE(tSparseTensor3b)             :: KzetaHexa_Sp       !< Stiffness in zeta (sparse)
    TYPE(tSparseTensor3b)             :: KxiHexa2_Sp        !< Stiffness in xi (sparse)
    TYPE(tSparseTensor3b)             :: KetaHexa2_Sp       !< Stiffness in eta (sparse)
    TYPE(tSparseTensor3b)             :: KzetaHexa2_Sp      !< Stiffness in zeta (sparse)
    REAL, POINTER                     :: ADGxiHexa(:,:,:)   !< Transpose stiffness / mass in xi
    REAL, POINTER                     :: ADGetaHexa(:,:,:)  !< Transpose stiffness / mass in eta
    REAL, POINTER                     :: ADGzetaHexa(:,:,:) !< Transpose stiffness / mass in zeta
    TYPE(tSparseTensor3b)             :: ADGxiHexa_Sp       !< Transpose stiffness / mass in xi (sparse)
    TYPE(tSparseTensor3b)             :: ADGetaHexa_Sp      !< Transpose stiffness / mass in eta (sparse)
    TYPE(tSparseTensor3b)             :: ADGzetaHexa_Sp     !< Transpose stiffness / mass in zeta (sparse)
    REAL, POINTER                     :: F3DHexa(:,:,:,:,:,:)  !< Flux matrices
    TYPE(tSparseTensor3b), POINTER    :: F3DHexa_Sp(:,:,:)  !< Sparse flux matrices
    TYPE(tSparseTensor3), POINTER     :: ASpHexa(:)         !< Sparse star tensor A
    TYPE(tSparseTensor3), POINTER     :: BSpHexa(:)         !< Sparse star tensor B
    TYPE(tSparseTensor3), POINTER     :: CSpHexa(:)         !< Sparse star tensor C
    TYPE(tSparseTensor3), POINTER     :: ESpHexa(:)         !< Sparse star tensor E
    !<
    INTEGER                           :: VarCoefRiemannSolv = 0  !< Selector for computing Riemann problems with
                                                            !<  discontinuous material or not.


    !<
    !< Gauss-Lobatto-Legendre points associated info
    !<
    REAL, POINTER                     :: GLL(:)                !< Position of Gauss-Lobatto-Legendre points in [-1,+1] domain
    REAL, POINTER                     :: W_GLL(:)           !< Integration weights associated to GLL points
    REAL, POINTER                     :: GLLPolyC(:,:)      !< Coefficients of the 1D Legendre polynomials
    REAL, POINTER                     :: D_GLL(:,:)         !< Derivatives of Legendre basis functions at each GLL point
    REAL, POINTER                     :: D_GLL_T(:,:)       !< Transpose of the derivatives matrix D_GLL
    INTEGER, POINTER                  :: GLLIndex3D(:,:)    !< Local indexing of each GLL node in xi eta and zeta
    INTEGER, POINTER                  :: GLLTopo3D(:,:,:)   !< Correspondence local to global node ordering
    INTEGER, POINTER                  :: GLLIndex2D(:,:)    !< Local indexing of each GLL node in xi eta and zeta
    INTEGER, POINTER                  :: GLLTopo2D(:,:)     !< Correspondence local to global node ordering
    REAL, POINTER                     :: Dx_Dxi(:,:,:,:)    !< Gradients of the deformation of the elements at each GLL point
    REAL, POINTER                     :: Dxi_Dx(:,:,:,:)    !< Inverse of Dx_Dxi
    REAL, POINTER                     :: Jacobian(:,:)      !< Determinant of the Jacobian matrix (dxi_i/dx_i) at each GLL point
    REAL, POINTER                     :: RhoInvGLL(:,:)     !< Inverse of density at each GLL node
    REAL, POINTER                     :: CijGLL(:,:,:)      !< Material stiffness entries at each GLL node
    REAL, POINTER                     :: MaxWaveSpeedGLL(:,:) !< Maximum Cp at each GLL node
    INTEGER                           :: Hetero             !< 0: Homogenous material present, 1: Heterogeneous material present
    !<
    !< Space-time DG matrices
    REAL, POINTER                     :: ST_MassMatrix(:,:)
    REAL, POINTER                     :: ST_Kxi(:,:)
    REAL, POINTER                     :: ST_Keta(:,:)
    REAL, POINTER                     :: ST_Kzeta(:,:)
    REAL, POINTER                     :: ST_Ktau(:,:)
    REAL, POINTER                     :: ST_F0(:,:)
    REAL, POINTER                     :: ST_F1(:,:)
    TYPE(tSparseMatrix), POINTER      :: InvSystemMatrix(:)    !< Inverse system matrices
    INTEGER                           :: InvSyst_MaxnNonZeros  !< Maximum number of non-zero entries in all InvSysemMatrix-es (used for MPI)
    !<
    !< Computational cost info
    REAL                              :: Cpu_Flux     = 0.  !< Total cpu cost of flux computation
    REAL                              :: Cpu_Volume   = 0.  !< Total cpu cost of volume computation
    REAL                              :: Cpu_Source   = 0.  !< Total cpu cost of source computation
    REAL                              :: Cpu_TimeInt  = 0.  !< Total cpu cost of time integral (Cauchy-Kowalewski)
    INTEGER                           :: nCpu_Flux    = 0   !< Total number of flux computation
    INTEGER                           :: nCpu_Volume  = 0   !< Total number of volume computation
    INTEGER                           :: nCpu_Source  = 0   !< Total number of source computation
    INTEGER                           :: nCpu_TimeInt = 0   !< Total number of time integral (Cauchy-Kowalewski)
    !<
    !< Stiffness matrix (tensors)
    REAL, POINTER     :: Kxi_k_Tet(:,:,:)        =>NULL()   !< Stiffness Matrix (xi)
    REAL, POINTER     :: Keta_k_Tet(:,:,:)       =>NULL()   !< Stiffness Matrix (eta)
    REAL, POINTER     :: Kzeta_k_Tet(:,:,:)      =>NULL()   !< Stiffness Matrix (zeta)
    REAL, POINTER     :: Kxi_m_Tet(:,:,:)        =>NULL()   !< Stiffness Matrix (xi)
    REAL, POINTER     :: Keta_m_Tet(:,:,:)       =>NULL()   !< Stiffness Matrix (eta)
    REAL, POINTER     :: Kzeta_m_Tet(:,:,:)      =>NULL()   !< Stiffness Matrix (zeta)
    REAL, POINTER     :: ADGxi_Tet(:,:,:)        =>NULL()   !< Transpose stiffness / mass in xi   (Used in Cauchy Kowalewski)
    REAL, POINTER     :: ADGeta_Tet(:,:,:)       =>NULL()   !< Transpose stiffness / mass in eta  (Used in Cauchy Kowalewski)
    REAL, POINTER     :: ADGzeta_Tet(:,:,:)      =>NULL()   !< Transpose stiffness / mass in zeta (Used in Cauchy Kowalewski)
    REAL, POINTER     :: ADGklm_Tet(:,:,:)       =>NULL()   !< ADER-DG tensor for space dependent reaction term (= identical to identity matrix for constant material per element -> to be optimized!)
    REAL, POINTER     :: FluxInt_Tet(:,:,:,:,:,:)=>NULL()   !< Flux matrices integrals
    !<
    REAL, POINTER     :: Kxi_k_Hex(:,:,:)        =>NULL()   !< Stiffness Matrix (xi)
    REAL, POINTER     :: Keta_k_Hex(:,:,:)       =>NULL()   !< Stiffness Matrix (eta)
    REAL, POINTER     :: Kzeta_k_Hex(:,:,:)      =>NULL()   !< Stiffness Matrix (zeta)
    REAL, POINTER     :: Kxi_m_Hex(:,:,:)        =>NULL()   !< Stiffness Matrix (xi)
    REAL, POINTER     :: Keta_m_Hex(:,:,:)       =>NULL()   !< Stiffness Matrix (eta)
    REAL, POINTER     :: Kzeta_m_Hex(:,:,:)      =>NULL()   !< Stiffness Matrix (zeta)
    REAL, POINTER     :: ADGxi_Hex(:,:,:)        =>NULL()   !< Stiff / Mass matrix (Used in Cauchy Kowalewski)
    REAL, POINTER     :: ADGeta_Hex(:,:,:)       =>NULL()   !< Stiff / Mass matrix (Used in Cauchy Kowalewski)
    REAL, POINTER     :: ADGzeta_Hex(:,:,:)      =>NULL()   !< Stiff / Mass matrix (Used in Cauchy Kowalewski)
    REAL, POINTER     :: FluxInt_Hex(:,:,:,:,:,:)=>NULL()   !< Flux matrices integrals

    !< Sparse version of tensors
    TYPE(tSparseTensor3b), POINTER    :: Kxi_k_Tet_Sp         =>NULL() !< Stiffness in xi (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Keta_k_Tet_Sp        =>NULL() !< Stiffness in eta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Kzeta_k_Tet_Sp       =>NULL() !< Stiffness in zeta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Kxi_m_Tet_Sp         =>NULL() !< Stiffness in xi (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Keta_m_Tet_Sp        =>NULL() !< Stiffness in eta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Kzeta_m_Tet_Sp       =>NULL() !< Stiffness in zeta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGxi_Tet_Sp         =>NULL() !< Transpose stiffness / mass in xi (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGeta_Tet_Sp        =>NULL() !< Transpose stiffness / mass in eta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGzeta_Tet_Sp       =>NULL() !< Transpose stiffness / mass in zeta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGklm_Tet_Sp        =>NULL() !< ADER-DG tensor for space dependent reaction term (= identical to identity matrix for constant material per element -> to be optimized!)
    TYPE(tSparseTensor3b), POINTER    :: FluxInt_Tet_Sp(:,:,:)=>NULL() !< Flux matrices integrals (sparse)
    !<
    TYPE(tSparseTensor3b), POINTER    :: Kxi_k_Hex_Sp         =>NULL() !< Stiffness in xi (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Keta_k_Hex_Sp        =>NULL() !< Stiffness in eta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Kzeta_k_Hex_Sp       =>NULL() !< Stiffness in zeta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Kxi_m_Hex_Sp         =>NULL() !< Stiffness in xi (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Keta_m_Hex_Sp        =>NULL() !< Stiffness in eta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: Kzeta_m_Hex_Sp       =>NULL() !< Stiffness in zeta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGxi_Hex_Sp         =>NULL() !< Transpose stiffness / mass in xi (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGeta_Hex_Sp        =>NULL() !< Transpose stiffness / mass in eta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: ADGzeta_Hex_Sp       =>NULL() !< Transpose stiffness / mass in zeta (sparse)
    TYPE(tSparseTensor3b), POINTER    :: FluxInt_Hex_Sp(:,:,:)=>NULL() !< Flux matrices integrals (sparse)
    !<
    !< Star matrices
    TYPE(tSparseTensor3), POINTER     :: AStar_Sp(:) => NULL()         !< Sparse star tensor A
    TYPE(tSparseTensor3), POINTER     :: BStar_Sp(:) => NULL()         !< Sparse star tensor B
    TYPE(tSparseTensor3), POINTER     :: CStar_Sp(:) => NULL()         !< Sparse star tensor C
    TYPE(tSparseTensor3), POINTER     :: EStar_Sp(:) => NULL()         !< Sparse star tensor E
    !<
    TYPE(tSparseTensor3), POINTER     :: FLStar_Sp(:,:) => NULL()      !< Sparse flux tensor
    TYPE(tSparseTensor3), POINTER     :: FRStar_Sp(:,:) => NULL()      !< Sparse flux tensor
    !<
  END TYPE tGalerkin

  TYPE tAdjoint
     INTEGER                                :: KernelType                       !< Slip at given fault node
     INTEGER                                :: nKernels                         !< Number of kernels computed simultaneously
     INTEGER                                :: nIter                            !< Maximum number of iterations involved in inversion
     INTEGER                                :: IterIni                          !< Index of initial iteration in current run
     INTEGER                                :: IterFin                          !< Index of final iteration in current run
     INTEGER                                :: MisfitType                       !< Type of misfit used in inversion
     REAL, POINTER                          :: dgvar_adj(:,:,:,:)               !< Data-array for expansion (Adj.)
     REAL, POINTER                          :: Kernel(:,:,:)                    !< DOFs of the sensitivity kernel
     REAL, POINTER                          :: Gradient(:,:)                    !< Gradient of model from sensitivity kernel
     REAL, POINTER                          :: TotalGradient(:)                 !< Sum of gradients of all elements in the mesh
     REAL, POINTER                          :: EM(:,:), PM(:,:)                 !< Single value envelope and phase misfits
     REAL, POINTER                          :: TIEM(:,:), TIPM(:,:)             !< Time integrated envelope and phase misfits
     INTEGER                                :: nt_ft                            !< Number of samples in freq domain for TF misfit
     REAL                                   :: fmin, fmax                       !< Frequency range for TF misfit
     REAL                                   :: w0                               !< Omega_0 value in Morlet wavelet
     INTEGER                                :: SpFilterType                     !< Type of spatial filter applied to kernels
     REAL                                   :: SmoothSize                       !< Size of gaussian smoothening function
     REAL, POINTER                          :: SpFilter(:,:)                    !< DOF representation of the spatial filter
  END TYPE tAdjoint

  !< includes background stress information for dynamic rupture
  TYPE tbackground_stress
     INTEGER                                :: nx,nz
     REAL, POINTER                          :: strike(:)
     REAL, POINTER                          :: dip(:)
     REAL, POINTER                          :: fields(:,:)
                                                 ! variable fields contains in this order
                                                 ! normal_stress
                                                 ! traction_strike
                                                 ! traction_dip
                                                 ! mu_S
                                                 ! mu_D
                                                 ! D_C
                                                 ! cohesion (should be negative since negative normal stress is compression)
                                                 ! forced_rupture_time
  END TYPE tbackground_stress

!< constants
  type tDynRun_constants
    real :: p0
    real :: ts0
    real :: td0
  end type tDynRun_constants

!< Dynamic Rupture output variables, without rupture front output
  TYPE tDynRup_output
     REAL, POINTER                          :: OutNodes(:,:)                    !< Node output positions at fault
     REAL, POINTER                          :: OutEval(:,:,:,:)                 !< Values for the automatic evaluation of DOFs at fault output nodes
     REAL, POINTER                          :: OutVal(:,:,:)                    !< State variable used at Rate-and-state friction laws
     REAL, POINTER                          :: OutInt(:,:)                      !< nearest BndGP from output faultreceiver
     REAL, POINTER                          :: OutInt_dist(:)                   !< distance from nearest BndGP from output faultreceiver
     INTEGER                                :: nOutPoints                       !< Number of output points per element
     INTEGER                                :: nOutVars
        !< Number of output variables (calculated using OututMask)
     INTEGER                                :: printtimeinterval                !< Time interval at which output will be written
     INTEGER                                :: OutputMask(1:6)                  !< Info of desired output 1/ yes, 0/ no - position: 1/ slip rate 2/ stress 3/ normal velocity 4/ in case of rate and state output friction and state variable 5/ initial stress fields 6/ displacement
     INTEGER                      , POINTER :: OutputLabel(:)                   !< Info of desired output 1/ yes, 0/ no - position: 1/ slip rate 2/ stress 3/ normal velocity 4/ in case of rate and state output friction and state variable 5/ initial stress fields
     LOGICAL                                :: DR_pick_output                   !< DR output at certain receiver stations
     INTEGER                                :: nDR_pick                         !< number of DR output receiver for this domain
     TYPE(tUnstructPoint)         , POINTER :: RecPoint(:)                      !< DR pickpoint location
     INTEGER                      , POINTER :: VFile(:)                         !< unit numbers for DR pickpoints
     INTEGER                                :: MaxPickStore                     !< output every MaxPickStore
     INTEGER                      , POINTER :: CurrentPick(:)                   !< Current storage time level
     REAL                         , POINTER :: TmpTime(:)                       !< Stored time levels
     REAL                         , POINTER :: TmpState(:,:,:)                  !< Stored variables
     REAL                         , POINTER :: rotmat(:,:,:)                    !< stores rotation matrix for fault receiver
     REAL                                   :: p0
     integer                                :: refinement
     integer                                :: BinaryOutput
     integer,pointer                        :: elements_per_rank(:)
     integer                                :: refinement_strategy
  END TYPE tDynRup_output

  TYPE tDynRup
     REAL, POINTER                          :: Slip1(:,:)                        !< Slip path at given fault node along loc dir 1
     REAL, POINTER                          :: Slip2(:,:)                        !< Slip path at given fault node along loc dir 2
     REAL, POINTER                          :: SlipRate1(:,:)                   !< Slip Rate at given fault node
     REAL, POINTER                          :: SlipRate2(:,:)                   !< Slip Rate at given fault node
     REAL, POINTER                          :: Mu(:,:)                          !< Current friction coefficient at given fault node
     REAL, POINTER                          :: Mu_S(:,:)                        !< Static friction coefficient at given fault node
     REAL, POINTER                          :: Mu_D(:,:)                        !< Dynamic friction coefficient at given fault node
     REAL, POINTER                          :: StateVar(:,:)                    !< State variable used at Rate-and-state friction laws
     REAL, POINTER                          :: cohesion(:,:)                    !< cohesion at given fault node  (should be negative since negative normal stress is compression)
     REAL                                   :: cohesion_0                       !< Default cohesion value
     REAL, POINTER                          :: forced_rupture_time(:,:)         !< forced rupture time at given fault node
     REAL                                   :: XHypo                            !< x-coordinate of the forced rupture patch
     REAL                                   :: YHypo                            !< y-coordinate of the forced rupture circle
     REAL                                   :: ZHypo                            !< z-coordinate of the forced rupture circle
     REAL                                   :: R_crit                           !< radius for the forced rupture nucleation patch
     REAL                                   :: t_0                              !< forced rupture decay time
     REAL, ALLOCATABLE                      :: BndBF_GP_Tet(:,:,:)              !< Basis functions of '-' element at fault surface with matching GP (nDegFr,nBndGP,nSide)
     REAL, ALLOCATABLE                      :: FluxInt(:,:,:)                   !< corresponding flux integration matrix (nDegFr,nDegFr,nSide))
     REAL, ALLOCATABLE                      :: RS_srW_array(:,:)                !< velocity weakening scale, array of spatial dependency
     REAL                                   :: RS_sr0                           !< Reference slip rate
     REAL                                   :: RS_sl0                           !< Reference slip
     REAL                                   :: RS_f0                            !< Reference friction coefficient
     REAL                                   :: RS_a                             !< RS constitutive parameter "a"
     REAL, POINTER                          :: RS_a_array(:,:)                  !< Spatial dependent RS constitutive parameter "a"
     REAL                                   :: RS_b                             !< RS constitutive parameter "b"
     REAL                                   :: RS_iniSlipRate1                  !< initial slip rate for rate and state friction
     REAL                                   :: RS_iniSlipRate2                  !< initial slip rate for rate and state friction
     REAL                                   :: Mu_W                             !< velocity weakening friction coefficient
     REAL                                   :: RS_srW                           !< velocity weakening scale
     REAL                                   :: H_Length                         !< Characteristic length (Self-similar crack)
     REAL                                   :: RupSpeed                         !< Rupture speed (Self-similar crack)
     REAL                                   :: Mu_S_ini                         !< Static friction coefficient ini scalar value
     REAL                                   :: Mu_SNuc_ini                      !< Static friction coefficient inside the nucleation zone ini scalar value
     REAL                                   :: Mu_D_ini                         !< Dynamic friction coefficient ini scalar value
     REAL                                   :: D_C_ini                          !< Critical slip read-in variable for constant value over the entire fault
     REAL, POINTER                          :: D_C(:,:)                         !< Critical slip at given fault node
     INTEGER                                :: Nucleation                       !< Nucleation
     INTEGER                                :: NucDirX                          !< Axis for locating nucleation patch (1: x, 2: y)
     INTEGER                                :: NucDirY                          !< Axis for locating nucleation patch (1: x, 2: y)
     REAL                                   :: NucXmin                          !< Lower boundary of nucleation patch
     REAL                                   :: NucXmax                          !< Upper boundary of nucleation patch
     REAL                                   :: NucYmin                          !< Lower boundary of nucleation patch
     REAL                                   :: NucYmax                          !< Upper boundary of nucleation patch
     REAL                                   :: NucBulk_xx_0                     !< Nucleation bulk stress
     REAL                                   :: NucBulk_yy_0                     !< Nucleation bulk stress
     REAL                                   :: NucBulk_zz_0                     !< Nucleation bulk stress
     REAL                                   :: NucShearXY_0                     !< Nucleation shear stress
     REAL                                   :: NucShearYZ_0                     !< Nucleation shear stress
     REAL                                   :: NucShearXZ_0                     !< Nucleation shear stress
     REAL                                   :: NucRS_sv0                        !< Nucleation state variable
     REAL                                   :: r_s                              !< width of the smooth transition
     INTEGER                                :: read_fault_file                  !< Switch for reading in fault parameters from Par_file_faults (1: on, 0: off)
     INTEGER                                :: BackgroundType                   !< Type of background stresses (0: homogeneous)
     TYPE(tbackground_stress)               :: bg_stress                        !< includes background stress information for dynamic rupture
     INTEGER                                :: inst_healing                     !< instantaneous healing switch (1: on, 0: off)
     ! case(6) bimaterial with LSW
     REAL                                   :: v_Star                           !< reference velocity of prakash-cliff regularization
     REAL                                   :: L                                !< reference length of prakash-cliff regularization
     REAL, POINTER                          :: Strength(:,:)                    !< save strength since it is used for bimaterial
     !RF output handled in tDynRup as it has to be computed in the friction solver
     INTEGER                                :: RF_output_on                     !< rupture front output on = 1, off = 0
     LOGICAL, ALLOCATABLE                   :: RF(:,:)                          !< rupture front output for this GP: true or false
     ! Magnitude output
     INTEGER                                :: magnitude_output_on              !< magnitude output on = 1, off = 0
     LOGICAL, ALLOCATABLE                   :: magnitude_out(:)                 !< magnitude output: true or false
     REAL, ALLOCATABLE                      :: averaged_Slip(:)                 !< slip averaged per element (length all + elements in this domain)
     ! declarate output types
     LOGICAL                                :: DR_output                        !< Dynamic Rupture output just for domains with "+" elements
     INTEGER                                :: OutputPointType                  !< Type of output (3: at certain pickpoint positions, 4: at every element , 5: option 3 + 4)
     TYPE(tDynRup_output)                   :: DynRup_out_atPickpoint           !< Output data at pickpoints for Dynamic Rupture processes
     TYPE(tDynRup_output)                   :: DynRup_out_elementwise           !< Output data at all elements for Dynamic Rupture processes
#ifdef HDF
     TYPE(thd_fault_receiver)           , POINTER :: hd_rec                           !< HDF5 file handle for fault hdf5 outpu
#endif

    integer              :: nDRElems !< number of DR Elems
    real*8, allocatable  :: DRupdates(:,:,:)            !< shadow storage of receiver elemes 
    integer, allocatable :: indicesOfDRElems(:) !< indices of elements having a pickpoint
    integer, allocatable :: DRupdatesPosition(:,:) !< helper array to determine the position inside DRupdates in friction routine

    integer              :: nDRElemsMIC !< number of DR Elems
    real*8, allocatable  :: DRupdatesMIC(:,:,:)            !< shadow storage of receiver elemes 
    integer, allocatable :: indicesOfDRElemsMIC(:) !< indices of elements having a pickpoint
    integer, allocatable :: indicesOfDRElemsInCPUupdates(:) !< indices of elements having a pickpoint

     type(tDynRun_constants),pointer         :: DynRup_Constants(:), DynRup_Constants_globInd(:)
   END TYPE tDynRup                                                        !<

  !<--- Tracing with Intel Trace Tools, function handles -----------------------
  TYPE tTracing
     INTEGER                                :: hLib
     INTEGER                    , POINTER   :: hFunctions(:)
  END TYPE tTracing
  !<
  TYPE  tTimer
      REAL                                  :: tcpu0
      REAL                                  :: tcpu1
      REAL                                  :: tick
      REAL                                  :: tmax
      REAL, POINTER                         :: list(:,:)
  END TYPE tTimer
  !<
  !<--- MPI variables ------------------------------------------------------------------------------------------------------------------!
  TYPE tMPI
     INTEGER                                :: myrank                           !< My own processor number
     INTEGER                                :: nCPU                             !< Total number of CPUs
     !<                                                                         !<
     INTEGER, POINTER                       :: CPUDistribution(:)               !< Distribution of CPUs as given by METIS
     !<                                                                         !<
     INTEGER                                :: integer_kind                     !< Kinds of integers
     INTEGER                                :: integer_kindtest                 !< Testvariable of integer kind
     INTEGER                                :: real_kind                        !< Kinds of reals
     REAL                                   :: real_kindtest                    !< Testvariable of real kind
     INTEGER                                :: MPI_AUTO_INTEGER                 !< Automatic MPI types, treating
     !<                                                                            external compiler options
     INTEGER                                :: MPI_AUTO_REAL                    !< that change the kind of integers and reals
     !<                                                                         !< Currently this feature is only
     !<                                                                            implemented for reals
     INTEGER                                :: iErr, status                     !< Standard error and status variables
     !<                                                                         !<
     INTEGER, POINTER                       :: nCPUReceiveElements(:)           !< Number of elem. per CPU to receive
     INTEGER, POINTER                       :: CPUReceiveElements(:,:)          !< Element numbers in the total mesh to receive
     INTEGER, POINTER                       :: nCPUSendElements(:)              !< Number of elem. per CPU to send
     INTEGER, POINTER                       :: CPUSendElements(:,:)             !< Element numbers in the total mesh to send
     !<
     INTEGER                                :: nSendCPU, nRecvCPU
     INTEGER, POINTER                       :: SendCPU(:), RecvCPU(:)
     !<
     TYPE(tTracing)                         :: Trace                            !< For instrumented tracing of MPI calls
     TYPE(tTimer)                           :: Chron                           !< For instrumented load balance measure
     !<
     REAL, POINTER                          :: PGMarray(:,:)                    !< Array to collect all PGM from CPUs
     !<
  END TYPE tMPI

  TYPE tMPIBoundary
     !<
     !< Inside : concerns information of elements inside the domain of CPU number MPI%myrank
     !< Outside: concerns information from the neighbor CPUs. They are obviously outside the domain MPI%myrank
     !<
     LOGICAL                                :: Init                             !< Is domain initialized, i.e. have A,B,C,E been sent?
     INTEGER                                :: CPU                              !< Neighbor CPU number
     INTEGER                                :: nElem                            !< Number of elements adjacent to the MPI boundary
     INTEGER                                :: nNCDomElem                       !< Number of non-conforming domain elements adjacent to the MPI boundary
     INTEGER                                :: nNCNeighElem                     !< Number of non-conforming neighbor elements adjacent to the MPI boundary
     INTEGER                                :: nNCSendElem                      !< Number of non-conforming domain elements which have to be sent
     INTEGER, POINTER                       :: DomainElements(:)                !< Numbers of the elements adjacent to an MPI boundary (inside)
     INTEGER, POINTER                       :: NC_SendElements(:)               !< Index of the non-conforming elements which have to be sent
     INTEGER, POINTER                       :: NC_DomainElements(:)             !< Numbers of the non-conforming domain elements adjacent to an MPI boundary (inside)
     INTEGER, POINTER                       :: NC_LocalElemType(:)              !< Element type of neighbor element for non-conforming boundaries
     REAL, POINTER                          :: NC_NeighborCoords(:,:,:)         !< Vertex coordinates of elements adjacent to MPI boundary (outside)
     INTEGER, POINTER                       :: NeighborUpdate(:)                !< Can MPI neighbor do an update?
     REAL, POINTER                          :: NeighborCoords(:,:,:)            !< Vertex coordinates of elements adjacent to MPI boundary (outside)
     REAL, POINTER                          :: NeighborDOF(:,:,:)               !< Degrees of freedom for all MPI boundary cells (outside)
     REAL, POINTER                          :: NeighborDOF_adj(:,:,:)           !< Adjoint variable's degrees of freedom for all MPI boundary cells (outside)
     REAL, POINTER                          :: NeighborBackground(:,:)          !< Background flow information in MPI neighbor (outside)
     REAL, POINTER                          :: NeighborDuDt(:,:,:)              !< Update of DOF for all MPI boundary cells (outside)
     REAL, POINTER                          :: NeighborTime(:)                  !< Local time inside the MPI neighbor element
     REAL, POINTER                          :: NeighborDt(:)                    !< Local timestep inside the MPI neighbor element
     TYPE(tSparseTensor3), POINTER          :: ASpHexa(:)                       !< Sparse star tensor A
     TYPE(tSparseTensor3), POINTER          :: BSpHexa(:)                       !< Sparse star tensor B
     TYPE(tSparseTensor3), POINTER          :: CSpHexa(:)                       !< Sparse star tensor C
     TYPE(tSparseTensor3), POINTER          :: ESpHexa(:)                       !< Sparse star tensor E
     TYPE(tSparseMatrix),POINTER            :: InvSystemMatrix(:)               !< Inverse system matrix for ST-DG

     TYPE(tSparseTensor3), POINTER          :: AStar_Sp(:)  =>NULL()            !< Sparse star tensor A      
     TYPE(tSparseTensor3), POINTER          :: BStar_Sp(:)  =>NULL()            !< Sparse star tensor B      
     TYPE(tSparseTensor3), POINTER          :: CStar_Sp(:)  =>NULL()            !< Sparse star tensor C      
     TYPE(tSparseTensor3), POINTER          :: EStar_Sp(:)  =>NULL()            !< Sparse star tensor E      
     !< 
     TYPE(tSparseTensor3), POINTER          :: FLStar_Sp(:,:) => NULL()         !< Sparse flux tensor
     TYPE(tSparseTensor3), POINTER          :: FRStar_Sp(:,:) => NULL()         !< Sparse flux tensor
     !< Dynamic Rupture variables to exchange dgvar values of MPI-fault elements since the Taylor derivatives are needed in friction
     INTEGER                                :: nFault_MPI                       !< Nr of MPI boundary elements which are also fault elements for Dynamic Rupture
     INTEGER, POINTER                       :: Domain_Fault_Elem(:)             !< Numbers of the elements adjacent to an MPI boundary (inside)
     REAL, POINTER                          :: MPI_DR_dgvar(:,:,:)              !< dgvar values of MPI-fault elements
  END TYPE tMPIBoundary

  TYPE tRealMessage                                                             !< Defines a vector message of type real
      REAL, POINTER        :: Content(:)
  END TYPE tRealMessage

  TYPE tIntegerMessage                                                          !< Defines a vector message of type integer
      INTEGER, POINTER     :: Content(:)
  END TYPE tIntegerMessage

  !<--- Description of the Discretization method  --------------------------------------------------------------------------------------
  TYPE tDiscretization
     INTEGER                                :: DiscretizationMethod             !< 1=FVM, 2=Discontinuous FEM, 3=FDM
     INTEGER                                :: DistribScheme                    !< 1=N, 2=LDA, 3=PSI
     INTEGER                                :: RD_SoluPolyOrder                 !< 1= 1 Triangle, 2= 4 Subtriangles, 3= 9 Subtriangles
     INTEGER                                :: SizeOfGradientField
     INTEGER                                :: TimeMethod                       !< 1=Euler-Cauchy
     INTEGER                                :: TimeOrder                        !< TimeOrder = 1,2,3,4
     INTEGER                                :: SpaceMethod                      !< 1=First order method
     INTEGER                                :: SpaceOrder                       !< SpaceOrder = 1,2
     INTEGER                                :: Limiter                          !< 1=Use a limiter, 2=Do not use a limiter
     INTEGER                                :: FluxMethod                       !<  1=AUSMDV scheme variant 1 (NOT reliable)
     REAL                                   :: CFL                              !< Courant-Friedrichs-Lewy (CFL) number
     REAL                                   :: Theta                            !< Value of theta for implicit Newmark (theta) schemes
     REAL                                   :: dxMin                            !< Smallest Grid length (used for Timestepcalc.)
     INTEGER                                :: NGP                              !< Number of quadrature points for flux evaluation
     INTEGER                                :: MaxIteration, MaxTolCriterion    !< Maximum number of iterations to be performed
     REAL                                   :: MaxTolerance                     !< Maximum tolerance between numerical and steady solution
     REAL                                   :: r_max, r_ave, LDA_Percentage     !< Maximum amplitude of change in computational area / Average amplitude of change per node
     REAL                                   :: EndTime                          !< Simulation end time
     REAL                                   :: time                             !< updating Time
     INTEGER                                :: iterationstep                    !< current Iterationstep
     REAL                                   :: dt                               !< current delta t
     INTEGER                                :: ICAccuracy                       !< Accuracy for integration of initial condition
     INTEGER                                :: nIntGP                           !< Number of internal Gausspoints for volume integration
     REAL                         , POINTER :: IntGaussP(:,:)                   !< Positions of the Gausspoints inside the cell
     REAL                         , POINTER :: IntGaussW(:)                     !< Weights of the Gausspoints inside the cell
     INTEGER                                :: nGaussPointSide                  !< Number of internal Gausspoints for each Side
     REAL                         , POINTER :: SideWeightOfGaussPointNbr(:)     !< Weight of the Gausspoints at Side
     REAL                         , POINTER :: SidePosOfGaussPointNbr(:,:)      !< Positions of the Gausspoints at Side
     INTEGER                                :: nGaussPointElem                  !< Number of internal Gausspoints for each Element
     REAL                         , POINTER :: ElemWeightOfGaussPointNbr(:)     !< Weight of the Gausspoints in Element
     REAL                         , POINTER :: ElemPosOfGaussPointNbr(:,:)      !< Positions of the Gausspoints inside the cell
     REAL                         , POINTER :: BinomialCoeff(:,:)               !< Field of binomial coefficients
     LOGICAL                                :: UseFixTimeStep                   !< Use a fixed timestep? (T/F)
     REAL                                   :: FixTimeStep                      !< Fixed timestep
     REAL                                   :: StartCPUTime                     !< Starttime of integration of the PDE
     REAL                                   :: StopCPUTime                      !< Stoptime of integration of the PDE
     REAL                                   :: LoopCPUTime                      !< CPU-Time spent in a loop, resp. in the loops
     REAL                                   :: CPUTESTTIME                      !< CPU-TEST-TIME for testing purposes
     INTEGER                                :: GhostInterpolationOrder          !< Order used for Interpolating ghostvalues (Only in KOP environment)
     TYPE(tGalerkin)                        :: Galerkin                         !< Data for Discontinuous Galerkin scheme
     TYPE(tDynRup)                          :: DynRup                           !< Data for Dynamic Rupture processes
     TYPE(tAdjoint)                         :: Adjoint                          !< Data for adjoint inversions
     INTEGER                                :: SolverType                       !< Accuracy for integration of initial condition
     LOGICAL                                :: CalledFromStructCode             !< TRUE if called from struct Code
     INTEGER, POINTER                       :: LocalIteration(:)                !< Local iteration counter
     REAL, POINTER                          :: LocalTime(:)                     !< Local time
     REAL, POINTER                          :: LocalDt(:)                       !< Local timestep
     REAL                                   :: printtime                        !< Time for next file output
     INTEGER                                :: IterationCriterion               !< Iteration definition is based on (1) = min dt, (2) = max dt
     REAL                                   :: TotalUpdates                     !< Predicted total element updates for loc. timestepping
  END TYPE tDiscretization

  !<--- Description of the Equations  --------------------------------------------------------------------------------------------------
  TYPE tEquations
     INTEGER                                :: EqType                           !< 1=Euler equations (non-linear or linear)
     INTEGER                                :: nVar                             !< Number of variables (=4 in 2D)
     INTEGER                                :: nVarTotal                        !< Number of variables without anelastic vars.
     INTEGER                                :: nVar_fld                         !< number of field (stress and velocity) variables
     INTEGER                                :: nVar_sts                         !< number of stress variables
     INTEGER                                :: nVar_vel                         !< number of velocity variables
     INTEGER                                :: nVAr_rot                         !< number of rotation variables
     INTEGER                                :: nBackgroundVar                   !< Number of background variables
     INTEGER                                :: LinType                          !< Type of linearization: 0=global,1=local
     INTEGER                                :: Dimension                        !< Number of space dimensions (currently 3)
     INTEGER                                :: HexaDimension                    !< Nr. of dimensions can be explicitly reduced on hexahedrons
     REAL                                   :: Pi                               !< Constant Pi
     REAL                                   :: a,b                              !< Wavespeeds for Advection
     REAL                                   :: mu                               !< viscosity or Lame constant
     REAL                                   :: bulk                             !< bulk modulus for acoustic
     REAL                                   :: lambda                           !< Lame constant
     REAL                                   :: omega                            !< Angular Velocity of Rigid-Body-Vortex
     REAL                                   :: circ                             !< Circulation of Potential-Vortex
     REAL                                   :: rho0                             !< Mean/reference density
     REAL                                   :: u0                               !< Mean/reference x-velocity
     REAL                                   :: v0                               !< Mean/reference y-velocity
     REAL                                   :: w0                               !< Mean/reference z-velocity
     REAL                                   :: p0                               !< Mean/reference pressure
     REAL                                   :: c0                               !< Mean/reference sound speed
     REAL                                   :: T0                               !< Mean/reference Temperature
     REAL                                   :: Ma                               !< Mach number
     REAL                                   :: k(3)                             !< Values a,b,c for advection-diffusion-dispersion
     REAL                                   :: rho1, mu1, lambda1               !< Jump of material constants
     INTEGER                                :: nLayers                          !< Number of MODEL layers
     REAL, POINTER                          :: MODEL(:,:)                       !< Model data
     REAL, POINTER                          :: ModelVariable(:,:,:)             !< Model variable data (1:iElem,1:ModelVarDOF,1:nBackgroundVar)
     INTEGER                                :: ModelVarnPoly                    !< Order of model variable data
     INTEGER                                :: ModelVarnDegFr                   !< DOF of model variable data
     LOGICAL                                :: CartesianCoordSystem             !< .TRUE. = cartesian
     INTEGER                                :: nAneMaterialVar                  !< Number of material variables for anelasticity
     INTEGER                                :: Advection                        !< (0) = no, (1) = overlaid advection
     INTEGER                                :: Anisotropy                       !< (0) = isotop, (1) = hexagonal, (2) = orthorhombisch, (3) = tetragonal
     INTEGER                                :: Anelasticity                     !< (0) = elastic, (1) = anelastic
     INTEGER                                :: Poroelasticity                   !< (0) = non-porous, (1) = porous-HF, (2) = porous-LF with ST-DG, (3) = porous-LF with FS-DG
     INTEGER                                :: Plasticity                       !< (0) = elastic, (1) = (Drucker-Prager) visco-plastic 
     REAL                                   :: PlastCo                          !< Cohesion for the Drucker-Prager plasticity
     REAL                                   :: BulkFriction                     !< Bulk friction for the Drucker-Prager plasticity
     REAL                                   :: Tv                               !< relaxation coefficient for the update of stresses due to the Drucker-Prager plasticity, approx. (dx/V_s)
     REAL, POINTER                          :: IniStress(:,:)                   !< Initial stress (loading) for the whole domain, only used for plastic calculations
     INTEGER                                :: Adjoint                          !< (0) = no adjoint, (1) = adjoint reverse-time field is generated simultaneously to forward field
     INTEGER                                :: EndIteration                     !< The index of the last iteration in the simulation
     REAL                                   :: FinalTime                        !< The time at which a simulation ends (limited by DISC%EndTime or max. iterations)
     REAL                                   :: FinalPick                        !< The time at which a the last receiver has been outputted
     INTEGER, POINTER                       :: LocAnelastic(:)                  !< (0) = local elastic, (1) local anelastic
     INTEGER, POINTER                       :: LocPoroelastic(:)                !< (0) = non-porous, (1) = porous-HF, (2) = porous-LF with ST-DG, (3) = porous-LF with FS-DG
     !
     INTEGER                                :: nMechanisms                      !< Number of attenuation mechanisms in each layer
     INTEGER                                :: nAneFuncperMech                  !< Number of anelastic functions per mechanisms
     INTEGER                                :: AneMatIni                        !< indicates where in MaterialVal begin the anelastic parameters
     INTEGER                                :: nNonZeroEV                       !< number of non-zero eigenvalues
     INTEGER                                :: RandomField_Flag                 !< Flag for number of used random fields
     REAL                                   :: FreqCentral                      !< Central frequency of the absorption band (in Hertz)
     REAL                                   :: FreqRatio                        !< The ratio between the maximum and minimum frequencies of our bandwidth
     !<                                                                          !< .FALSE. = (r,z)
     LOGICAL                                :: linearized                       !< Are the equations linearized? (T/F)
     CHARACTER(LEN=600)                     :: MaterialFileName                 !< Filename where to load material properties
     REAL, POINTER                          :: MaterialGrid(:,:,:,:)            !< Structured grid (x,y,z,rho,mu,lamda columns) of material properties
     REAL, POINTER                          :: MaterialGridSpace(:)             !< Specifications of structured grid spacing holding material values
     !< Dynamic Rupture variables
     INTEGER                                :: DR                               !< (0) = no, (1) = dynamic rupture is present
     INTEGER                                :: FL                               !< Type of friction law used (0) = none, (1) = imposed rup vel, (2) = LSW, (3) = RS
     REAL, POINTER                          :: IniBulk_xx(:,:)                  !< Initial bulk stress at fault
     REAL, POINTER                          :: IniBulk_yy(:,:)                  !< Initial bulk stress at fault
     REAL, POINTER                          :: IniBulk_zz(:,:)                  !< Initial bulk stress at fault
     REAL, POINTER                          :: IniShearXY(:,:)                  !< Initial shear stress at fault
     REAL, POINTER                          :: IniShearYZ(:,:)                  !< Initial shear stress at fault
     REAL, POINTER                          :: IniShearXZ(:,:)                  !< Initial shear stress at fault
     REAL, POINTER                          :: IniMu(:,:)                       !< Initial friction coefficient at fault
     REAL, POINTER                          :: IniStateVar(:,:)                 !< Initial state variable value at fault
     REAL                                   :: IniSlipRate1                     !< Initial slip rate value at fault
     REAL                                   :: IniSlipRate2                     !< Initial slip rate value at fault
     REAL                                   :: ShearXY_0                        !< Initial shear stress
     REAL                                   :: ShearYZ_0                        !< Initial shear stress
     REAL                                   :: ShearXZ_0                        !< Initial shear stress
     REAL                                   :: RS_sv0
     REAL                                   :: Bulk_xx_0                        !< Initial bulk stress
     REAL                                   :: Bulk_yy_0                        !< Initial bulk stress
     REAL                                   :: Bulk_zz_0                        !< Initial bulk stress
     REAL                                   :: XRef, YRef, ZRef                 !< Location of reference point, which is used for fault orientation
     INTEGER                                :: GPwise                           !< Switch for heterogeneous background field distribution: elementwise =0 ; GPwise =1

  END TYPE tEquations

  !< Check pointing configuration
  type tCheckPoint
     real                                   :: interval                         !< Check point interval (0 = no checkpointing)
     character(len=600)                     :: filename                         !< Check point filename
     character(len=64)                      :: backend                          !< Check point backend
  end type tCheckPoint

  !<--------------------------------------------------------------------------
  !<
  !<--- Input and Output -----------------------------------------------------
  !<
  !< Unit Numbers for FileIO
  TYPE tUnitNumbers
     INTEGER                                :: NumbersStartAt                   !< Start value for unit numbers
     INTEGER                                :: ParOut                           !< Output in Restart-Parameter File
     INTEGER                                :: ParIn                            !<
     INTEGER                                :: CPUOut                           !< Output for KOP-CPU-TIME
     INTEGER                                :: FileOut                          !< Result file
     INTEGER                                :: FileOut_Tet                      !< Result file
     INTEGER                                :: FileOut_Hex                      !< Result file
     INTEGER                                :: FileIn                           !< Mesh input file
     INTEGER                                :: FileIn_Fault                     !< Input file for fault parameters
     INTEGER                                :: other01                          !< Different other files
     INTEGER                                :: other02
     INTEGER                                :: other03
     INTEGER                                :: other04
     INTEGER                                :: other05
     INTEGER                                :: other06
     INTEGER                                :: other07
     INTEGER                                :: other08
     INTEGER                                :: other09
     INTEGER                                :: other10
     INTEGER                                :: receiverStart                   !< First unit number for pick-point files
     INTEGER                     , POINTER  :: receiver(:)                     !< Pick-point file's unit numbers
     INTEGER                     , POINTER  :: VFile(:)                         !< File for the variables p,v,u,r'...(Format2)
     INTEGER                                :: maxThisDom                       !< Maximum unit number in this domain
  END TYPE tUnitNumbers
  !< Plot Body Contour parameters
  TYPE tPlotArray
     REAL                        , POINTER  :: abs(:)                              !< sort criteria
     REAL                        , POINTER  :: x(:)                                !< x-coordinate
     REAL                        , POINTER  :: y(:)                                !< y-coordinate
     REAL                        , POINTER  :: arc(:)                              !< Bogenlaenge
     REAL                        , POINTER  :: p(:)                                !< pressure referenced with
     !< stagnation pressure
  END TYPE tPlotArray
  !< Unstructured point
  TYPE tUnstructPoint
     REAL                                   :: x,y,z                            !< physical coordinates
     REAL                                   :: xi,eta,zeta                      !< reference coordinates
     REAL                   , DIMENSION(3)  :: coordx                           !< (subtet) vertices coordinates in x
     REAL                   , DIMENSION(3)  :: coordy                           !< (subtet) vertices coordinates in y
     REAL                   , DIMENSION(3)  :: coordz                           !< (subtet) vertices coordinates in z
     INTEGER                                :: index                            !< Element index
     INTEGER                                :: globalreceiverindex              !< receiver index of global list
     LOGICAL                                :: inside                           !< If a point is inside the mesh or not     
  END TYPE tUnstructPoint
  !< Spline
  TYPE  tSpline
     INTEGER                                :: nPoints                          !< Number of points on Splin
     REAL, POINTER, DIMENSION(:)            :: t                                !< values of the running curve's parameter
     REAL, POINTER, DIMENSION(:)            :: x                                !< x(t)
     REAL, POINTER, DIMENSION(:)            :: y                                !< y(t)
     REAL, POINTER, DIMENSION(:)            :: z                                !< z(t)
     REAL, POINTER, DIMENSION(:)            :: xtt                              !< xtt(t) (Second derivatives for the splines)
     REAL, POINTER, DIMENSION(:)            :: ytt                              !< ytt(t) (Second derivatives for the splines)
     REAL, POINTER, DIMENSION(:)            :: ztt                              !< ztt(t) (Second derivatives for the splines)
     INTEGER                                :: nCurvePoints                     !< Number of points defining the spline
     CHARACTER(LEN=80)                      :: Filename                         !< Filename of the Spline
  END TYPE tSpline
  !< Data Type for controlling output Intervall
  TYPE tOutputInterval
     INTEGER                                :: printIntervalCriterion           !< 1=iteration, 2=time, 3=time+iteration criterion for printed info
     INTEGER                                :: Interval                         !< Interval of iterations for output
     REAL                                   :: TimeInterval                     !< Interval of delta_t for output
     LOGICAL                                :: PlotNrGiven                      !< .TRUE. if the number for the datafile is given by KOP2d
     INTEGER                                :: plotNumber                       !< number used for datafile if (PlotNrGiven)
     INTEGER                                :: IntervalOffset                   !< Used in KOP2d environment
  END TYPE tOutputInterval
  !< Data type for Dynamic Rupture Output
  TYPE tDR
     INTEGER                                :: CurrentPick                      !< Current storage time level
     INTEGER                                :: MaxPickStore                     !< Maximum number of stored time levels
     INTEGER                                :: FileExists                       !< Indicates whether output file has been created
     REAL                         , POINTER :: TmpTime(:)                       !< Stored time levels
     REAL                         , POINTER :: TmpOutVal(:,:,:)                 !< Stored states
  END TYPE tDR
  !
#ifdef HDF
  !< HDF5 receiver output variable
  TYPE thd_receiver
     INTEGER(HID_T)                         :: file_id                          !< file handle
     CHARACTER(100), DIMENSION(2)           :: grp_name                         !< group name
     CHARACTER(100)                         :: dset_name(5)                     !< dataset name
     INTEGER                                :: ndset                            !< number of datasets
     INTEGER,ALLOCATABLE,DIMENSION(:)       :: start                            !< buffer start
     INTEGER                                :: mpi_grp                          !< mpi group of receiver output processes
     INTEGER                                :: mpi_comm                         !< mpi communicator of receiver output processes
  END TYPE

  TYPE thd_fault_receiver
     INTEGER(HID_T)                         :: file_id                          !< file handle
     CHARACTER(100), DIMENSION(2)           :: grp_name                         !< group name
     CHARACTER(100)                         :: dset_name(8)                     !< dataset name
     INTEGER                                :: ndset                            !< number of datasets
     INTEGER,ALLOCATABLE,DIMENSION(:)       :: start                            !< buffer start
     INTEGER                                :: mpi_grp                          !< mpi group of receiver output processes
     INTEGER                                :: mpi_comm                         !< mpi communicator of receiver output processes
  END TYPE


  !< HDF5 wavefield output variable
  TYPE thd_output
     INTEGER                                :: elem_n                           !< local number of elements
     INTEGER                                :: elem_offset                      !< offset at which to write
     INTEGER                                :: elem_total                       !< global number of elements
     INTEGER                                :: node_n                           !< local number of nodes
     INTEGER                                :: node_offset                      !< offset at which to write
     INTEGER                                :: node_total                       !< global number ofa nodes
     INTEGER                                :: refinement = 0                   !< 0 is old output style(at nodes), 1 and above is at  barycenters with consecutive subdivisions
     INTEGER                                :: points_n                         !< How many output points per each tetrahedron will be outputted (used for refinemente > 0)
     TYPE(tUnstructPoint)         , POINTER :: RecPoint(:)                      !< DR pickpoint location
  END TYPE thd_output
#endif
  !
  !< Data type for Input and Output (variable name : IO)
  TYPE tInputOutput
     TYPE(tOutputInterval)                  :: OutInterval
     LOGICAL                                :: Mesh_is_structured               !< Is mesh structured? (T/F)
     INTEGER                                :: Mesh_is_structured_ni            !< Number of elements in i direction
     INTEGER                                :: Mesh_is_structured_nj            !< Number of elements in j direction
     INTEGER                                :: Mesh_is_structured_nk            !< Number of elements in k direction
     INTEGER                                :: nrPlotVar                        !< Number of variables for output
     INTEGER                                :: Format                           !< 0=IDL, 1=TECPLOT, 2=IBM Open DX
     INTEGER                                :: dimension                        !< Dimension for output (OneD,2d,3d)
     LOGICAL                                :: dimensionMask(3)                 !< Mask which Dimension is writen
     INTEGER                                :: dimensionIndex(3)                !< Index which is kept constant
     !<                                                                         !< 2=for each variable the pick point's values are saved to one file
     INTEGER                                :: nRecordPoint                     !< number of single pickpoints
     INTEGER                                :: ntotalRecordPoint                !< total number of pickpoints from points, circles and lines
     INTEGER                                :: nlocalRecordPoint                !< local number of pickpoints
     INTEGER,POINTER                        :: igloblocRecordPoint(:) => null() !< global index of local pickpoints
     INTEGER                                :: nGeometries                      !< number of the different geometries
     INTEGER                                :: w_or_wout_ana                    !< number of variables used
     INTEGER                                :: nOutputMask                      !< number of OutputMask variables
     INTEGER,POINTER                        :: pickmask(:) => null()            !< Pickmask for receiver output
     INTEGER,POINTER                        :: pickmask_rot(:) => null()        !< Pickmask for rotational receiver output
     INTEGER,POINTER                        :: pickmask_sts(:) => null()        !< Pickmask for stress tensor receiver output
     INTEGER,POINTER                        :: pickmask_vel(:) => null()        !< Pickmask for velocity vector receiver output
     INTEGER                                :: Rotation                         !< rotational output for velocities (0=no / 1=yes)
     INTEGER(8)                             :: meta_plotter                     !< output handle for fault output pvd wrapper
     CHARACTER(LEN=3)                       :: Extension                        !< .dat for IDL and Tecplot, .dx for IBM DX
     CHARACTER(LEN=20), POINTER             :: TitleMask(:)                     !< Variable names for output
     CHARACTER(LEN=600),POINTER             :: RF_Files(:)                      !< Names for random field parameter files
     CHARACTER(LEN=600)                     :: title                            !< title for Tecplot output
     CHARACTER(LEN=200)                     :: Path                             !< Output path
     CHARACTER(LEN=60)                      :: OutputFile                       !< Output filename
     CHARACTER(LEN=200)                     :: MetisFile                        !< Metis filename
     CHARACTER(LEN=35)                      :: MeshFile                         !< Mesh filename
     CHARACTER(LEN=200)                     :: BndFile                          !< CFX boundary conditions
     CHARACTER(LEN=200)                     :: ContourFile                      !< Contour filename
     CHARACTER(LEN=200)                     :: ErrorFile                        !< Error filename
     CHARACTER(LEN=600)                     :: ParameterFile                    !< Parameter filename
     CHARACTER(LEN=20)                      :: meshgenerator                    !< ='emc2_am_fmt' or 'emc2_ftq'
                                                                                !<  or 'triangle'
     CHARACTER(LEN=600)                     :: PGMLocationsFile                 !< File, specifying PGM locations
     INTEGER                                :: PGMLocationsFlag                 !< Flag if PGM output is required or not (1 or 0)
     INTEGER                                :: nPGMRecordPoint                  !< Number of PGM locations
     INTEGER                                :: PGMstartindex                    !< Index of pickpoints indicating first PGM pickpoint
     REAL,POINTER                           :: PGM(:)                           !< Maximum peak ground motion
     REAL,POINTER                           :: PGD_tmp(:,:)                     !< PGD auxiliary variable for integration
     REAL,POINTER                           :: PGA_tmp(:,:)                     !< PGA auxiliary variable for derivation
     REAL,POINTER                           :: MaterialVal(:,:)                 !< Read in lines of (x,y,z,rho,mu,lamda) of material property structured grid
     CHARACTER(LEN=35)                      :: DATAFile                         !< Cfd Solver interface filename,
     CHARACTER(LEN=35)                      :: ObsFile                          !< File where the observations are found for adjoint inversions
     CHARACTER(LEN=35)                      :: OriginalObsFile                  !< Same as above, but without suffixes indicating multiple source input
     CHARACTER(LEN=35)                      :: SynthFile                        !< File where the synthetics from the last iteration of the inversion are found
     INTEGER                                :: MPIPickCleaningDone           !< Flag of having already performed MPI pickpoint cleaning
     LOGICAL                      ,POINTER  :: OutputMask(:)                    !< Mask for variable output
                                                                                !< .TRUE.  = do output for this variable
                                                                                !< .FALSE. = do no output for this variable
     LOGICAL                      ,POINTER  :: RotationMask(:)                  !< Mask for rotational output
     INTEGER                      ,POINTER  :: ScalList(:) !<List of Scalar Vars
     INTEGER                      ,POINTER  :: VectList(:) !<List of Vector Vars
                                                           !<(indicate 1.
                                                           !< Component)
     INTEGER                                :: nScals      !<Nr. of Output Scals
     INTEGER                                :: nVects      !<Nr. of Output Vects
     LOGICAL                                :: addBackgroundvalue               !< for domain connection
     LOGICAL                                :: plot_body_contour                !< do contour plot of a body? (T/F)
     LOGICAL                                :: CalcMassflow                     !< Calculate Massflow? (T/F)
     !<                                                                          !< von Programm gegeben (FALSE)
     INTEGER                                :: error, ICType, PlotFG            !<
     REAL                                   :: k,k0,k1,k2,k3,k4                 !< for RD-Schemes
     REAL                                   :: a,b                              !<
     REAL                                   :: picktime                         !< Time for next pickpointing
     REAL, POINTER                          :: localpicktime(:)                 !< Time for next pickpointing (local dt)
     REAL                                   :: pickdt                           !< Time increment for pickpointing
     integer                                :: pickDtType                       !< Meaning of pickdt: 1 = time, 2 = timestep(s)
     INTEGER                                :: PickLarge                        !< 0 = IO at each time level, 1 = IO every some number of levels
     INTEGER                      , POINTER :: CurrentPick(:)                   !< Current storage time level
     INTEGER                                :: MaxPickStore                     !< Maximum number of stored time levels
     REAL                         , POINTER :: TmpTime(:,:) => null()           !< Stored time levels
     REAL                         , POINTER :: TmpState(:,:,:)  => null()       !< Stored variables
     REAL                         , POINTER :: TmpState_rot(:,:,:) => null()    !< Stored variables (rotational)
     REAL                         , POINTER :: TmpState_sts(:,:,:) => null()    !< Stored variables (stress)
     REAL                         , POINTER :: TmpState_vel(:,:,:) => null()    !< Stored variables (velocity)
     !<                                                                         !<
     TYPE(tUnstructPoint)         , POINTER :: UnstructRecPoint(:)              !< Unstructured pickpoints
     TYPE(tUnstructPoint)         , POINTER :: tmpRecPoint(:)                   !< temporal     pickpoints
     TYPE(tSpline)                , POINTER :: Spline(:)                        !< Spline
     TYPE(tUnitNumbers)                     :: UNIT                             !< Structure for unit numbers
     TYPE(tDR)                              :: DR                               !< Fault-based output
     CHARACTER(LEN=600)                     :: FileName_BackgroundStress        !< File name of background stress field heterogeneous
     REAL                                   :: WallStart                        !< starttime
     REAL                                   :: WallTime_h, WallTime_s           !< wall clock time in hours / seconds
     REAL                                   :: Delay_h, Delay_s                 !<
     INTEGER                                :: AbortStatus                      !< 0 = regular
                                                                                !< 1 = lack of CPU time
                                                                                !< 2 = other error
     LOGICAL                                :: MetisWeights                     !< Run Seissol to compute METIS weights only
     INTEGER                                :: FaultOutputFlag                  !< Flag if fault output is required or not (1 or 0)
#ifdef HDF
     TYPE(thd_output)             , POINTER :: hd_out
     TYPE(thd_receiver)           , POINTER :: hd_rec
#endif

     type(tCheckPoint)                      :: checkpoint                       !< Checkpointing configuration
  END TYPE tInputOutput

  !<--------------------------------------------------------------------------
  !<
  !<--- Initial condition ----------------------------------------------------
  !<
  !< Initial values for GP=Gausspulse
  TYPE tGaussPuls
     REAL, POINTER                          :: Um(:)                            !< Homogenous background value in vector form
                                                                                !< for general systems
     REAL                                   :: rho0                             !< Homogenous background value
     REAL                                   :: u0                               !< Homogenous background value
     REAL                                   :: v0                               !< Homogenous background value
     REAL                                   :: w0                               !< Homogenous background value
     REAL                                   :: p0                               !< Homogenous background value
     REAL                                   :: XC(3)                            !< Center Coordinates
     REAL                                   :: amplitude, hwidth(3)             !< Amplitude and halfwidth
     REAL                                   :: n(3)                             !< Gausspuls system normal vector
     REAL                                   :: t1(3)                            !< Gausspuls system tangent vector 1
     REAL                                   :: t2(3)                            !< Gausspuls system tangent vector 2
     INTEGER                                :: variable                         !< Variable containing GP
     INTEGER                                :: direction                        !< direction of variation
     INTEGER                                :: setvar                           !< Nr. of variables to set
     INTEGER, POINTER                       :: varfield(:)                      !< Index array of variables to set (Var_Gauss_Puls)
     REAL, POINTER                          :: ampfield(:)                      !< Array for the amplitudes        (Var_Gauss_Puls)
     REAL                                   :: omega                            !< Omega of superposed windfield
     REAL                                   :: f                                !< Frequency of superposed windfield
  END TYPE tGaussPuls
  !< User-defined Funtion for initial condition
  TYPE tUserFunction
     INTEGER                                :: nVar, nZones                     !< Number of variables and number of zones
     TYPE(tFunctionString), POINTER         :: FuncStr(:,:)                     !< Function strings
     CHARACTER(LEN=600)                     :: Filename                         !< Filename for user function initial condition
     INTEGER, POINTER                       :: Mapping(:,:)                     !< Mapping from zone and var to function number
     INTEGER, POINTER                       :: Zones(:)                         !< Copy of zone distribution in the mesh
  END TYPE tUserFunction
  !<
  TYPE tFunctionString
     CHARACTER(LEN=900)                     :: string                           !< String containing the function string
  END TYPE tFunctionString
  !< Initial values and boundary condition for Planarwave
  TYPE tPlanarwave
     REAL                                   :: rho0                             !< Homogenous background value
     REAL                                   :: u0                               !< Homogenous background value
     REAL                                   :: v0                               !< Homogenous background value
     REAL                                   :: w0                               !< Homogenous background value
     REAL                                   :: p0                               !< Homogenous background value
     REAL                                   :: amplitude                        !< Amplitude and halfwidth
     REAL                                   :: k_vec(3)                         !< Wavenumber vector
     REAL                                   :: k_vec_mat(3)                     !< Wavenumber vector for periodic variable material
     REAL                                   :: n(3)                             !< Unit normal vector
     REAL                                   :: k                                !< Wavenumber = ||k_vec||
     REAL, POINTER                          :: Um(:)                            !< Background
     INTEGER                                :: variable                         !< Ch. variable containing the planarwave
     INTEGER                                :: setvar                           !< Nr. of variables to set
     INTEGER, POINTER                       :: varfield(:)                      !< Index array of variables to set (Var_Gauss_Puls)
     REAL, POINTER                          :: ampfield(:)                      !< Array for the amplitudes        (Var_Gauss_Puls)
  END TYPE tPlanarwave
  !< Anelastic (damped) plane wave
  TYPE tPlanarwaveAN
     INTEGER                                :: NEigenVal
     REAL                                   :: Wavenumbers(3)                   !< Wavenumbers of plane sin-wave in x-,y-,z-direction
     COMPLEX                      , POINTER :: EigenVec(:,:)                    !< Eigenvectors
     COMPLEX                      , POINTER :: EigenVal(:)                      !< Eigenvalues
     CHARACTER(LEN=600)                     :: EigenVecValName                  !< Input file name of eigenvectors and eigenvalues
  END TYPE tPlanarwaveAN
  !< Anisotropic plane wave
  TYPE tPlanarwaveANISO
     REAL                                   :: amplitude                        !< Amplitude and halfwidth
     REAL                                   :: k_vec(3)                         !< Wavenumber vector
     REAL                                   :: n(3)                             !< Unit normal vector
     REAL                                   :: k                                !< Wavenumber = ||k_vec||
     REAL, POINTER                          :: Um(:)                            !< Background
     INTEGER                                :: variable                         !< Ch. variable containing the planarwave
     INTEGER                                :: setvar                           !< Nr. of variables to set
     INTEGER, POINTER                       :: varfield(:)                      !< Index array of variables to set (Var_Gauss_Puls)
     REAL, POINTER                          :: ampfield(:)                      !< Array for the amplitudes        (Var_Gauss_Puls)
     REAL                                   :: Wavenumbers(3)                   !< Wavenumbers of plane sin-wave in x-,y-,z-direction
     COMPLEX                      , POINTER :: EigenVec(:,:)                    !< Eigenvectors
     COMPLEX                      , POINTER :: EigenVal(:)                      !< Eigenvalues
  END TYPE tPlanarwaveANISO

  !< Data for the initial condition (variable name : IC)
  TYPE tInitialCondition
     CHARACTER (LEN=25)                     :: cICType                          !< CHARACTER flag for initial data
     INTEGER                                :: iICType                          !< INTEGER flag for initian data (Euler3D)
     TYPE (tGaussPuls)                      :: GP                               !< Gauss pulse structure
     TYPE (tPlanarwave)                     :: PW                               !< Planar wave structure
     TYPE (tUserFunction)                   :: UF                               !< User defined function as initial condition
     TYPE (tPlanarwaveAN)                   :: PWAN                             !< Anelastic planar wave as initial condition
     TYPE (tPlanarwaveANISO),POINTER        :: PWANISO(:)                       !< Anisotropic planar wave as initial condition
  END TYPE tInitialCondition
  !<--------------------------------------------------------------------------
  !<
  !<--- Definitions of the boundaries --------------------------------------------------------------------------------------------------

  !<
  !< Free surface boundary
  TYPE tFreeSurface
     INTEGER                                :: nSide                            !< Number of cells of this kind
     LOGICAL                                :: plot_body_contour                !< do contour plot of a body? (T/F)
     INTEGER                                :: nPoints                          !< No. of points for body contour plot
     LOGICAL                                :: curvilinear                      !< Is wall based on curvilinear data ?
     REAL, POINTER                          :: CurveData(:,:)                   !< Data for curvilinear boundary
     REAL, POINTER                          :: Derivative(:,:)                  !< Second derivatives for the splines
     INTEGER                                :: nCurvePoints                     !< Number of points for curvilinear data
  END TYPE tFreeSurface
  !< Prescribed inflow values
  TYPE tInflow
     REAL,POINTER                           :: u0_in(:)                         !< Inflow density
     INTEGER                                :: InflowType                       !< If .NOT. constantDate, then this specifies the InflowConditionType
     TYPE (tPlaneWaveCustom), POINTER       :: PW
  END TYPE tInflow
  !< Custom plane wave inflow
  TYPE tPlaneWaveCustom
     REAL, POINTER                          :: n_vec(:)
     REAL, POINTER                          :: p_vec(:)
     REAL, POINTER                          :: t_vec(:)
     REAL, POINTER                          :: k(:)
     REAL, POINTER                          :: Ampfield(:)
     INTEGER, POINTER                       :: Varfield(:)
     INTEGER                                :: SetVar
     REAL, POINTER                          :: TimeHist(:,:)                    !< Time histories for custom incoming planewave
     INTEGER                                :: TimeHistnSteps                   !< Size of TimeHist
     REAL, POINTER                          :: FI_Point(:)                      !< First incidence point of plane wave
  END TYPE tPlaneWaveCustom
  !< Prescribed or extrapolated outflow values
  TYPE tOutflow
     INTEGER                                :: nSide                            !< Number of cells of this kind
     LOGICAL                                :: UseValue(4)                      !< T=value prescribed, F=extrapolation
     REAL                                   :: rho_inf                          !< Prescribed density (value at infinity)
     REAL                                   :: u_inf                            !< Prescribed x-velocity (value at infinity)
     REAL                                   :: v_inf                            !< Prescribed y-velocity (value at infinity)
     REAL                                   :: w_inf                            !< Prescribed z-velocity (value at infinity)
     REAL                                   :: p_inf                            !< Prescribed pressure (value at infinity)
     REAL                                   :: massflow                         !< Massflow through object
     REAL                                   :: Bx_inf                           !< Prescribed x-B Field (value at infinity)
     REAL                                   :: By_inf                           !< Prescribed y-B Field (value at infinity)
     REAL                                   :: Bz_inf                           !< Prescribed z-B Field (value at infinity)
  END TYPE tOutflow
  !<
  TYPE tBoundary
     INTEGER                                :: NoBndObjects(6)                  !< New object structure
     INTEGER                                :: NoBndSides(6)                    !< Old mono-type structure
     INTEGER                                :: StructBCCode(6)                  !< Old Euler3D BC Code system
     INTEGER                                :: Periodic                         !< Use periodic boundary conditions?
     LOGICAL                                :: DirPeriodic(3)                   !< 3D periodicity
     INTEGER                                :: NoCoupleSide                     !< Anzahl der Kopplseiten == NoBndSides(6)
     INTEGER                                :: NoCoupleCornerSides              !<
     INTEGER                                :: NoMPIDomains                     !< Number of MPI neighbor domains
     REAL                         , POINTER :: boundaryValue(:,:)               !< Field contains values of
     REAL                                   :: BNDversionID                     !< Version ID Number of BOUNDARIES input part in parameterfile Version .ge.25
     TYPE(tFreeSurface)           , POINTER :: ObjFreeSurface(:)                !< Data objects for free surface
     TYPE(tInflow)                , POINTER :: ObjInflow(:)                     !< Data objects for inflow
     TYPE(tOutflow)               , POINTER :: ObjOutflow(:)                    !< Data objects for outflow
     TYPE(tMPIBoundary)           , POINTER :: ObjMPI(:)                        !< Data objects for MPI boundary
     !<                                                                          !<
     !<                                                                          !<
     INTEGER, POINTER                       :: VirtualToCouple(:,:)             !< Index into the coupling structured, based on virtual element numbers
     LOGICAL                                :: lookUp_Connectedgline(6,6)       !<
     LOGICAL                                :: initialized                      !<
     LOGICAL                                :: LW                               !< LW-Procedure at this boundary?
  END TYPE tBoundary
  !<--------------------------------------------------------------------------
  !<
  !<--- Sources --------------------------------------------------------------
  !<
  !< Oszillation Gauss pulse source
  TYPE tGaussPulsSource
     REAL                                   :: XC(3)                            !< Center Coordinates
     REAL                                   :: ampl, hwidth                     !< Amplitude and halfwidth
     REAL                                   :: period, freq, omega              !< Period, Frequency and omega
  END TYPE tGaussPulsSource
  !< Time Gauss pulse source
  TYPE tTimeGaussPulsSource
     REAL, ALLOCATABLE                      :: SpacePosition(:,:)               !< Center Coordinates (3,nSource) 3=> (x,y, z) location
     REAL, ALLOCATABLE                      :: t0(:)                            !< Central peak
     REAL, ALLOCATABLE                      :: Width(:)                         !< Width of the pulse
     REAL, ALLOCATABLE                      :: A0(:)                            !< Amplitude of the pulse
     INTEGER                                :: nPulseSource                     !< Number of sources
     INTEGER, ALLOCATABLE                   :: EqnNr(:)                         !< Equation # on which the pulse sources shall act (nPulseSource)
     INTEGER, ALLOCATABLE                   :: Element(:)                       !< Elements that contain the pulse sources
  END TYPE tTimeGaussPulsSource
  !< Planar wave source (for refraction and scattering problems)
  TYPE tPlanarSource
     REAL                                   :: xc                               !< Center of Gaussian distribution in
                                                                                !< x-direction
     REAL                                   :: ampl, hwidth                     !< Amplitude and halfwidth
     REAL                                   :: wavelen, freq, omega             !< wavelength, frequency and omega
     INTEGER                                :: variable                         !< variable number of perturbation
  END TYPE tPlanarSource
  !<
  TYPE tDirac
     REAL                            :: x0, y0
     INTEGER                         :: nDirac                                  !< Number of Dirac sources
     REAL, POINTER                   :: SpacePosition(:,:)                      !< Space positions of Dirac sources
     REAL, POINTER                   :: TimePosition(:)                         !< Time  positions of Dirac sources
     REAL, POINTER                   :: Intensity(:)                            !< Intensities
     INTEGER, POINTER                :: EqnNr(:)                                !< Equation # on which Dirac sources shall act
     INTEGER, POINTER                :: Element(:)                              !< Elements that contain the Dirac sources
  END TYPE tDirac
  !<
  TYPE tRicker
     REAL                            :: x0, y0
     INTEGER                         :: nRicker                                 !< Number of Ricker sources
     REAL, POINTER                   :: SpacePosition(:,:)                      !< Space positions of Ricker sources
     REAL, POINTER                   :: Delay(:)                                !< Time  positions of Ricker sources
     REAL, POINTER                   :: a1(:), f(:)                             !< Parameters for Ricker wavelets in time
     INTEGER, POINTER                :: EqnNr(:)                                !< Equation # on which Wavelet sources shall act
     INTEGER, POINTER                :: Element(:)                              !< Elements that contain the Ricker wavelet in time
  END TYPE tRicker
  !<
  TYPE tHypocenter
     REAL                            :: latitude, longitude, depth              !< Spherical coordinates of Hypocenter (depth in km)
  END TYPE tHypocenter
  !<
  TYPE tRuptureplane
     INTEGER                         :: Type                                    !< Type of Rupture Plane format
     REAL                            :: length,width, htop                      !< Length, Width, and Depth     of the Rupture Plane
     REAL                            :: strk, dip, rake_ave                     !< Strike, dip and rake angles  of the Rupture Plane
     REAL                            :: HypX, HypZ                              !< Local Hypocenter coordinates of the Rupture Plane
     INTEGER                         :: nxRP, nzRP                              !< Local grid size              of the Rupture Plane
     INTEGER                         :: nsteps                                  !< Number of time steps in rupture function
     REAL                            :: dxRP, dzRP                              !< Local grid spacing           of the Rupture Plane
     REAL                            :: Xpos, Zpos                              !< Local grid spacing           of the Rupture Plane
     REAL                            :: RiseTime_ave                            !< Average Rise Time            of the Rupture Plane
     REAL                            :: TWindowLen                              !< Length of Time Window
     REAL                            :: WindowShift                             !< Time shift
     REAL                            :: t_samp                                  !< Time sampling of rupture functions
     REAL                            :: T_max                                   !< Time sampling of rupture functions
     INTEGER                         :: nTWindow                                !< Number of Time Windows
     INTEGER                         :: nSegments                               !< Number of Segments           of the Rupture Plane
     INTEGER, POINTER                :: nSbfs(:)                                !< Number of Subfaults          of the Rupture Plane
     INTEGER, POINTER                :: EqnNr(:)                                !< Equation # on which sources shall act
     INTEGER, POINTER                :: Element(:)                              !< Elements that contain the subfault center
     REAL, POINTER                   :: TimeHist(:,:)                           !< Time history for all subfaults
     REAL, POINTER                   :: SegStrk(:)                              !< Strike   for each segment
     REAL, POINTER                   :: SegDip(:)                               !< Dip      for each segment
     REAL, POINTER                   :: SegLen(:)                               !< Length   for each segment
     REAL, POINTER                   :: SegWid(:)                               !< Width    for each segment
     REAL, POINTER                   :: Slip(:,:)                               !< Slip       value for each subfault and time window
     REAL, POINTER                   :: SSlip(:,:)                              !< StrikeSlip value for each subfault and time window
     REAL, POINTER                   :: DSlip(:,:)                              !< DipSlip    value for each subfault and time window
     REAL, POINTER                   :: Sliprate(:,:)                           !< Sliprate   value for each subfault and time window
     REAL, POINTER                   :: Strks(:,:)                              !< Strike angles for each subfault and time window
     REAL, POINTER                   :: Dips(:,:)                               !< Dip    angles for each subfault and time window
     REAL, POINTER                   :: Rake(:,:)                               !< Rake   angles for each subfault and time window
     REAL, POINTER                   :: Area(:)                                 !< Area          for each subfault and time window
     REAL, POINTER                   :: Tonset(:)                               !< Onset time     for each subfault and time window
     REAL, POINTER                   :: TRise(:)                                !< Rise  time     for each subfault and time window
     REAL, POINTER                   :: SpacePosition(:,:)                      !< Space positions of subfault sources
     REAL, POINTER                   :: RS(:,:)                                 !< Rotation matrix
     REAL, POINTER                   :: RD(:,:)                                 !< Rotation matrix
     REAL, POINTER                   :: RY(:,:)                                 !< Rotation matrix
     REAL, POINTER                   :: RZ(:,:)                                 !< Rotation matrix
     REAL, POINTER                   :: Rglob(:,:)                              !< Rotation matrix
     REAL, POINTER                   :: RglobT(:,:)                             !< Rotation matrix
     REAL, POINTER                   :: n_strk(:)                               !< Normal vector along strike
     REAL, POINTER                   :: n_dip(:)                                !< Normal vector along dip
     REAL, POINTER                   :: corner(:)                               !< Position of the top left corner of the rupture plane
     REAL                            :: MomentTensor(3,3)                       !< The seismic moment tensor
     REAL                            :: TensorRotation(3,3)                     !< The rotation matrix of the moment tensor
     REAL                            :: TensorRotationT(3,3)                    !< The transpose rotation matrix of the moment tensor
     REAL, POINTER                   :: TWindowStart(:)                         !< Point in Time when a Time Window starts
     REAL, POINTER                   :: TWindowEnd(:)                           !< Point in Time when a Time Window ends
  END TYPE tRuptureplane
  !<
  TYPE tConvergenceSource
     REAL, POINTER                   :: U0(:)                                   !< Amplitudes for all variables
     REAL, POINTER                   :: k1(:)                                   !< x wave numbers for all variables
     REAL, POINTER                   :: k2(:)                                   !< y wave numbers for all variables
     REAL, POINTER                   :: k3(:)                                   !< z wave numbers for all variables
     REAL, POINTER                   :: l1(:)                                   !< x wave lengths for all variables
     REAL, POINTER                   :: l2(:)                                   !< y wave lengths for all variables
     REAL, POINTER                   :: l3(:)                                   !< z wave lengths for all variables
     REAL, POINTER                   :: T(:)                                    !< Period T=1/f for all variables
     REAL, POINTER                   :: omega(:)                                !< rad. frequencies for all variables
  END TYPE tConvergenceSource
  !< Sponge layer (acts as a direct (!<) source)
  TYPE tSponge
     INTEGER                                :: enabled                          !< sponge layer on (1,3) or off (0)
     REAL                                   :: delta(6)                         !< distances of sponge to boundaries
                                                                                !<   1 = xmin, 2 = xmax
                                                                                !<   3 = ymin, 4 = ymax
                                                                                !<   5 = zmin, 6 = zmax
     INTEGER                                :: itype                            !< Type of sponge
     INTEGER                                :: SpongePower                      !< Power for sponge type 1
     REAL                                   :: x0, y0, z0                       !< bottom left front corner
     REAL                                   :: x1, y1, z1                       !< top right back corner
     REAL                                   :: PMLsigma                         !< Parameter sigma for PML technique
  END TYPE tSponge

  !< Source terms are calculated from a file
  TYPE tAdjSource
     INTEGER                                :: DataFormat                       !< Format in which is read the data
     INTEGER                                :: nFwdSourceLoc                    !< Number of distinct (at different x,y,z) forward sources
     INTEGER                                :: PresentSource                    !< The source index being used at the present time simulation
     INTEGER, POINTER                       :: FwdSourceLoc(:,:)                !< Which sources correspond to which source group
     INTEGER                                :: MaxFwdSrcPerLoc                  !< Maximum number of sources present at a source location
     INTEGER                                :: nSource                          !< Number of adjoint sources
     INTEGER                                :: nVar                             !< Number of variables involved
     INTEGER, POINTER                       :: iVar(:)                          !< Index of variables involved
     REAL, POINTER                          :: SpacePosition(:,:)               !< Space positions of adjoint sources
     INTEGER, POINTER                       :: Element(:)                       !< Elements that contain the Dirac sources
     INTEGER                                :: nSamples                         !< Number of time samples in File
     REAL                                   :: Dt                               !< Timestep of data
     REAL, POINTER                          :: Misfit(:,:,:)                    !< Value of the variables in adjoint source
     INTEGER                                :: TaperType                        !< Type of tapering used
     REAL                                   :: wind_size                        !< Size of taper window
     INTEGER                                :: var_chk                          !< The variable index of the trace checked for tape onset
     REAL                                   :: Tol                              !< Tolerance that triggers taper onset
     INTEGER, POINTER                       :: Taper_ini(:)                     !< Index of first sample tapered in traces
     INTEGER, POINTER                       :: Taper_end(:)                     !< Index of last sample tapered in traces
     REAL                                   :: TaperTailSize                    !< Size of gaussian tail used in tapering (at t=L/2 taper=~e^-1)
  END TYPE tAdjSource                                                                                        !<
  !< Data for the source terms (variable name : SOURCE)
  TYPE tSource
     INTEGER                                :: Type                             !< Type of source
     INTEGER                                :: acting_on_variable               !< Source on which variable?
     INTEGER                                :: NstartX                          !< (Structured only)
     INTEGER                                :: NstartY                          !< (Structured only)
     INTEGER                                :: NendX                            !< (Structured only)
     INTEGER                                :: NendY                            !< (Structured only)
     TYPE (tGaussPulsSource)                :: GP                               !< GP Source terms
     TYPE (tTimeGaussPulsSource)            :: TimeGP                           !< Time Gauss pulse surce
     TYPE (tPlanarSource)                   :: Planar                           !< Planar wave sources
     TYPE (tDirac)                          :: Dirac                            !< Dirac sources
     TYPE (tRicker)                         :: Ricker                           !< Ricker sources
     TYPE (tHypocenter)                     :: Hypocenter                       !< Hypocenter
     TYPE (tRupturePlane)                   :: RP                               !< Rupture plane
     TYPE (tSponge)                         :: Sponge                           !< Sponge layer (direct "source")
     TYPE (tAdjSource)                      :: AdjSource                        !< Adjoint source for inversions
     TYPE (tConvergenceSource)              :: CS                               !< Source for convergence studies
     LOGICAL                                :: CauchyKovalewski                 !< Use Cauchy-Kovalewski procedure for sourceterms?
     CHARACTER(LEN=600)                     :: FSRMFileName                     !< Filename of Finite Source Rupture Model
  END TYPE tSource
  !<--------------------------------------------------------------------------
  !<
  !<--- Analyse Information --------------------------------------------------
  !<
  TYPE tAnalyse
     LOGICAL                                :: AnalyseDataPerIteration          !< Switch to analyse Data each Iteration
     INTEGER                                :: AnalyseDataNumber                !< Number of Variables for Data Output
     REAL                         , POINTER :: ErrorField(:,:)                  !< Error Field to analyse data each timestep
     INTEGER                                :: typ                              !< 0 = no,
     !<                                                                          !< 1 = compare with exact solution.
     !<                                                                          !<     Exact Solution is the initial condition
     !<                                                                          !< 2 = compare with exact solution.
     !<                                                                          !<     Exact Solution is a fine grid solution
     !<                                                                          !< 3 = compare with exact solution.
     !<                                                                          !<     Exact Solution is tanh(k(y-b/ax))
     !<                                                                          !< 4 = compare with exact solution
     !<                                                                          !<     Exact Solution is given by 1D Riemann Problem
     !<                                                                          !< 5 = compare with exact solution given by
     !<                                                                          !<     the dispersion relation of the advection-diffusion-dispersion equation
     !<                                                                          !<     u_t + a u_x + b u_xx + c u_xxx = 0
     CHARACTER(LEN=600)                     :: VariableList                     !< Variable List for Tecplot output
     LOGICAL, POINTER                       :: variables(:)                     !< 0 = no analysis of this variable
     TYPE(tPlanarwaveAN)                    :: PWAN                             !< Anelastic planar wave as initial condition
     TYPE(tPlanarwaveANISO), POINTER        :: PWANISO(:)                       !< Anisotropic planar wave as initial condition
     TYPE(tPlanarwave)                      :: PW                               !< Anelastic planar wave as initial condition
     !<
  END TYPE tAnalyse
  !<--- Optinal Fields --------------------------------------------------------
  TYPE tUnstructOptionalFields
     LOGICAL                      , POINTER :: Marker(:)                        !< Markierungsfeld f� Gitterverfeinerung oder -vergr�ung
     REAL                         , POINTER :: dt(:)                            !< Zeitschritt pro Zelle
     REAL                         , POINTER :: RK_k(:,:,:)                      !< Runge-Kutta K's
     REAL                         , POINTER :: BackgroundValue(:,:)             !< Hintergrundwerte f�earisierte Eulergleichungen
     REAL                         , POINTER :: DGLimiter(:)                     !< TVD Limiter Marker for DG
     !< plot fields dateien
     REAL                         , POINTER :: weight(:)
     REAL                         , POINTER :: Mach(:)
     REAL                         , POINTER :: Entropie(:)
     REAL                         , POINTER :: Temp(:)
     REAL                         , POINTER :: AuxField(:,:)
     REAL                         , POINTER :: rot(:,:)
     REAL                         , POINTER :: div(:)
     REAL                         , POINTER :: Alf(:)
     REAL                         , POINTER :: rotB(:,:)
     REAL                         , POINTER :: divB(:)
     REAL                         , POINTER :: grd(:,:,:)
     TYPE(tPointerToField)        , POINTER :: FieldMask(:)
     !< calc_deltaT
     REAL                         , POINTER :: vel(  :)
     REAL                         , POINTER :: sound(:)
     REAL                         , POINTER :: dt_convectiv(:)
     REAL                         , POINTER :: dt_viscos(:)
     LOGICAL                      , POINTER :: mask( :)
     !< FaceAdjustment und
     !< Viscous Part
     REAL                         , POINTER :: pvar_n(:,:)
     !< Viscous Part
     REAL                         , POINTER :: rh(:)
     !< Spatial Disc
     REAL                         , POINTER :: xlim(  :,:  )
     REAL                         , POINTER :: grad(  :,:,:)
     REAL                         , POINTER :: pvarlr(:,:,:,:)
     REAL                         , POINTER :: ftmp(  :,:  )
     !< FV Discretization
     REAL                         , POINTER :: work( :,:)
     REAL                         , POINTER :: work0(:,:)
     REAL                         , POINTER :: flux( :,:)
     !<
     !< Facet information for distance calculation
     !<
     INTEGER                         :: nFacet
     INTEGER, POINTER                :: FacetList(:,:)
     REAL, POINTER                   :: FacetBary(:,:)
     !<
  END TYPE tUnstructOptionalFields
  !<--------------------------------------------------------------------------
  !<
  !<--- Domain description ----------------------------------------------------
  !<
  TYPE tUnstructDomainDescript
     CHARACTER(LEN=100)                     :: programTitle
     INTEGER                                :: sourceTermIndex
     INTEGER                                :: Level
     TYPE(tUnstructMesh)                    :: MESH
     TYPE(tDiscretization)                  :: DISC
     TYPE(tEquations)                       :: EQN
     TYPE(tSource)                          :: SOURCE
     TYPE(tMPI)                             :: MPI
     TYPE(tBoundary)                        :: BND
     TYPE(tInputOutput)                     :: IO
     TYPE(tInitialCondition)                :: IC
     TYPE(tAnalyse)                         :: ANALYSE
     TYPE(tUnstructOptionalFields)          :: OptionalFields
     REAL                         , POINTER :: pvar(:,:)
     REAL                         , POINTER :: cvar(:,:)
     REAL                         , POINTER :: vvar(:,:)
     REAL                                   :: dtReference
     REAL                                   :: PeriodicDisp(4) 
  END TYPE tUnstructDomainDescript

  !<--- Debug ------------------------------------------------------------------
  TYPE tDebug
     LOGICAL                                :: enabled                          !< debugging messages on (T) or off (F)
     INTEGER                                :: level                            !< level of debugging messages
  END TYPE tDebug

END MODULE TypesDef
