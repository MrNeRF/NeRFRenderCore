#pragma once

#include <cuda_runtime.h>
#include <tiny-cuda-nn/common.h>

#include "../common.h"
#include "../core/occupancy-grid.cuh"

NRC_NAMESPACE_BEGIN

__global__ void decay_occupancy_grid_values_kernel(
    const uint32_t n_cells_per_level,
    const uint32_t n_levels,
    const float factor,
    float* __restrict__ grid_sigma
);

__global__ void generate_grid_cell_network_sample_points_kernel(
    const uint32_t n_cells,
    const uint32_t batch_size,
    const uint32_t start_idx,
    const OccupancyGrid* grid,
    const int level,
    const float inv_aabb_size,
    const float* __restrict__ random_float,
    float* __restrict__ sample_pos
);

__global__ void update_occupancy_with_density_kernel(
    const uint32_t n_samples,
    const uint32_t start_idx,
    const uint32_t level,
    const float selection_threshold,
    const float decay_factor,
    const float* __restrict__ random_float,
    const tcnn::network_precision_t* __restrict__ network_sigma,
    OccupancyGrid* grid
);

__global__ void update_occupancy_grid_bits_kernel(
    const float threshold,
    OccupancyGrid* grid
);

NRC_NAMESPACE_END
