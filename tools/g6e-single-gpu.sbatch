#!/bin/bash
#SBATCH --job-name=gpu_select
#SBATCH --output=gpu_%A_%a.out
#SBATCH --error=gpu_%A_%a.err
#SBATCH --partition=g6e-12xlarge
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:1
#SBATCH --array=0-3    # This lets you submit jobs for GPUs 0-3

export NVHPC_INSTALL_DIR=/ebs-shared/libraries/nvhpc
module load ${NVHPC_INSTALL_DIR}/modulefiles/nvhpc-nompi/23.11

# The GPU ID comes from the array task ID
export CUDA_VISIBLE_DEVICES=$SLURM_ARRAY_TASK_ID
export SLURM_LOCALID=$SLURM_ARRAY_TASK_ID

echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "SLURM_LOCALID: $SLURM_LOCALID"


# # Run the program
/ebs-shared/aws-builds/tools/gpu-info
##/fsx/running-gpu-jobs/parameter-sweeps/gpu-info
