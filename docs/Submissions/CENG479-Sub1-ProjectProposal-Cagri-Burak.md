

## MAY 2026
## GAZİ UNIVERSITY
## FACULTY OF ENGINEERING
## DEPARTMENT OF COMPUTER ENGINEERING





Burak ÇETİN – 22118080032
Çağrı ÇELİK – 22118080069




## Submission 1 – Project Proposal
Accelerating 2D Image Convolution on GPU: A Performance Study of Memory-
Hierarchy-Aware CUDA Implementations









## CENG479 – PARALLEL  COMPUTER ARCHITECTURES AND
## PROGRAMMING

iv


## CONTENTS

CONTENTS .......................................................................................................................... iv
- PROJECT TITLE AND TEAM MEMBERS .................................................................... 1
- PROBLEM STATEMENT ................................................................................................. 2
- MOTIVATION ................................................................................................................... 3
- PROPOSED PARALLEL ALGORITHM ......................................................................... 4
4.1 Sequential CPU Baseline ............................................................................................. 4
4.2 Naive CUDA Global-Memory Kernel ......................................................................... 4
4.3 Shared-Memory Tiled CUDA Kernel .......................................................................... 5
4.4 Constant-Memory Filter Coefficients .......................................................................... 5
4.5 Separable Convolution for Applicable Filters .............................................................. 5
4.6 Correctness Verification Strategy................................................................................. 6
- SELECTED TECHNOLOGY ........................................................................................... 7
- PERFORMANCE ANALYSIS PLAN .............................................................................. 8
6.1 Workload Parameters ................................................................................................... 8
6.2 Timing Methodology ................................................................................................... 8
6.3 Speedup Calculation .................................................................................................... 9
6.4 GPU Profiling Metrics ................................................................................................. 9
6.5 Expected Performance Improvement ........................................................................... 9
6.6 Scope and Limitations................................................................................................ 10
ACADEMIC REFERENCES .............................................................................................. 11



## 1


## 1. PROJECT TITLE AND TEAM MEMBERS
Project Title: Accelerating  2D  Image  Convolution  on  GPU: A  Performance  Study  of
Memory-Hierarchy-Aware CUDA Implementations
Course: CENG-479 Parallel  Computer Archıtectures And Programmıng
Department: Department of Computer Engineering, Gazi University
## Semester: Spring 2026
## Team Members:
- Çağrı Çelik - Student ID: 22118080069
- Burak Çetin - Student ID: 22118080032
Selected Technology: CUDA
This project will be completed as a two-student team project. The implementation and
analysis will be divided between the team members.



## 2


## 2. PROBLEM STATEMENT
Two-dimensional image convolution is one of the most common computational operations
in image processing, computer vision, and deep learning. It is used in Gaussian blur, Sobel
edge detection, sharpening, denoising, feature extraction, and convolutional layers of neural
networks. Although the mathematical operation is simple, applying convolution to high-
resolution  images  becomes  computationally  expensive  because  every  output  pixel  is
computed from a neighborhood of input pixels and a filter mask. For large images and larger
filters, the number of multiply-accumulate operations increases rapidly (Perrot et al., 2016).
Given an input image I of size H×W and a convolution filter K of size (2r+1)×(2r+1), the
output image O is computed as:
## 푂
## (
## 푖,푗
## )
## =∑∑퐾
## (
## 푎,푏
## )
## 푟
## 푏=−푟
## 푟
## 푎=−푟
## ⋅퐼
## (
## 푖+푎,푗+푏
## )

