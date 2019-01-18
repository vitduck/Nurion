#include "nurion.inc"
!***********************************************************************
!
! compiler and linking information, using symbol from symbol.inc 
!
!***********************************************************************
SUBROUTINE BUILD_INFO(IU6) 
    IMPLICIT NONE 
    INTEGER IU6 

    WRITE (IU6,'(A)') '--------------------------------------------------------------------------------------------------------'
    WRITE (IU6,'(A13, A)') 'LIBMPI: ', LMPI
    WRITE (IU6,'(A13, A)') 'FC: ', FC
    WRITE (IU6,'(A13, A)') 'LLIBS: ', LLIBS
      
#ifdef OBJECTS_O0
    WRITE (IU6,*)
    WRITE (IU6, '(A13, A)') 'OBJECTS_O0: ', OBJECTS_O0
    WRITE (IU6, '(A13, A)') 'OFLAG_O: ', OFLAG_0
#endif
    
#ifdef OBJECTS_O1
    WRITE (IU6,*)
    WRITE (IU6, '(A13, A)') 'OBJECTS_O1: ', OBJECTS_O1
    WRITE (IU6, '(A13, A)') 'OFLAG_1: ', OFLAG_1
#endif

#ifdef OBJECTS_O2
    WRITE (IU6,*)
    WRITE (IU6, '(A13, A)') 'OBJECTS_O2: ', OBJECTS_O2
    WRITE (IU6, '(A13, A)') 'OFLAG_2: ', OFLAG_2
#endif

#ifdef OBJECTS_O3
    WRITE (IU6,*)
    WRITE (IU6, '(A13, A)') 'OBJECTS_O3: ', OBJECTS_O3
    WRITE (IU6, '(A13, A)') 'OFLAG_3: ', OFLAG_3
#endif

    WRITE (IU6,'(A)') '--------------------------------------------------------------------------------------------------------'
    WRITE (IU6,*)
END SUBROUTINE 
