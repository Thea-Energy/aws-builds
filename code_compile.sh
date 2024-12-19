#!/bin/bash

#--------------------------------------------
#--------------------------------------------
#         USER INPUTS

build_libraries="true"

install_desc="true"
install_gx="true"

#--------------------------------------------
#--------------------------------------------

module purge

if [ "${build_libraries}" == "true" ]; then
    source ./build.sh "true"
else
    source ./build.sh "false"
fi

module load ${nvhpc_install_dir}/modulefiles/nvhpc-nompi/23.11
source ${miniconda_install_dir}/bin/activate
conda init --all

if [ ${install_desc} == "true" ]; then

    if [ -d "DESC" ]; then
	echo "DESC repo already exists!"
    else
	git clone https://github.com/PlasmaControl/DESC.git
    fi
    export PYTHONPATH=/ebs-shared/DESC:$PYTHONPATH
    cd DESC
    conda create --name desc-env python=3.11 --yes
    conda activate desc-env
    pip install nvidia-cudnn-cu12
    pip install --upgrade "jax[cuda12]"
    pip install -r requirements.txt
    pip install -r devtools/dev-requirements.txt
fi


if [ ${install_gx} == "true" ]; then

    if [ -d "gx" ]; then
	echo "GX repo already exists!"
    else
	git clone https://bitbucket.org/gyrokinetics/gx.git
    fi
    cp Makefile.aws Makefiles
    cd gx
    git checkout next
    export GK_SYSTEM=aws
    export CUDAARCH=${cuda_architecture}
    export OPENMPI_DIR=/opt/amazon/openmpi5
    export NETCDF_DIR=${netcdf_install_dir}
    export NETCDF_FORTRAN_DIR=${netcdf_fortran_install_dir}
    export HDF5_DIR=${hdf5_install_dir}
    export GSL_ROOT=${gsl_install_dir}
    export NVIDIA_PATH=${NVHPC_ROOT}
    export NCCL_HOME=${NVHPC_ROOT}/comm_libs/nccl
    
    make
fi
