#!/bin/bash

aws_repo_dir="$1"
base_dir="$2"
code_root="${base_dir}/codes"

if [ "$3" == "true" ]; then
    install_desc="true"
    install_terpsichore="true"
    install_gx="true"
else
    install_desc="$4"
    install_terpsichore="$5"
    install_gx="$6"
fi

# Clear positional arguments
set --

if [ ! -d "${code_root}" ]; then
    mkdir ${code_root}
fi

# ---------------------------------------
# DESC Build
# ---------------------------------------

cd ${code_root}

if [ -d "DESC" ]; then
    export PYTHONPATH=/ebs-shared/DESC:$PYTHONPATH
fi

if [ ${install_desc} == "true" ]; then
    
    if [ -d "DESC" ]; then
	echo "DESC repo already exists!"
    else
	git clone https://github.com/PlasmaControl/DESC.git
	export PYTHONPATH=/ebs-shared/DESC:$PYTHONPATH
    fi
    cd DESC
    conda create --name desc-env python=3.11 --yes
    conda activate desc-env
    pip install nvidia-cudnn-cu12
    pip install --upgrade "jax[cuda12]"
    pip install -r requirements.txt
    pip install -r devtools/dev-requirements.txt
fi

# ---------------------------------------
# TERPSICHORE Build
# ---------------------------------------

cd ${code_root}
export TERPS_SYSTEM=aws
if [ ${install_terpsichore} == "true" ]; then

    if [ -d "TERPSICHORE" ]; then
	echo "TERPSICHORE repo already exists!"
    else
	git clone https://github.com/Thea-Energy/TERPSICHORE.git
    fi
    cd TERPSICHORE
    git checkout dynamic
    if [ -f "tpr_ap_THEA.x" ]; then
	echo "TERPSICHORE is already compiled!"
    else
	make clean
	make
    fi
fi
    
# ---------------------------------------
# GX Build
# ---------------------------------------
cd ${code_root}

export GK_SYSTEM=aws
export CUDAARCH=${cuda_architecture}
export OPENMPI_DIR=/opt/amazon/openmpi5
export NVIDIA_PATH=${NVHPC_INSTALL_DIR}/Linux_x86_64/23.11
export NCCL_HOME=${NVIDIA_PATH}/comm_libs/nccl
export LD_LIBRARY_PATH=${netcdf_install_dir}/lib:${hdf5_install_dir}/lib:${netcdf_fortran_install_dir}/lib:${gsl_install_dir}/lib:${NVIDIA_PATH}/math_libs/lib64:${NCCL_HOME}/lib    
if [ ${install_gx} == "true" ]; then

    if [ -d "gx" ]; then
	echo "GX repo already exists!"
    else
	git clone https://bitbucket.org/gyrokinetics/gx.git
    fi
    cd gx
    cp ${aws_repo_dir}/Makefile.aws Makefiles
    #git checkout next

    if [ -f "gx" ]; then
	echo "GX is already compiled!"
    else
	make clean
	make
    fi
fi

cd ${aws_repo_dir}
