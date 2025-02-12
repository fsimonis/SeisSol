!>
!! @file
!! This file is part of SeisSol.
!!
!! @author Josep de la Puente Alvarez (josep.delapuente AT bsc.es, http://www.geophysik.uni-muenchen.de/Members/jdelapuente)
!!
!! @section LICENSE
!! Copyright (c) 2008, SeisSol Group
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

#ifdef BG
#include "../Initializer/preProcessorMacros.fpp"
#else
#include "Initializer/preProcessorMacros.fpp"
#endif

MODULE calc_deltaT_mod
  !--------------------------------------------------------------------------
  USE TypesDef
  !--------------------------------------------------------------------------
  IMPLICIT NONE
  PRIVATE
  !----------------------------------------------------------------------------
  INTERFACE calc_deltaT
     MODULE PROCEDURE calc_deltaT
  END INTERFACE

  INTERFACE ini_calc_deltaT
     MODULE PROCEDURE ini_calc_deltaT
  END INTERFACE

  INTERFACE close_calc_deltaT
     MODULE PROCEDURE close_calc_deltaT
  END INTERFACE

  INTERFACE cfl_step
     MODULE PROCEDURE cfl_step
  END INTERFACE
  !----------------------------------------------------------------------------
  PUBLIC  :: ini_calc_deltaT
  PUBLIC  :: close_calc_deltaT
  PUBLIC  :: calc_deltaT
#ifdef GENERATEDKERNELS
  public  :: cfl_step
#endif
  !----------------------------------------------------------------------------
  ! Module Variables
  REAL             :: tol

CONTAINS

  SUBROUTINE ini_calc_deltaT(EqType,OptionalFields,EQN,MESH,IO)
    !--------------------------------------------------------------------------
    IMPLICIT NONE     
    !--------------------------------------------------------------------------
    TYPE (tEquations)             :: EQN                                         !
    TYPE (tUnstructMesh)          :: MESH
    TYPE (tUnstructOptionalFields):: OptionalFields
    TYPE (tInputOutput)           :: IO
    INTEGER                       :: EqType
    ! local Variables
    INTEGER                       :: allocStat
    !--------------------------------------------------------------------------
    INTENT(IN)                    :: MESH,EqType,IO
    INTENT(INOUT)                 :: OptionalFields
    !--------------------------------------------------------------------------
    !                                                                            !
    tol = 1.0 / (10.0**(PRECISION(1.0)-2) )                                      !
    !                                                                            !                                                    !
    ALLOCATE(                                             &                      ! Allocate
               OptionalFields%vel(         MESH%nElem)    , &                    ! Allocate
               OptionalFields%sound(       MESH%nElem)    , &                    ! Allocate
               OptionalFields%mask(        MESH%nElem)    , &                    ! Allocate
               OptionalFields%dt_convectiv(MESH%nElem)    , &                    ! Allocate
               STAT = allocStat                             )                    ! Allocate
    !                                                                            !
    IF (allocstat .NE. 0 ) THEN                                                  ! Error Handler
         logError(*) 'ALLOCATE ERROR in ini_calc_deltaT!'            ! Error Handler
         STOP                                                                    ! Error Handler
    END IF                                                                       ! Error Handler
    !                                                   !
    !                                                   !
  END SUBROUTINE ini_calc_deltaT                        !

  SUBROUTINE close_calc_deltaT(OptionalFields)
    !--------------------------------------------------------------------------
    IMPLICIT NONE     
    !--------------------------------------------------------------------------
    TYPE (tUnstructOptionalFields):: OptionalFields
    !--------------------------------------------------------------------------
    !                                                   !
    IF (ASSOCIATED(OptionalFields%vel)) THEN            !
        DEALLOCATE(OptionalFields%vel)                  ! Deallocate
    END IF                                              !
    IF (ASSOCIATED(OptionalFields%sound)) THEN          !
        DEALLOCATE(OptionalFields%sound)                ! Deallocate
    END IF                                              !
    IF (ASSOCIATED(OptionalFields%dt_convectiv)) THEN   !
        DEALLOCATE(OptionalFields%dt_convectiv)         ! Deallocate
    END IF                                              !
    IF (ASSOCIATED(OptionalFields%mask)) THEN           !
        DEALLOCATE(OptionalFields%mask)                 ! Deallocate
    END IF                                              !
    IF (ASSOCIATED(OptionalFields%dt_viscos)) THEN      !
        DEALLOCATE(OptionalFields%dt_viscos)            ! Deallocate
    END IF                                              !
  END SUBROUTINE close_calc_deltaT                      !
    
  SUBROUTINE calc_deltaT(OptionalFields,EQN,MESH,DISC,SOURCE,IO,time,printTime)
    !--------------------------------------------------------------------------
    IMPLICIT NONE
    !--------------------------------------------------------------------------
    ! argument list declaration
    TYPE (tUnstructOptionalFields):: OptionalFields
    TYPE (tEquations)             :: EQN 
    TYPE (tUnstructMesh)          :: MESH 
    TYPE (tDiscretization)        :: DISC
    TYPE (tInputOutput)           :: IO
    TYPE (tSource)                :: SOURCE
    REAL                          :: time
    REAL                          :: printTime
    ! local Variables
    REAL                          :: dt1
    !--------------------------------------------------------------------------
    INTENT(IN)                    :: EQN,MESH,SOURCE,IO,time,printTime
    INTENT(INOUT)                 :: OptionalFields, DISC
    !--------------------------------------------------------------------------
    !                                                   !

      CALL cfl_step(OptionalFields,EQN,MESH,DISC,IO)    
      !                                                 !
    dt1 = OptionalFields%dt(1)                          !
    !                                                   !
    IF(DISC%Galerkin%DGMethod.NE.3) THEN
        SELECT CASE(IO%OutInterval%printIntervalCriterion)  
        CASE(2,3)                                           
           IF ( (time+dt1) .GT. printtime ) THEN            
              OptionalFields%dt(:) = printtime - time       
           ELSEIF ( (time + 1.5 * dt1) .GT. printtime) THEN 
              OptionalFields%dt(:) = 0.5 * (printtime - time)
           ENDIF
        END SELECT                                          
        !                                                   
        IF (      (time      .LT.DISC%EndTime)          &   ! EndTime
             .AND.((time+dt1).GT.DISC%EndTime) ) THEN       
           !                                                
           logInfo(*) 'Modification: Timestep to MATCH max_time'
           logInfo(*) 'time    :', time
           logInfo(*) 'max_time:', DISC%EndTime
           logInfo(*) 'dt      :', dt1
           logInfo(*) 'reduction of dt: new dt is ',(DISC%EndTime-time)/dt1*100,' % of old ddt'
           !                                                 
           OptionalFields%dt(:) = DISC%EndTime - time       
           !                                                
           logInfo(*) 'new dt', DISC%EndTime - time
           !                                                
        ENDIF                                               
        !
        IF (ABS(time+dt1-DISC%EndTime).LT.tol) THEN 
           OptionalFields%dt(:) = DISC%EndTime - time       
        END IF                                              
    ENDIF
    !                                                   
    DISC%dt    = MINVAL(OptionalFields%dt(:))
    !
  END SUBROUTINE calc_deltaT                            

  SUBROUTINE cfl_step(OptionalFields,EQN,MESH,DISC,IO)
    !--------------------------------------------------------------------------
    IMPLICIT NONE
    !--------------------------------------------------------------------------
    ! argument list declaration
    TYPE (tUnstructOptionalFields),TARGET :: OptionalFields
    TYPE (tEquations)                     :: EQN
    TYPE (tUnstructMesh)                  :: MESH
    TYPE (tDiscretization)                :: DISC
    TYPE (tInputOutput)                   :: IO
    ! local variable declaration
    REAL,POINTER                          :: MaterialVal(:,:)
    INTEGER                               :: iElem, iNeighbor, iSide
    INTEGER                               :: idxNeighbors(MESH%GlobalElemType)
    REAL                                  :: rho, C(6,6)                                                 
    REAL                                  :: dtmin(MESH%nElem)
    !--------------------------------------------------------------------------
    INTENT(IN)                            :: EQN, MESH, IO
    INTENT(OUT)                           :: OptionalFields
    INTENT(INOUT)                         :: DISC
    !--------------------------------------------------------------------------
    !                                                                         !
    ! Compute Velocities                       
    !                                                                         
    !                                                                      
       IF ((.NOT.ASSOCIATED(OptionalFields%BackgroundValue))) THEN              
          logError(*) 'OptionalFields%BackgroundValue not associated!'
          logError(*) 'although linearized Equations are specified. '
          STOP                                                                
       END IF                                                                 
       !                                                                      
       MaterialVal => OptionalFields%BackgroundValue                                

       DO iElem = 1, MESH%nElem
           OptionalFields%sound(iElem) = MAXVAL( DISC%Galerkin%MaxWaveSpeed(iElem,:) )
       ENDDO

       SELECT CASE(EQN%Advection)
       CASE(0) 
           OptionalFields%vel(:) = 0.
       CASE(1)
           OptionalFields%vel(:) = SQRT( MaterialVal(:,4)**2 + MaterialVal(:,5)**2 + MaterialVal(:,6)**2 )
       END SELECT
    !                                                                         
    ! Berechne dt aus dt_convectiv und dt_fix                      
    !             fuer jedes Element                                          
    !                                                                         
    !                                                                      
    ! U N S T E A D Y   S O L U T I O N                                    
    !
    OptionalFields%dt_convectiv(:)  = DISC%CFL*2.0*MESH%ELEM%MinDistBarySide(:)  & 
                                     / ( OptionalFields%sound(:) + OptionalFields%vel(:) )
   !
   IF(DISC%Galerkin%pAdaptivity.GE.1) THEN                         
    OptionalFields%dt_convectiv(:) = OptionalFields%dt_convectiv(:) / & 
                                     ( 2.*DISC%Galerkin%LocPoly(:)+1  )    
   ELSE                                                            
    OptionalFields%dt_convectiv(:) = OptionalFields%dt_convectiv(:) / & 
                                     ( 2.*DISC%Galerkin%nPoly+1       )         
   ENDIF                                                  
    !
    OptionalFields%dt(:)= MIN(MINVAL(OptionalFields%dt_convectiv(:)),  &   !    Minimum konvektiv
                             DISC%FixTimeStep                         )   !    dt_fix
    !
    IF(DISC%Galerkin%DGMethod.EQ.3) THEN
      DISC%LocalDt(:) = OptionalFields%dt_convectiv(:)
      WHERE(DISC%LocalDt(:).GT.DISC%FixTimeStep)
        DISC%LocalDt(:) = DISC%FixTimeStep
      ENDWHERE
      DO iElem = 1, MESH%nElem
        dtmin(iElem) = DISC%LocalDt(iElem)
        DO iSide = 1, MESH%LocalElemType(iElem)
            iNeighbor = MESH%ELEM%SideNeighbor(iSide,iElem)
            IF(iNeighbor.LE.MESH%nElem) THEN
                dtmin(iElem) = MIN(dtmin(iElem), DISC%LocalDt(iNeighbor))
            ENDIF
        ENDDO
      ENDDO
      DO iElem = 1, MESH%nElem
        DISC%LocalDt(iElem) = dtmin(iElem)
      ENDDO
      !
      DO iElem = 1, MESH%nElem
        ! Match printtime if necessary
        IF(DISC%LocalTime(iElem)+DISC%LocalDt(iElem).GE.DISC%printtime) THEN
            DISC%LocalDt(iElem) = DISC%printtime - DISC%LocalTime(iElem)
        ENDIF
        ! Match endtime if necessary
        IF(DISC%LocalTime(iElem)+DISC%LocalDt(iElem).GE.DISC%EndTime) THEN
            DISC%LocalDt(iElem) = DISC%EndTime - DISC%LocalTime(iElem)
        ENDIF
      ENDDO
      !
    ENDIF
    !                                                                      
    !                                                                         
    RETURN                                                                    
    !                                                                         
  END SUBROUTINE cfl_step

END MODULE calc_deltaT_mod