Each output pixel requires
## (
## 2푟+1
## )
## 2
multiply-accumulate operations. For example, a 3×3
filter requires 9 operations per output pixel, a 7×7 filter requires 49 operations, and an 11×11
filter requires 121 operations. When these filters are applied to high-resolution images such
as 2048×2048 or 4096×4096, the total operation count becomes very large. Therefore,
sequential execution on a CPU can become a performance bottleneck, especially when
multiple filters are applied in an image-processing pipeline (Perrot et al., 2016).
The main challenge is not only the number of arithmetic operations but also the memory
access pattern. Neighboring output pixels use overlapping regions of the input image. In a
naive implementation, the same input pixels may be loaded repeatedly from global memory
by different threads. Previous studies show that convolution on GPUs is often memory-
bandwidth-bound  rather  than  purely  compute-bound.  Therefore,  the  key  performance
problem is how to reduce redundant memory traffic and increase data reuse through the GPU
memory hierarchy (Iandola et al., 2013).
The problem addressed in this project is: How can 2D image convolution be accelerated
using CUDA, and how much performance improvement can be obtained by progressively
applying GPU memory-hierarchy optimizations compared with a sequential CPU baseline?


## 3


## 3. MOTIVATION
This  problem  genuinely  benefits  from  parallelization  because  each  output  pixel  of  a
convolution operation can be computed independently. The computation of O(i,j) does not
require the result of another output pixel. This means that thousands or millions of output
pixels can be assigned to different GPU threads. Since GPUs are designed for large-scale
data-parallel workloads, this pixel-level independence makes 2D convolution a suitable
problem for CUDA-based acceleration (Van Werkhoven et al., 2014).
Another motivation is that convolution has a regular and predictable memory access pattern.
Unlike  graph  algorithms  or  irregular  data  structures,  convolution  accesses  a  local
neighborhood around each pixel. This regularity makes it suitable for memory optimization
techniques  such  as  coalesced  global  memory  access,  shared-memory  tiling,  constant
memory  for  filter  coefficients,  and  separable  convolution  for  suitable  filters.  These
optimizations are important because the performance of convolution is strongly affected by
how efficiently input pixels and filter values are reused (Van Werkhoven et al., 2014).
The problem is also important in real-world systems. Image filtering operations are used in
many  applications  such  as  medical  imaging,  autonomous  systems,  surveillance,  video
processing,  mobile  camera  pipelines,  and  deep  learning  inference.  In  such  systems,
convolution is often not a single isolated operation; it is usually one stage in a larger
processing pipeline. Therefore, improving the execution time of convolution can reduce the
runtime of the overall image-processing workflow (Allusse et al., 2008).
The project is also suitable for a parallel programming course because it allows a clear
comparison between sequential and parallel execution. A sequential CPU implementation
can be used as the baseline, while multiple CUDA implementations can be compared against
it.  This  makes  it  possible  to  measure  not  only  whether  GPU  parallelism  improves
performance, but also how different CUDA memory strategies affect speedup (Lu et al.,
## 2020).


## 4


## 4. PROPOSED PARALLEL ALGORITHM
The project will implement and compare several versions of the same 2D convolution
operation. All versions will produce the same output image for the same input image and
filter,  allowing  a  fair  comparison  of  execution  time  and  speedup.  The  planned
implementations are: sequential CPU baseline, naive CUDA global-memory kernel, shared-
memory tiled CUDA kernel, constant-memory filter optimization, and separable convolution
for applicable filters (Van Werkhoven et al., 2014).
4.1 Sequential CPU Baseline
The first implementation will be a sequential CPU version written in C/C++. It will use
nested loops over image rows, image columns, and filter coefficients. This implementation
will serve two purposes. First, it will provide the baseline execution time for speedup
calculations. Second, it will provide the reference output for correctness verification of the
CUDA implementations.
The CPU baseline will use the same border-handling strategy as the GPU versions. The
planned approach is zero-padding or halo-based boundary handling. This ensures that output
pixels near the image boundary are computed consistently across all implementations. The
CPU code will be compiled with standard optimization flags such as -O3, but it will remain
single-threaded so that the comparison clearly reflects the improvement obtained by CUDA-
based parallelization.
4.2 Naive CUDA Global-Memory Kernel
The first CUDA version will assign one CUDA thread to one output pixel. Each thread will
compute the convolution result for its assigned pixel by reading the required input pixels and
filter coefficients directly from global memory. The thread will then write the computed
value to the output image.
This version is expected to be faster than the sequential CPU version because many output
pixels will be computed in parallel. However, it is also expected to be inefficient compared
with  optimized  CUDA  versions  because  neighboring  threads  will  repeatedly read
overlapping input pixels from global memory. Since global memory access has high latency
and limited bandwidth compared with on-chip memory, this implementation will likely be
limited by memory traffic (Iandola et al., 2013).


## 5


4.3 Shared-Memory Tiled CUDA Kernel
The second CUDA version will use shared-memory tiling. In this approach, each thread
block will process a tile of the output image. Before computing the output pixels, the threads
in the block will cooperatively load the required input tile into shared memory. This tile will
include  the  central  region  and  the  halo  pixels  needed  for  the  convolution  filter. After
synchronization, each thread will compute its output pixel using data from shared memory
instead of repeatedly accessing global memory.
This implementation aims to reduce redundant global memory reads. Since adjacent output
pixels share most of their input neighborhood, loading the required tile once into shared
memory allows multiple threads to reuse the same input values. This is expected to improve
performance especially for larger filters, where the amount of overlapping input data is
higher (Van Werkhoven et al., 2014).
4.4 Constant-Memory Filter Coefficients
The third CUDA version will store filter coefficients in CUDA constant memory. The
convolution filter is usually small, read-only, and accessed by all threads. These properties
make it suitable for constant memory. If many threads access the same filter coefficient at
the same time, constant memory can provide efficient broadcast behavior.
This optimization will be combined with the shared-memory tiled implementation. In this
version, input image tiles will be reused through shared memory, while filter coefficients
will be accessed through constant memory. The goal is to measure whether constant memory
provides additional improvement over the shared-memory version, especially for commonly
used filter sizes such as 3×3, 5×5, 7×7, and 11×11 (Van Werkhoven et al., 2014).
4.5 Separable Convolution for Applicable Filters
Some filters are mathematically separable. For example, Gaussian blur and box blur can be
decomposed into a horizontal 1D convolution followed by a vertical 1D convolution. In this
case, a direct k×k convolution can be replaced with two k-element 1D convolutions. This
reduces the per-pixel arithmetic cost from k
## 2
to 2k.
For example, an 11×11 direct convolution requires 121 filter operations per pixel, while
separable  convolution  requires  only  22  operations  per  pixel.  Therefore,  separable
convolution can provide a large performance improvement when the filter supports this
decomposition. However, this optimization will only be applied to suitable filters. It will not

## 6


be used for every filter type because not all convolution filters are separable (Van Werkhoven
et al., 2014).
## 4.6 Correctness Verification Strategy
All CUDA outputs will be compared against the sequential CPU baseline. Since floating-
point  operations  can  produce  small  numerical  differences  depending  on  hardware  and
operation order, the comparison will use an error tolerance such as 10
## −5
or 10
## −4
. The project
will calculate maximum absolute error and mean absolute error between the CPU output and
each GPU output.
A CUDA implementation will only be included in the performance results if it passes
correctness  verification.  This  is  especially  important  for  tiled  shared-memory
implementations  because  indexing  mistakes  in  halo  loading,  boundary  handling,  or
synchronization can create errors near tile boundaries. Correctness will be tested for every
image size, filter size, and kernel version.



## 7


## 5. SELECTED TECHNOLOGY
The selected technology for this project is CUDA, which is one of the allowed technologies
for the CENG-479 project. CUDA is the most appropriate choice because the problem is
highly  data-parallel  and  maps  naturally  to  GPU  execution.  Each  output  pixel  can be
computed by an independent GPU thread, and CUDA provides direct control over GPU
memory spaces such as global memory, shared memory, constant memory, and registers
(Iandola et al., 2013).
Compared  with  Java  Threads  and  POSIX  Threads,  CUDA  provides  a  more  suitable
execution  model  for  this  problem.  Java  Threads  and  POSIX  Threads  are  CPU-based
approaches and are limited by the number of CPU cores and CPU memory bandwidth. They
can improve performance compared with a sequential CPU version, but they cannot exploit
the thousands of lightweight threads and high memory bandwidth available on modern
NVIDIA  GPUs.  Since  convolution  over  large  images  exposes  massive  pixel-level
parallelism, CUDA is expected to provide a stronger performance improvement (Allusse et
al., 2008).
CUDA  is  also  suitable  because  the  project  focuses  on  memory-hierarchy-aware
optimization. The planned implementation requires explicit use of shared memory for input
tile reuse and constant memory for filter coefficients. These memory spaces are directly
programmable in CUDA. This makes CUDA not only an acceleration tool but also an
educationally appropriate platform for studying how memory hierarchy affects parallel
performance (Van Werkhoven et al., 2014).
The project will be developed using C/C++ and CUDA Toolkit. The experiments will be
performed on an NVIDIA GPU, preferably an RTX 4070 if available. If development is
performed on a GTX 1650, the same methodology will still be valid, although the absolute
speedup values may be lower. CUDA events will be used for kernel timing, and NVIDIA
profiling  tools  such  as  Nsight  Compute  may  be  used  to  inspect  memory  throughput,
occupancy, and warp execution behavior.



## 8


## 6. PERFORMANCE ANALYSIS PLAN
The performance analysis will compare the sequential CPU baseline with each CUDA
implementation. The main goal is to measure how much speedup is obtained from GPU
parallelization and how each memory optimization changes performance. The project will
report both kernel-only execution time and end-to-end execution time including host-to-
device and device-to-host memory transfers. This distinction is important because GPU
kernels may be fast, but memory transfer overhead can reduce the total application-level
benefit (Allusse et al., 2008).
## 6.1 Workload Parameters
The experiments will use multiple image sizes and filter sizes. Planned image sizes are:
## • 512×512
## • 1024×1024
## • 2048×2048
## • 4096×4096
Planned filter sizes are:
## • 3×3
## • 5×5
## • 7×7
## • 11×11
These values are selected to show how performance changes as the workload increases.
Smaller images may show limited GPU benefit because memory transfer and kernel launch
overhead can dominate execution time. Larger images are expected to benefit more from
GPU parallelization because they provide more work for GPU threads. Larger filters are also
expected to make memory reuse more important because neighboring output pixels share
more input data (Jorda et al., 2019).
## 6.2 Timing Methodology
For the CPU baseline, execution time will be measured using a high-resolution CPU timer.
For CUDA implementations, kernel-only time will be measured using CUDA events. End-
to-end time will be measured separately by including memory allocation, host-to-device
transfer, kernel execution, and device-to-host transfer.

## 9


Each experiment will be repeated multiple times, and the average execution time will be
reported. A warm-up run will be executed before actual timing to reduce initialization effects.
If timing variation is significant, standard deviation may also be reported.
## 6.3 Speedup Calculation
Speedup will be calculated using the following formula:
## 푆푝푒푒푑푢푝=
## 푇
## 퐶푃푈
## 푇
## 퐺푃푈

where T
## CPU
is the execution time of the sequential CPU baseline and T
## GPU
is the execution
time of the CUDA implementation. Two speedup values will be reported:
- Kernel-only speedup: CPU time divided by CUDA kernel execution time.
- End-to-end speedup: CPU time divided by total GPU execution time including
memory transfers.
This  distinction  will  make  the  analysis  more  realistic.  Kernel-only  speedup  shows  the
computational advantage of CUDA, while end-to-end speedup shows the practical benefit
when data transfer overhead is included (Allusse et al., 2008).
6.4 GPU Profiling Metrics
If profiling tools are available, the project will collect selected GPU metrics. These may
include:
- Global memory throughput
- Shared memory usage
- Achieved occupancy
- Warp execution efficiency
- Kernel execution time
- Memory load/store efficiency
These metrics will help explain the measured performance results. For example, if the naive
CUDA version is slower than expected, profiling may show excessive  global memory
transactions. If the shared-memory version improves performance, profiling may show
reduced global memory traffic and better data reuse (Lu et al., 2020).
## 6.5 Expected Performance Improvement
The sequential CPU implementation is expected to be the slowest version for large images
and larger filters. The naive CUDA kernel is expected to provide a clear speedup over the

## 10


CPU  baseline  because  many  output  pixels  are  computed  in  parallel.  However,  its
performance will likely be limited by redundant global memory reads.
The shared-memory tiled kernel is expected to improve performance over the naive CUDA
version by reducing redundant global memory access. The constant-memory version may
provide an additional improvement because filter coefficients are read-only and repeatedly
accessed by all threads. The separable convolution version is expected to provide the largest
improvement for suitable filters such as Gaussian blur because it reduces the number of
operations from k
## 2
to 2k per pixel (Van Werkhoven et al., 2014).
The expected performance trend of the proposed implementations is summarized in Table
## 6.5.1.
Table 6.5.1. Expected performance trend of proposed implementations
## Implementation Expected Result
Sequential CPU Correct but slow for large images
Naive CUDA global memory Faster than CPU, but memory-inefficient
Shared-memory tiled CUDA Faster than naive CUDA for medium/large filters
Shared memory + constant
memory
Additional improvement for repeated filter access
Separable convolution Strong improvement for suitable filters such as Gaussian
blur
The exact speedup values will depend on GPU model, CPU model, compiler options, image
size, filter size, and whether memory transfer time is included. Therefore, the project will
avoid presenting speedup as a fixed universal value. Instead, it will report measured speedup
values for the actual experimental setup.
6.6 Scope and Limitations
The project will focus on direct spatial-domain 2D convolution and selected CUDA memory
optimizations. It will not attempt to reproduce industrial-level libraries such as cuDNN,
OpenCV  CUDA,  or  NVIDIA  NPP.  These  libraries  include  many  architecture-specific
optimizations and are outside the scope of this course project.
The core implementation will focus on grayscale images. RGB image support may be added
if time permits, but it is not required for the main performance comparison. Advanced
methods  such  as  FFT-based  convolution,  Winograd  convolution,  full  auto-tuning,  and
register-only packet convolution will be discussed as related work but will not be fully
implemented. This scope keeps the project realistic while still allowing meaningful analysis
of parallelism and memory hierarchy (Perrot et al., 2016).


## 11


## ACADEMIC REFERENCES
Allusse, Y.,  Horain,  P., Agarwal, A.,  & Saipriyadarshan,  C.  (2008).  GpuCV: A  GPU-
accelerated framework for image processing and computer vision. Lecture Notes in
Computer Science (Including Subseries Lecture Notes in Artificial Intelligence and
Lecture   Notes   in   Bioinformatics), 5359   LNCS(PART   2),   430–439.
https://doi.org/10.1007/978-3-540-89646-3_42
Iandola, F. N., Sheffield, D., Anderson, M. J., Phothilimthana, P. M., & Keutzer, K. (2013).
Communication-minimizing  2D  convolution  in  GPU  registers. 2013  IEEE
International   Conference   on   Image   Processing   (ICIP),   2116–2120.
https://doi.org/10.1109/ICIP.2013.6738436
Jorda,  M.,  Valero-Lara,  P.,  &  Pena, A.  J.  (2019).  Performance  Evaluation  of  cuDNN
Convolution Algorithms  on  NVIDIA Volta  GPUs. IEEE Access, 7,  70461–70473.
https://doi.org/10.1109/ACCESS.2019.2918851
Lu,  G.,  Zhang,  W.,  &  Wang,  Z.  (2020).  Optimizing  GPU  Memory  Transactions  for
Convolution Operations. 2020 IEEE International Conference on Cluster Computing
(CLUSTER), 399–403. https://doi.org/10.1109/CLUSTER49012.2020.00050
Perrot, G., Domas, S., & Couturier, R. (2016). An optimized GPU-based 2D convolution
implementation. Concurrency  and  Computation:  Practice  and  Experience, 28(16),
4291–4304. https://doi.org/10.1002/cpe.3752
Van Werkhoven, B., Maassen, J., Bal, H. E., & Seinstra, F. J. (2014). Optimizing convolution
operations on GPUs using adaptive tiling. Future Generation Computer Systems, 30(1),
14–26. https://doi.org/10.1016/j.future.2013.09.003
