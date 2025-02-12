!>
!! @file
!! This file is part of SeisSol.
!!
!! @author Christian Pelties (pelties AT geophysik.uni-muenchen.de, http://www.geophysik.uni-muenchen.de/Members/pelties)
!!
!! @section LICENSE
!! Copyright (c) 2014, SeisSol Group
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
!!
!! @section DESCRIPTION
!! routine outputs the magnitude for each MPI domain that contains a subfault
!! the results need to be gathered and summarized in a postprocessing step
!! magnitude = scalar seismic moment = slip per element * element face * shear modulus
!! unit: N*m = 10^7 dyne*cm

#ifdef BG
#include "../Initializer/preProcessorMacros.fpp"
#else
#include "Initializer/preProcessorMacros.fpp"
#endif

MODULE magnitude_output_mod
  !---------------------------------------------------------------------------!
  USE TypesDef
  !---------------------------------------------------------------------------!
  IMPLICIT NONE
  PRIVATE
  !---------------------------------------------------------------------------!
  PUBLIC  :: magnitude_output
  !---------------------------------------------------------------------------!
  INTERFACE magnitude_output
     MODULE PROCEDURE magnitude_output
  END INTERFACE

CONTAINS

  SUBROUTINE magnitude_output(MaterialVal,DISC,MESH,MPI,IO)
    !< routine outputs the magnitude for each MPI domain that contains a subfault
    !-------------------------------------------------------------------------!
    IMPLICIT NONE
    !-------------------------------------------------------------------------!
    ! Argument list declaration
    TYPE(tDiscretization), target   :: DISC                                              !
    TYPE(tUnstructMesh)             :: MESH
    TYPE(tMPI)                      :: MPI
    TYPE(tInputOutput)              :: IO
    !-------------------------------------------------------------------------!
    ! Local variable declaration                                              !
    INTEGER                         :: iElem,iSide,nSide,iFace
    INTEGER                         :: stat, UNIT_MAG
    REAL                            :: magnitude
    REAL                            :: MaterialVal(:,:)
    LOGICAL                         :: exist
    CHARACTER (LEN=5)               :: cmyrank
    CHARACTER (len=200)             :: MAG_FILE
    !-------------------------------------------------------------------------!
    INTENT(IN)    :: DISC, MESH, MPI, IO
    !-------------------------------------------------------------------------!

    ! generate unique name out of MPI rank
#ifdef PARALLEL
    ! pure MPI case
    WRITE(cmyrank,'(I5.5)') MPI%myrank                           ! myrank -> cmyrank
    WRITE(MAG_FILE, '(a,a5,a5,a4)') TRIM(IO%OutputFile),'-MAG-',TRIM(cmyrank),'.dat'
    UNIT_MAG = 299875+MPI%myrank
#else
    WRITE(MAG_FILE, '(a,a4,a4)') TRIM(IO%OutputFile),'-MAG','.dat'
    UNIT_MAG = 299875
#endif
    !
    INQUIRE(FILE = MAG_FILE, EXIST = exist)
    IF(exist) THEN
        ! If file exists, then append data
        OPEN(UNIT     = UNIT_MAG                                          , & !
             FILE     = MAG_FILE                                          , & !
             FORM     = 'FORMATTED'                                      , & !
             STATUS   = 'OLD'                                            , & !
             POSITION = 'APPEND'                                         , & !
             RECL     = 80000                                            , & !
             IOSTAT   = stat                                               ) !
        IF(stat.NE.0) THEN                                              !
           logError(*) 'cannot open ',MAG_FILE         !
           logError(*) 'Error status: ', stat                !
           STOP                                                          !
        ENDIF
    ELSE
        ! open file
        OPEN(UNIT   = UNIT_MAG                                            , & !
             FILE     = MAG_FILE                                          , & !
             FORM     = 'FORMATTED'                                      , & !
             STATUS   = 'NEW'                                            , & !
             RECL     = 80000                                            , & !
             IOSTAT   = stat                                               ) !
        IF(stat.NE.0) THEN                                              !
           logError(*) 'cannot open ',MAG_FILE         !
           logError(*) 'Error status: ', stat                !
           STOP                                                          !
        ENDIF
        !
    ENDIF
    !
    ! Compute output
    magnitude = 0.0D0
    nSide = MESH%FAULT%nSide
    DO iFace = 1,nSide
       iElem = MESH%Fault%Face(iFace,1,1)          ! Remark:
       iSide = MESH%Fault%Face(iFace,2,1)          ! iElem denotes "+" side
       IF (DISC%DynRup%magnitude_out(iFace)) THEN
           ! magnitude = scalar seismic moment = slip per element * element face * shear modulus
           magnitude = magnitude + DISC%DynRup%averaged_Slip(iFace)*DISC%Galerkin%geoSurfaces(iSide,iElem)*MaterialVal(iElem,2)
       ENDIF
    ENDDO
    !
    ! Write output
    WRITE(UNIT_MAG,*) magnitude

    CLOSE( UNIT_Mag )

  END SUBROUTINE magnitude_output

END MODULE magnitude_output_mod
