!>
!! @file
!! This file is part of SeisSol.
!!
!! @author Alex Breuer (breuer AT mytum.de, http://www5.in.tum.de/wiki/index.php/Dipl.-Math._Alexander_Breuer)
!! @author Sebastian Rettenberger (sebastian.rettenberger @ tum.de, http://www5.in.tum.de/wiki/index.php/Sebastian_Rettenberger)
!!
!! @section LICENSE
!! Copyright (c) 2015, SeisSol Group
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
!! C++/Fortran-interoperability: Fortran-bindings

#include "Initializer/preProcessorMacros.fpp"

module f_ctof_bind_interoperability
  implicit none

  interface f_interoperability_computeDynamicRupture
    module procedure f_interoperability_computeDynamicRupture
  end interface

  interface f_interoperability_writeReceivers
    module procedure f_interoperability_writeReceivers
  end interface

  contains
    !
    ! C to fortran bindings
    !
    subroutine f_interoperability_setDynamicRuptureTimeStep( i_domain, i_timeStep ) bind(C, name='f_interoperability_setDynamicRuptureTimeStep')
      use iso_c_binding
      use typesDef
      implicit none

      type(c_ptr), value                     :: i_domain
      type(tUnstructDomainDescript), pointer :: l_domain

      type(c_ptr), value                     :: i_timeStep
      integer, pointer                       :: l_timeStep

      ! convert c to fortran pointers
      call c_f_pointer( i_domain,   l_domain   )
      call c_f_pointer( i_timeStep, l_timeStep )

      l_domain%disc%iterationstep = l_timeStep
    end subroutine

    subroutine f_interoperability_getDynamicRuptureTimeStep( i_domain, o_timeStep ) bind(C, name='f_interoperability_getDynamicRuptureTimeStep')
      use iso_c_binding
      use typesDef
      implicit none

      type(c_ptr), value                     :: i_domain
      type(tUnstructDomainDescript), pointer :: l_domain

      type(c_ptr), value                     :: o_timeStep
      integer, pointer                       :: l_timeStep

      ! convert c to fortran pointers
      call c_f_pointer( i_domain,   l_domain   )
      call c_f_pointer( o_timeStep, l_timeStep )

      l_timeStep = l_domain%disc%iterationstep
    end subroutine

    subroutine f_interoperability_computeDynamicRupture( i_domain, i_time, i_timeStepWidth ) bind (c, name='f_interoperability_computeDynamicRupture')
      use iso_c_binding
      use typesDef
      use f_ftoc_bind_interoperability
      use friction_mod
      use faultoutput_mod
      implicit none

      type(c_ptr), value                     :: i_domain
      type(tUnstructDomainDescript), pointer :: l_domain

      type(c_ptr), value                     :: i_time
      real*8, pointer                        :: l_time

      type(c_ptr), value                     :: i_timeStepWidth
      real*8, pointer                        :: l_timeStepWidth

      integer :: i, rank_int

      ! register scorep region dynamic rupture
      SCOREP_USER_REGION_DEFINE( r_dr )
      SCOREP_USER_REGION_DEFINE( r_dr_output )

      SCOREP_USER_REGION_BEGIN( r_dr, "dynamic_rupture", SCOREP_USER_REGION_TYPE_COMMON )

      ! convert c to fortran pointers
      call c_f_pointer( i_domain,        l_domain)
      call c_f_pointer( i_time,          l_time  )
      call c_f_pointer( i_timeStepWidth, l_timeStepWidth )

      SCOREP_USER_REGION_BEGIN( r_dr_output, "fault_output", SCOREP_USER_REGION_TYPE_COMMON )
      call faultoutput(l_domain%eqn, l_domain%disc, l_domain%mesh, l_domain%io, l_domain%mpi, l_domain%optionalFields%BackgroundValue, l_domain%bnd, l_time, l_timeStepWidth)
      SCOREP_USER_REGION_END( r_dr_output )

      call friction(l_domain%eqn, l_domain%disc, l_domain%mesh, l_domain%mpi, l_domain%io, l_domain%optionalFields, l_domain%bnd, l_time, l_timeStepWidth)

      ! TODO: refactor
      SCOREP_USER_REGION_BEGIN( r_dr_output, "fault_output", SCOREP_USER_REGION_TYPE_COMMON )
      if( l_domain%mpi%myrank==0 .and. (l_domain%disc%dynRup%outputPointType==4 .or. l_domain%disc%dynRup%outputPointType==5) ) then
        ! fault output iterations, including iteration 1 and last timestep
        if ( mod(l_domain%disc%iterationstep-1, l_domain%disc%dynRup%dynRup_out_elementwise%printtimeinterval)==0 .or. &
             (l_domain%disc%endTime-l_time) .le. (l_timeStepWidth*1.005d0) ) then
          do i=1,size(l_domain%disc%dynRup%dynRup_out_elementwise%elements_per_rank)
            if( l_domain%disc%dynRup%dynRup_out_elementwise%elements_per_rank(i).gt.0 ) then
              rank_int=i-1
              call addtimestep_pvd_writer( l_domain%io%meta_plotter, l_time, rank_int, l_domain%disc%iterationstep )
            endif
          enddo
          ! destroy pvd file after last time step
          if( (l_domain%disc%endTime-l_time) .le. (l_timeStepWidth*1.005d0) ) then
            call close_pvd_writer(l_domain%io%meta_plotter)
            call destroy_pvd_writer(l_domain%io%meta_plotter)
            logInfo(*) 'fault-output.pvd closed'
          endif
        endif
      endif

      l_domain%disc%iterationstep = l_domain%disc%iterationstep + 1
      SCOREP_USER_REGION_END( r_dr_output )

      SCOREP_USER_REGION_END( r_dr )
    end subroutine

    subroutine f_interoperability_computePlasticity( i_domain, i_timeStep, i_initialLoading, i_stresses, o_plasticUpdate ) bind( c, name='f_interoperability_computePlasticity')
      use iso_c_binding
      use typesDef
      use plasticity_mod

      type(c_ptr), value                     :: i_domain
      type(tUnstructDomainDescript), pointer :: l_domain

      type(c_ptr), value                     :: i_timeStep
      real*8, pointer                        :: l_timeStep

      type(c_ptr), value                     :: i_initialLoading
      real*8, pointer                        :: l_initialLoading(:,:)

      type(c_ptr), value                     :: i_stresses
      real*8, pointer                        :: l_stresses(:,:)

      type(c_ptr), value                     :: o_plasticUpdate
      real*8, pointer                        :: l_plasticUpdate(:,:)

      ! local data
      real*8                                :: dudt_pstrain( 6 )

      integer                               :: l_dof, l_quantity

      ! convert c to fotran pointers
      call c_f_pointer( i_domain,         l_domain                                         )
      call c_f_pointer( i_timeStep,       l_timeStep                                       )
      call c_f_pointer( i_initialLoading, l_initialLoading, [NUMBER_OF_BASIS_FUNCTIONS,6]  )
      call c_f_pointer( i_stresses,       l_stresses,       [NUMBER_OF_BASIS_FUNCTIONS,6]  )
      call c_f_pointer( o_plasticUpdate,  l_plasticUpdate,  [NUMBER_OF_BASIS_FUNCTIONS,6]  )


      ! TODO: remove ielem
      call plasticity_3d( dgvar        = l_stresses, &
                          dofStress    = l_initialLoading, &
                          nDegFr       = NUMBER_OF_BASIS_FUNCTIONS, &
                          bulkFriction = l_domain%eqn%BulkFriction, &
                          tv           = l_domain%eqn%Tv, &
                          plastCo      = l_domain%eqn%PlastCo, &
                          dt           = l_timeStep, &
                          iElem        = 0, &
                          mu           = l_domain%eqn%mu, &
                          dudt_plastic = l_plasticUpdate, &
                          dudt_pstrain = dudt_pstrain )
    end subroutine

    subroutine f_interoperability_writeReceivers( i_domain, i_fullUpdateTime, i_timeStepWidth, i_receiverTime, i_numberOfReceivers, i_receiverIds ) bind (c, name='f_interoperability_writeReceivers')
      use iso_c_binding
      use typesDef
      use receiver_mod
      implicit none

      type(c_ptr), value                     :: i_domain
      type(tUnstructDomainDescript), pointer :: l_domain

      type(c_ptr), value                     :: i_fullUpdateTime
      real*8, pointer                        :: l_fullUpdateTime

      type(c_ptr), value                     :: i_timeStepWidth
      real*8, pointer                        :: l_timeStepWidth

      type(c_ptr), value                     :: i_receiverTime
      real*8, pointer                        :: l_receiverTime

      type(c_ptr), value                     :: i_numberOfReceivers
      integer, pointer                       :: l_numberOfReceivers

      type(c_ptr), value                     :: i_receiverIds
      integer, pointer                       :: l_receiverIds(:)

      ! convert c to fortran pointers
      call c_f_pointer( i_domain,            l_domain                             )
      call c_f_pointer( i_fullUpdateTime,    l_fullUpdateTime                     )
      call c_f_pointer( i_timeStepWidth,     l_timeStepWidth                      )
      call c_f_pointer( i_receiverTime,      l_receiverTime                       )
      call c_f_pointer( i_numberOfReceivers, l_numberOfReceivers                  )
      call c_f_pointer( i_receiverIds,       l_receiverIds, [l_numberOfReceivers] )

      ! call SeisSol's receiver procedure
      call receiver( i_fullUpdateTime    = l_fullUpdateTime,    \
                     i_timeStepWidth     = l_timeStepWidth,     \
                     i_receiverTime      = l_receiverTime,      \
                     i_numberOfReceivers = l_numberOfReceivers, \
                     i_receiverIds       = l_receiverIds,       \
                     eqn                 = l_domain%eqn,        \
                     mesh                = l_domain%mesh,       \
                     disc                = l_domain%disc,       \
                     mpi                 = l_domain%mpi,        \
                     io                  = l_domain%io )
    end subroutine

end module
