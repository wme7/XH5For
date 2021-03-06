!-----------------------------------------------------------------
! XH5For (XDMF parallel partitioned mesh I/O on top of HDF5)
! Copyright (c) 2015 Santiago Badia, Alberto F. Martín, 
! Javier Principe and Víctor Sande.
! All rights reserved.
!
! This library is free software; you can redistribute it and/or
! modify it under the terms of the GNU Lesser General Public
! License as published by the Free Software Foundation; either
! version 3.0 of the License, or (at your option) any later version.
!
! This library is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
! Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public
! License along with this library.
!-----------------------------------------------------------------
program xh5for_ch_unstructured_mixedtopology

use xh5for
use PENF, only: I4P, I8P, R4P, R8P, str

#if defined(ENABLE_MPI) && defined(MPI_MOD)
  use mpi
#endif
  implicit none
#if defined(ENABLE_MPI) && defined(MPI_H)
  include 'mpif.h'
#endif

    !-----------------------------------------------------------------
    !< Variable definition
    !----------------------------------------------------------------- 
    type(xh5for_t)             :: xh5
    real(R8P),    dimension(72):: geometry = (/ 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 1, 0, &
                                                1, 1, 0, 2, 1, 0, 0, 0, 1, 1, 0, 1, &
                                                2, 0, 1, 0, 1, 1, 1, 1, 1, 2, 1, 1, &
                                                0, 1, 2, 1, 1, 2, 2, 1, 2, 0, 1, 3, &
                                                1, 1, 3, 2, 1, 3, 0, 1, 4, 1, 1, 4, &
                                                2, 1, 4, 0, 1, 5, 1, 1, 5, 2, 1, 5 /)

    integer(I4P), dimension(57):: topology = (/ 9,         0 ,1 ,4 ,3 ,6 ,7 ,10,9 ,  & ! Hexahedron
                                                9,         1 ,2 ,5 ,4 ,7 ,8 ,11,10,  & ! Hexahedron
                                                6,         6 ,10,9 ,12,              & ! Tetrahedron
                                                6,         5 ,11,10,14,              & ! Tetrahedron
                                                3, 6,      15,16,17,14,13,12,        & ! Polygon
                                                4,         18,15,19,                 & ! Triangle
                                                4,         16,20,17,                 & ! Triangle
                                                5,         22,23,20,19,              & ! Quadrilateral   
                                                4,         21,22,18,                 & ! Triangle
                                                4,         22,19,18 /)                 ! Triangle

    integer(I4P), dimension(10):: cellfield = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9/)

    real(R8P),    dimension(24):: nodefield = (/ 0.0, 1.0, 2.0,3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, &
                                                10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0,  &
                                                18.0, 19.0, 20.0, 21.0, 22.0, 23.0 /)

    real(R8P),    allocatable  :: out_geometry(:)
    integer(I4P), allocatable  :: out_topology(:)
    integer(I4P), allocatable  :: out_cellfield(:)
    real(R8P),    allocatable  :: out_nodefield(:)
    integer(I4P), allocatable  :: out_gridfield(:)

    integer                    :: rank = 0
    integer                    :: mpierr
    integer                    :: exitcode = 0


    !-----------------------------------------------------------------
    !< Main program
    !----------------------------------------------------------------- 

#if defined(ENABLE_MPI) && (defined(MPI_MOD) || defined(MPI_H))
    call MPI_INIT(mpierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, mpierr);
#endif

    !< Initialize some values depending on the mpi rank
    geometry = geometry/2 + rank

    !< Write XDMF/HDF5 file
    call xh5%Open(FilePrefix='xh5for_ch_unstructured_mixedtopology', Strategy=XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB, Action=XDMF_ACTION_WRITE)
    call xh5%SetGrid(NumberOfNodes=24, NumberOfElements=10,TopologyType=XDMF_TOPOLOGY_TYPE_MIXED, GeometryType=XDMF_GEOMETRY_TYPE_XYZ)
    call xh5%WriteTopology(Connectivities = topology)
    call xh5%WriteGeometry(XYZ = geometry)
    call xh5%WriteAttribute(Name='NodeField', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_NODE , Values=nodefield)
    call xh5%WriteAttribute(Name='CellField', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_CELL , Values=cellfield)
    call xh5%Close()
    call xh5%Free()

    !< Read XDMF/HDF5 file
    call xh5%Open(FilePrefix='xh5for_ch_unstructured_mixedtopology', Strategy=XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB, Action=XDMF_ACTION_READ)
    call xh5%ParseGrid()
    call xh5%ReadTopology(Connectivities = out_topology)
    call xh5%ReadGeometry(XYZ = out_geometry)
    call xh5%ReadAttribute(Name='NodeField', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_NODE , Values=out_nodefield)
    call xh5%ReadAttribute(Name='CellField', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_CELL , Values=out_cellfield)
    call xh5%Close()
    call xh5%Free()

#ifdef ENABLE_HDF5
    !< Check results
    if(.not. (sum(out_geometry - geometry)<=epsilon(0._R4P))) exitcode = -1
    if(.not. (sum(out_topology - topology)==0)) exitcode = -1
    if(.not. (sum(out_cellfield - cellfield)==0)) exitcode = -1
    if(.not. (sum(out_nodefield - nodefield)<=epsilon(0._R8P))) exitcode = -1
#else
    if(rank==0) write(*,*) 'Warning: HDF5 is not enabled. Please enable HDF5 and recompile to write the HeavyData'
#endif

#if defined(ENABLE_MPI) && (defined(MPI_MOD) || defined(MPI_H))
    call MPI_FINALIZE(mpierr)
#endif

    call exit(exitcode)

end program xh5for_ch_unstructured_mixedtopology
