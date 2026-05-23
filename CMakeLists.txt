cmake_minimum_required(VERSION 3.18)

project(cuda_2d_convolution_optimization LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

add_executable(convolution_benchmark
    src/main.cu
    src/convolution_cpu.cpp
    src/convolution_cuda.cu
    src/filters.cpp
    src/image_io.cpp
    src/benchmark.cpp
)

target_include_directories(convolution_benchmark PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
)

set_target_properties(convolution_benchmark PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
)

if(MSVC)
    target_compile_options(convolution_benchmark PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:/O2>
        $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/O2>
    )
else()
    target_compile_options(convolution_benchmark PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:-O3>
        $<$<COMPILE_LANGUAGE:CUDA>:-O3>
    )
endif()
