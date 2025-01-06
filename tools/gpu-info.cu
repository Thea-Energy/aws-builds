#include <stdio.h>
#include <cuda_runtime.h>
#include <nvml.h>
#include <stdlib.h>

// Error checking macro for NVML calls
#define CHECK_NVML(call) \
    do { \
        nvmlReturn_t result = call; \
        if (result != NVML_SUCCESS) { \
            printf("NVML Error: %s at line %d\n", nvmlErrorString(result), __LINE__); \
            return 1; \
        } \
    } while(0)

int main() {
    // Get SLURM_LOCALID
    char* slurm_localid = getenv("SLURM_LOCALID");
    int local_id = slurm_localid ? atoi(slurm_localid) : -1;
    
    // Initialize NVML
    CHECK_NVML(nvmlInit());

    // Get NVML device handle for current device
    nvmlDevice_t device;
    CHECK_NVML(nvmlDeviceGetHandleByIndex(local_id, &device));

    // Get UUID
    char uuid[NVML_DEVICE_UUID_BUFFER_SIZE];
    CHECK_NVML(nvmlDeviceGetUUID(device, uuid, NVML_DEVICE_UUID_BUFFER_SIZE));

    // Print only SLURM_LOCALID and UUID
    printf("SLURM_LOCALID=%s, UUID=%s\n", 
           slurm_localid ? slurm_localid : "not set", 
           uuid);

    // Shutdown NVML
    CHECK_NVML(nvmlShutdown());

    return 0;
}
