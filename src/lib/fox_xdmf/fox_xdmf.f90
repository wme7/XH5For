module fox_xdmf
!--------------------------------------------------------------------- -----------------------------------------------------------
!< XdmfHdf5Fortran: XDMF parallel partitioned mesh I/O on top of HDF5
!< XDMF interface module for the XML writing later on top of FoX_wxml
!--------------------------------------------------------------------- -----------------------------------------------------------

use xdmf_file
use xdmf_domain
use xdmf_grid
use xdmf_geometry
use xdmf_topology
use xdmf_dataitem

implicit none
private

public:: xdmf_file_t
public:: xdmf_domain_t
public:: xdmf_grid_t
public:: xdmf_geometry_t
public:: xdmf_topology_t
public:: xdmf_dataitem_t

end module fox_xdmf