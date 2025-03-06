#!/bin/bash

# This driver script will build and/or compile codes on AWS GPU instances

# Set base directory for installation (i.e. ${base_dir}/libraries and ${base_dir}/codes)
base_dir="/ebs-shared"

INSTALL_ALL_LIBRARIES="false"

# If ${INSTALL_ALL_LIBRARIES}="false", you can individually toggle library installs in the build.sh script
install_miniconda="false"
install_nvhpc="false"
install_gsl="false"
install_hdf5="false"
install_netcdf="false"
install_netcdf_fortran="false"

INSTALL_ALL_CODES="false"

# If ${INSTALL_ALL_CODES}="false", you can individually toggle library installs in the build.sh script
install_desc="false"
install_terpsichore="false"
install_gx="false"
install_t3d="false"

#--------------------------------------------
#--------------------------------------------

module purge

aws_repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${INSTALL_ALL_LIBRARIES}" == "true" ]; then
    source ./install_libraries.sh "${aws_repo_dir}" "${base_dir}" "true"
else
    source ./install_libraries.sh "${aws_repo_dir}" "${base_dir}" "false" "${install_miniconda}" "${install_nvhpc}" "${install_gsl}" "${install_hdf5}" "${install_netcdf}" "${install_netcdf_fortran}"
fi


if [ "${INSTALL_ALL_CODES}" == "true" ]; then
    source ./install_codes.sh "${aws_repo_dir}" "${base_dir}" "true"
else
    source ./install_codes.sh "${aws_repo_dir}" "${base_dir}" "false" "${install_desc}" "${install_terpsichore}" "${install_gx}" "${install_t3d}"
fi
