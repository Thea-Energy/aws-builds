#!/bin/bash
# Script for installing libraries and compiling code for DESC/GX

#--------------------------------------------
#--------------------------------------------
#         USER INPUTS

INSTALL_ROOT="/ebs-shared/libraries"
base_dir="/ebs-shared"


if [ $1 == "false" ]; then
    install_miniconda="false"
    install_nvhpc="false"
    install_gsl="false"
    install_hdf5="false"
    install_netcdf="false"
    install_netcdf_fortran="false"
else
    # toggle install for each library
    install_miniconda="true"
    install_nvhpc="true"
    install_gsl="true"
    install_hdf5="true"
    install_netcdf="true"
    install_netcdf_fortran="true"
fi

#--------------------------------------------
#--------------------------------------------

cd ${base_dir}
module load openmpi5/5.0.3

get_cuda_architecture() {
    gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n 1)

    case "$gpu_model" in
	*"A100"*) echo "80" ;;
	*"H100"*) echo "90" ;;
	*"A10"*) echo "86" ;;
	*"L40"*) echo "89" ;;
	*) echo "Unknown GPU model: $gpu_model" ;;
    esac
}

#----------------
# Generic Package Installer
#----------------

install_package() {
    local library_name=$1
    local install_dir=$2
    local url=$3
    local tar_file=$4
    local source_files=$5 # building from source (true) or just binaries (false)
    local config_options=$6
    local install_options=$7
    local custom_install=$8
    
    if [ -f "${tar_file}" ]; then
	echo "${tar_file} already exists in this directory!"
    else
	echo "Downloading ${tar_file} from ${url}..."
	wget -O ${tar_file} ${url}
	if [ $? -ne 0 ]; then
	    echo "Error: Failed to download ${tar_file}"
	    exit 1
	fi
    fi

    
    extracted_dirname=$(tar -tzf ${tar_file} | head -1 | cut -f1 -d"/")
    if [ ${extracted_dirname} == "." ]; then
	# see if it's getting tripped up by a './' in front of the dirname
	extracted_dirname=$(tar -tzf ${tar_file} | head -1 | grep -oP '(?<=./).*')	
    fi

    if [ -d "${extracted_dirname}" ]; then
	echo "Extracted directory ${extracted_dirname} already exists in this directory!"
    else
	echo "Extracting ${tar_file}..."
	tar -xpzf ${tar_file}
	if [ $? -ne 0 ]; then
	    echo "Error: Failed to extract ${tar_file}"
	    exit 1
	fi
    fi

    #rm -f ${tar_file}
    #if [ $? -ne 0 ]; then
	#echo "Error: Failed to remove ${tar_file}"
	#exit 1
    #fi
    
    cd ${extracted_dirname}
    if [ $? -ne 0 ]; then
	echo "Error: Failed to enter ${extracted_dirname}"
	exit 1
    fi
    
    if [ ${source_files} == "true" ]; then

	if [ ${config_options} == "none" ]; then
	    ./configure
	else
	    ./configure ${config_options}
	fi
	
	if [ $? -ne 0 ]; then
	    echo "Error: Failed to configure ${library_name}"
	    exit 1
	fi

	make
	if [ $? -ne 0 ]; then
	    echo "Error: Failed to build ${library_name}"
	    exit 1
	fi
    fi

    if [ ${custom_install} == "true" ]; then
	${install_options}
    else
	make install ${install_options}
    fi

    if [ $? -ne 0 ]; then
	echo "Error: Failed to install ${library_name}"
	exit 1
    fi

    cd ${base_dir}
    if [ $? -ne 0 ]; then
	echo "Error: Failed to cd back to base directory"
	exit 1
    fi
}    

#----------------
# Miniconda Installation
#----------------

miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
miniconda_install_dir="${INSTALL_ROOT}/miniconda3"

echo "here"
exit 1
if [ ${install_miniconda} == "true" ]; then
    if [ -d "${miniconda_install_dir}" ]; then
	rm -rf ${miniconda_install_dir}
    fi
    mkdir -p ${miniconda_install_dir}
    wget ${miniconda_url} -O ${miniconda_install_dir}/miniconda.sh
    bash ${miniconda_install_dir}/miniconda.sh -b -u -p ${miniconda_install_dir}
    rm ${miniconda_install_dir}/miniconda.sh
    source ${miniconda_install_dir}/bin/activate
    conda init --all
fi

#----------------
# NVIDIA HPC SDK Installation
#----------------

