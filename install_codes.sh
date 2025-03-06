#!/bin/bash

aws_repo_dir="$1"
base_dir="$2"
code_root="${base_dir}/codes"

if [ "$3" == "true" ]; then
    install_desc="true"
    install_terpsichore="true"
    install_gx="true"
    install_t3d="true"
else
    install_desc="$4"
    install_terpsichore="$5"
    install_gx="$6"
    install_t3d="$7"
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
    conda create --name desc-env python=3.12 --yes
    conda activate desc-env
    pip install --editable .
    pip install -r devtools/dev-requirements.txt
    pip install "jax[cuda12]"
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
    cp ${aws_repo_dir}/makefiles/Makefile.aws Makefiles
    #git checkout next

    if [ -f "gx" ]; then
	echo "GX is already compiled!"
    else
	make clean
	make
    fi
fi

cd ${aws_repo_dir}

# ---------------------------------------
# T3D Build
# ---------------------------------------

cd ${code_root}


if [ ${install_t3d} == "true" ]; then

    conda deactivate
    
    
    if [ -d "gx" ]; then
	cd gx
	if [ -f "gx" ]; then
	    export GX_PATH=${code_root}/gx
	    echo "GX is compiled"
	else
	    echo "ERROR: GX must be compiled to use T3D effectively"
	    exit 1
	fi
	cd ${code_root}
    else
	echo "ERROR: GX must be compiled to use T3D effectively"
	exit 1
    fi

    if [ -d "t3d" ]; then
	echo "T3D repo already exists"
    else
	git clone https://bitbucket.org/gyrokinetics/t3d.git
    fi
    cd t3d
    conda install -c conda-forge adios2
    conda env create -f environment.yml --yes
    conda activate t3d

    # Install booz_xform in conda environment first
    cd ${code_root}
    if [ -d "booz_xform" ]; then
	echo "booz_xform repo already exists"
    else
	git clone https://github.com/hiddenSymmetries/booz_xform.git
    fi
    cd booz_xform
    pip install setuptools
    pip install wheel
    pip install ninja
    pip install pybind11
    pip install cmake
    mkdir build
    cd build
    cmake -DCMAKE_CXX_COMPILER=mpicxx ..
    make -j

    # Install T3D w/ GX capabilities
    cd ${code_root}/t3d
    pip install -e .[gx]
fi

cd ${aws_repo_dir}