nvhpc_url="https://developer.download.nvidia.com/hpc-sdk/23.11/nvhpc_2023_2311_Linux_x86_64_cuda_multi.tar.gz"
nvhpc_tar_file="nvhpc_2023_2311_Linux_x86_64_cuda_multi.tar.gz"
cuda_architecture=$(get_cuda_architecture)
export NVHPC_SILENT="true"
export NVHPC_INSTALL_DIR="${INSTALL_ROOT}/nvhpc"
export NVHPC_INSTALL_TYPE="single"
custom_nvhpc_install="./install"

if [ ${install_nvhpc} == "true" ]; then
    install_package "NVHPC" "${NVHPC_INSTALL_DIR}" "${nvhpc_url}" "${nvhpc_tar_file}" "false" "none" "${custom_nvhpc_install}" "true"
fi

#----------------
# GNU Scientific Library (GSL) Installation
#----------------

gsl_install_dir="${INSTALL_ROOT}/gsl"
gsl_url="https://mirror.ibcp.fr/pub/gnu/gsl/gsl-latest.tar.gz"
gsl_tar_file="gsl-latest.tar.gz"
gsl_config_options="--prefix=${gsl_install_dir}"
gsl_install_options="PREFIX=${gsl_install_dir}/bin"

if [ ${install_gsl} == "true" ]; then
    install_package "GSL" "${gsl_install_dir}" "${gsl_url}" "${gsl_tar_file}" "true" "${gsl_config_options}" "${gsl_install_options}" "false"
fi

#----------------
# HDF5 Installation
#----------------

hdf5_install_dir="${INSTALL_ROOT}/hdf5"
hdf5_url="https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_5/downloads/hdf5-1.14.5.tar.gz"
hdf5_tar_file="hdf5-1.14.5.tar.gz"
hdf5_config_options="--prefix=${hdf5_install_dir} CC=mpicc --enable-parallel"
hdf5_install_options="PREFIX=${hdf5_install_dir}/bin"

if [ ${install_hdf5} == "true" ]; then    
    install_package "HDF5" "${hdf5_install_dir}" "${hdf5_url}" "${hdf5_tar_file}" "true" "${hdf5_config_options}" "${hdf5_install_options}" "false"
fi

#----------------
# Netcdf Installation
#----------------

netcdf_install_dir="${INSTALL_ROOT}/netcdf"
netcdf_url="https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.2.tar.gz"
netcdf_tar_file="v4.9.2.tar.gz"
netcdf_config_options="--prefix=${netcdf_install_dir} CC=mpicc --disable-shared --enable-parallel-tests"
netcdf_install_options="PREFIX=${netcdf_install_dir}/bin"
export CPPFLAGS="-I${hdf5_install_dir}/include -I/usr/include"
export LDFLAGS="-L${hdf5_install_dir}/lib -L/usr/lib"
if [ ${install_netcdf} == "true" ]; then
    install_package "netcdf" "${netcdf_install_dir}" "${netcdf_url}" "${netcdf_tar_file}" "true" "${netcdf_config_options}" "${netcdf_install_options}" "false"
fi

#----------------
# Netcdf-Fortran Installation
#----------------

netcdf_fortran_install_dir="${netcdf_install_dir}/fortran"
netcdf_fortran_url="https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.0.tar.gz"
netcdf_fortran_tar_file="v4.6.0.tar.gz"

export CPPFLAGS="-I${NETCDF_DIR}/include -I${hdf5_install_dir}/include -I/usr/include"
export LDFLAGS="-L${NETCDF_DIR}/lib -L${HDF5_DIR}/lib -L/usr/lib"
export LD_LIBRARY_PATH="${NETCDF_DIR}/lib:${HDF5_DIR}/lib:/usr/lib"
export LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lm -lz -lbz2 -lzstd -lxml2 -lcurl"
netcdf_fortran_configure_options="--disable-shared --prefix=${netcdf_fortran_install_dir} --disable-fortran-type-check CC=mpicc CXX=mpicxx FC=mpif90"
netcdf_fortran_install_options="PREFIX=${netcdf_fortran_install_dir}/bin"


if [ ${install_netcdf_fortran} == "true" ]; then
    install_package "netcdf-fortran" "${netcdf_fortran_install_dir}" "${netcdf_fortran_url}" "${netcdf_fortran_tar_file}" "true" "${netcdf_fortran_configure_options}" "${netcdf_fortran_install_options}" "false"
fi

