

## SPECIAL ISSUE PAPER
An extended analysis of memory hierarchies for efficient
implementations of image processing applications
## Christian Hartmann
## 1
## •
## Dietmar Fey
## 1
Received: 29 September 2016 / Accepted: 19 September 2017 / Published online: 27 September 2017
Springer-Verlag GmbH Germany 2017
AbstractThrough continued miniaturization of electronic
devices  embedded  smart  cameras  are  steadily  becoming
more and more important. The reduction of the camera size
increases the spectrum of applications. In industrial appli-
cations  the  range  of  smart  cameras  spans  from  quality
monitoring  and  position  tracking  to  the  calibration  of
production  machines.  In  non-professional  applications  a
distinct  boom  in  action  cameras  combined  with  fused
sensor information can be observed. However, all of these
applications   have   a   common   bottleneck:   the   memory
architecture.   Most   image   processing   applications   are
memory-bound tasks. Thus, the amount of time for trans-
ferring data with image processing applications decisively
affects  the  application’s  entire  processing  time.  Different
memory  access  patterns  require  different  memory  config-
urations and hierarchies. An insufficient match between the
image processing application and the memory architecture
leads  to a poor performance in the image processing sys-
tem.  This  can  lead  to  longer  processing  times,  and  larger
energy   consumption   rates.   This   work   introduces   new
methods  of  classifying  image  processing  applications  by
using their memory access pattern for mapping on memory
architectures. Our work combines a simulation framework
the   heterogenous   memory   simulator   with   a   analytical
framework the memory analyzer to find bottlenecks inside
the  image  processing  application  and  aids  in  finding  a
suitable,   application-specific   memory   configuration   in
terms of processing time and energy consumption.
KeywordsImage processingMemoryCacheEnergy
analysisPerformance analysisData locality
## 1 Introduction
Computer   pioneers   correctly   predicted   that   memory
architectures  will  become  a  bottleneck  in  system  archi-
tecture.  In  the  image  processing  domain  the  insatiable
pursuit of fast memory has only been furthered due to the
increase  in  complexity  of  image  processing  applications
driven  by  progress  in  the  miniaturization  of  microelec-
tronic systems. Smart phones or automotive assistant sys-
tems   are   merely   two   examples   of   applications   with
increased processing data and complexity. Camera systems
in smart phones have attained resolutions up to 21 mega-
pixels and are able to detect a human face. Such an amount
of  data  demands  a  system  architecture  with  fast  memory
for its processing needs. One economical solution would be
an   application-specific   memory   hierarchy,   which   takes
advantage  of  application-specific  features.  One  common
feature  is  the  locality  of  the  memory  access.  Locality
means  that  only  a  limited  number  of  data  close  to  each
other  are  accessed  for  a  single  processing  step.  Most
algorithms do not need all the data from an entire frame at
the same time. Efficient memory architectures exploit this
case,  and  examples  can  be  found  in  [2,  21].  In  contrast
many solutions in the image processing domain use inflated
memory structures from standard PCs, such as Intel Core i7
[14], for their image processing applications. These mem-
ory architectures are often inefficient in terms of area and
energy   consumption   rates,   in   particular   for   embedded
&Christian Hartmann
christian.hartmann@fau.de
## Dietmar Fey
dietmar.fey@fau.de
## 1
Chair of Computer Architecture, University of Erlangen-
## Nuremberg, Martensstr. 3, 91058 Erlangen, Germany
## 123
J Real-Time Image Proc (2018) 14:713–728
https://doi.org/10.1007/s11554-017-0723-2

architectures.  In  order  to  find  an  efficient  cache  memory
structure  in  one  level,  e.g.,  sizes  of  caches  and  cache,
degree  of  associativity  and  the  cache  hierarchy  organiza-
tion in the context of the address access patterns in image
processing  applications,  an  analysis  and  classification  of
image  processing  algorithms  is  required.  Therefore,  an
analysis  and  simulation  framework  was  created.  In  this
work  we  introduce  a  memory  simulation  and  analysis
framework for image processing applications. It consists of
two  tools,  MemAn  and  HMSim.  HMSim  is  a  simulation
tool  based  on  the  Open  Virtual  Platform  (OVP)  [13]  and
written  in  SystemC.  It  includes  various  virtual  memory
components,  with  varying  structures,  configurations  and
sizes.  The  simulation  is  used  to  estimate  the  processing
time,  and  energy  consumption  rates  for  an  image  pro-
cessing  application  with  a  specific  cache  structure  and
cache hierarchy. MemAn is an analysis tool combined with
a  database,  the  tool  works  on  empirical  data  which  are
stored  in  the  database.  The  empirical  data  have  a  basic
volume  by  the  first  use  of  MemAn/HMSim,  the  volume
will  be  increased  with  the  output  of  HMSim.  MemAn
implements a corresponding time and energy model on the
basis  of  the  empirical  data.  The  tool  is  written  in Mathe-
matica  [15]  and  enables  the  user  to  estimate  the  energy
consumption  and  the  processing  time  of  an  image  pro-
cessing  application  without  carrying  out  time-intensive
simulations. With MemAn/HMSim developers will be able
to localize bottlenecks in image processing applications in
terms  of access time  and  energy  consumption.  Thus,  sys-
tem designers are able to create more efficient systems by
simulating  and  analyzing  memory  access  patterns.  The
framework assists in the design of efficient memory hier-
archies.   That   means   efficiency   regarding   energy   con-
sumption and processing time. This enables the prediction
of  the  overall  processing  time  of  an  image  processing
application  and  the  assistance  in  the  design  of  real-time
image processing systems.
This  paper  is  organized  as  follows.  Section2provides
an overview of the current state of research on this topic.
The energy database will be introduced in Sect.3. Subse-
quently,  memory  technologies  and  the  framework  tool
HMSim   are   introduced   in   Sect.4.   The   definition   of
MemAn  can  be  found  in  Sect.5.  In  Sect.5.1a  brief
introduction to the image processing domain and its algo-
rithms  will  be  given.  In  Sect.6the  user  interface  is  dis-
cussed.  Results  of  the  MemAn/HMSim  work-flow  and
examples  the  underlying  methodology  of  the  framework
are discussed in Sect.7. Examples in this section illustrate
the underlying methodology of MemAn/HMSim. Lastly, a
conclusion and outlook for future work are provided in the
final sections.
2 Related work
The literature differs two approaches to estimate the non-
functional  properties  of  an  image  processing  system.  The
first  approach  is  based  on  analytical  models  without  any
simulation. The second approach found in the literature is
simulation  based  and  allows  also  to  test  the  functional
properties.
## 2.1 Analytical
A representative of the analytical approaches is the work of
[17].  It  determines  the  cache  hit  and  miss  behavior  for
GPUs  by  using  the  reuse  distance.  It  is  an  interesting
approach   and   can   be   transferred   to   CPUs.   However,
specifically  in  [17]  concrete  hardware  is  needed  for  mea-
suring the instruction trace. Furthermore, the extension of
non-functional   properties,   e.g.,   energy   consumption,   is
lacking. The work of [18] and [22] determines the cache hit
and  miss  rate  by  using  the  reuse  distances  of  memory
accesses  of the  same address.  If  the  reuse distance grows
higher  than  the  cache  set,  the  data  of  the  address  will  be
replaced. The reuse distance mentioned in the work of [18]
is  a  good  foundation  for  Sect.4.2.  These  two  approaches
lack  in  not  having  an  estimation  of  non-functional  prop-
erties such as processing time and energy consumption.
2.2 Simulation-based approaches
Simulation-based approaches for hardware emulation exist.
One  representative  is  the  gem5  [3]  environment  with  its
memory  model.  Unfortunately,  the  gem5  memory  model
lacks sufficient detail for reflecting to a realistic behavior of
a  memory  architecture.  The  work  of  [11]  includes  an
energy estimation method. The model is used for an energy
estimation  by  running  HEVC  encoded  videos  on  Leon3
Sparc  architectures.  Every  arithmetic  instruction  has  an
energy value and all instruction values will be summarized
for the overall energy consumption. The problem with this
approach  is  that  it  lacks  by  not  covering  the  memory
architecture.  A  realistic  system  evaluation  for  image  pro-
cessing  applications is not sufficient enough  without con-
sidering  a  realistic  memory  hierarchy.  The  work  of  [11]
can  only  be  used  as  an  extension  in  order  to  combine  it
with a memory model. A further interesting approach is the
Preesm  framework  introduced  in  [19],  which  optimizes
image processing applications for digital signal processors
from  Texas  Instruments  by  addressing  memory  and  bus
delays.  However,  there  are  no  energy  consumption  rate
estimations.
In  [10]  a  combination   of  simulation  and  analytical
approaches  can  be  found.  However,  a  cache  model  for  a
714J Real-Time Image Proc (2018) 14:713–728
## 123

realistic   system   evaluation   is   also   lacking.   This   work
considered the advantages of both approaches for creating
an analysis and simulation framework for image processing
applications in terms of energy and timing estimations. In
contrast  to  related  work  an  estimation  of  processing  time
and energy consumption of every image processing appli-
cation can be given based on the memory access behavior.
3 Concepts for the data acquisition
This  section  introduces  the  data  acquisition  of  processing
time and energy consumption of a single memory access.
In  order  to  estimate  the  energy  consumption  for  image
processing  applications  Cacti  [12],  DRAMSys  [16]  and  a
custom-created  database  was  created.  Figure9shows  the
combination  of  the  HMSim/MemAn  framework  and  the
data   acquisition   database   and   tools.   In   the   following
methods will be explained to get information of the energy
consumption of a real memory access.
3.1 Cacti and DRAMSys
These  tools  are  included  in  our  framework  and  provide
estimations   of   energy   consumption   rates   for   different
memory technologies. Cacti and DRAMsys are used for the
energy consumption estimation of single memory accesses.
DRAMSys  is  used  for  access  time  and  energy  estimation
on  DRAM  technologies  and  Cacti  for  cache  accesses.
Table1shows  the  timing  results  from  Cacti  for  varying
degrees of cache associativity and sizes.
The  data  shown  in  Table1stem  from  Cacti  with  an
assumed  32 nm  SRAM  technology  and  show  the  access
time of a single write access in nanoseconds. It can be seen
that  a  greater  cache  size  and  associativity  leads  to  longer
access times. However, depending on the image processing
application higher cache sizes and associativity can lead to
lowering the processing time of the whole application. Due
to  the  reduction  of  costly  external  memory  accesses  the
total  access  time  can  be  reduced  in  some  cases.  This
application-specific  assumption  can  not  be  provided  by
Cacti or DRAMsys. For that case Cacti and DRAMsys are
included in the novel framework MemAn/HMSim.
3.2 Custom measurements
To  extend  the  range  of  hardware  architectures  toward  to
technologies  lower  than  32 nm  custom  measurements  are
necessary.  The  measurements  for  the  ARM  Cortex  A9,
ARM Cortex A53 and ARM Cortex A57 architecture were
taken. By means of CPU integrated performance counters
the access time was measured. For the energy consumption
the performance counter were used to determine the hit and
miss  rate  of  an  application.  To  weight  the  energy  of  a
single  hit  or  miss  the  Zimmer  precision  power  analyzer
LMG640 [23] was used.
The  Zimmer  has  a  resolution  of  0.015  %  of  the  mea-
sured input value. Figure1shows the test setup for energy
measurements.  By  measuring  the  difference  between  idle
state and benchmark processes and using the performance
counter  to  detect  the  cache  hit  and  miss  rate,  the  energy
consumption of a single cache access can be classified and
determined.
4 Memory simulation framework HMSim
In this section the memory simulation framework HMSim
will  be  introduced.  HMSim  stands  for  ‘‘Heterogeneous
Memory Simulator’’. The memory simulation environment
HMSim  gives  developers  the  chance  to  test  the  function-
ality of their image processing application, to estimate the
access time and the energy consumption of the application
with different memory architectures. This section is orga-
nized  as  following.  Section4.1gives  a  brief  overview  of
the memory technologies. Section4.2introduces the reuse
distance    theory.    Section4.3introduces    the    HMSim
framework,  and  some  alternatives  for  test  pattern  genera-
tion are shown in Sect.4.4.
4.1 Memory technologies
In  order  to  determine  energy  consumption  as  accurate  as
possible   three   primary   memory   technologies   must   be
considered,   the   SRAM,   the   eDRAM   and   the   DRAM
technology. The first two technologies are used for caches,
the last is used for external RAM. All three are shown in
Fig.2. Every technology has individual characteristics and
Table 1Access time
Cache 2-way (ns)Cache 4-way (ns)Cache 8-way (ns)
Size 16 KB141415
Size 32 KB141516
Size 64 KB161718
Size 128 KB181920
Size 256 KB192022
J Real-Time Image Proc (2018) 14:713–728715
## 123

contributes another amount of energy consumption what is
considered  in  the  single  access  measurements.  The  cache
hit  and  miss  rates  are  derived  in  dependence  of  the  pixel
access patterns in our input and output images.
To increase the performance of an application, required
data  must  be  kept  at  the  high  memory  levels  as  long  as
possible. Therefore, it is  valuable to investigate  the influ-
ence of different replacement strategies and cache config-
urations.   HMSim   enables   the   consideration   of   these
influences. The calculation of cache hits and misses will be
introduced in the next subsection.
4.2 Reuse distance theory
HMSim  uses  the  reuse  distance  theory  for  cache  hit/miss
prediction.  Therefore,  a  brief  overview  of  the  reuse  dis-
tance theory is given in this subsection. In [5,6] the reuse
distance is defined as the number of distinct memory ref-
erences between itself and its reuse. When an initial access
occurs  at  a  specific  address  the  reuse  distance  is  set  to
infinity  (1).  An  example  is  illustrated  in  Table2.Itisa
fully  associative  cache  with  a  least  recently  used  (LRU)
replacement strategy.
Redundant  accesses  within  a  reuse  distance  of  another
reference does not count in the reuse distance. This should
be  self-evident  because  the  same  data  are  loaded  once  in
the  cache  an  does  not  occupy  additional  storage  cells.
Redundant storage is excluded. This behavior is shown by
the secondx[1] access. It has a reuse distance of 2 and not
3, since the reference ofx[5] occurs twice. Table3shows
and  extended  example  with  various  cache  types. The dif-
ferent  caches  are  a  2-way,  4-way  and  8-way  associative,
with  a  64-byte  cache  size  and  one-byte  block  size.  The
replacement policy is least recently used (LRU).
Every memory reference with a reuse distance less than
the associativity has the correct data in the cache and does
not need an external memory access. Every reuse distance
equal  or  greater  than  the  cache  associativity  needs  an
external  memory  access.  In  Table3the1and  bold-
marked  reuse  distances  must  be  loaded  externally.  The
example  shows  that  a  higher  associativity  can  lead  to  a
reduction in external memory accesses.
4.3 Memory simulation framework (HMSim)
The  memory  simulation  framework  is  a  OVP/SystemC-
based  simulation  environment.  It  includes  a  functional
simulation   and   uses   the   reuse   distance   theory   from
Sect.4.2to determine  the  cache  hits  and  misses.  A  com-
bination with the tool Cacti developed by HP [12], custom
measurements and DRAMsys [16] provides estimations of
non-functional properties such as energy consumption and
memory  access  time.  The  access  time  and  energy  con-
sumption  depend  on  the  technology  (SRAM,  eDRAM,
DRAM),  the  structure  size,  the  capacity,  the  number  of
banks, the block size and the associativity. All these data
are required as input for HMSim to estimate the energy and
time consumption for a single memory access. A configu-
ration file, written in XML, contains all these attributes and
is  used  for  the  custom  memory  configuration.  Figure3
illustrates   the   design   of   the   simulation   environment
HMSim.
As illustrated HMSim is based on the simulation envi-
ronment  OVP  [13].  For  the  estimation  of  the  non-func-
tional    properties    such    as    energy    consumption    and
processing time a generic SystemC based virtual memory
extension was created. This extension is connected by the
standard  OVP  interface,  the  intercept  library,  to  the  OVP
simulator.  On  HMSim  an  application  is  able  to  run  on
Fig. 1Energy  measurement  setup  with  the  Zimmer  LMG640  [23]
and the Digilent Zedboard with a Zynq 7020 [1]
Fig. 2Memory technologies
Table 2Reuse distance example
## Accessx[0]x[1]x[5]x[6]x[5]x[1]x[1]
Mem address0156511
Reuse distance1111120
716J Real-Time Image Proc (2018) 14:713–728
## 123

OVP.  OVP   is  an  instruction  accurate  simulator.  OVP
enables an instruction tracing by using the intercept inter-
face.  That  means  all  instructions  of  an  application  under
test will be decoded. Every load and store instruction will
be   detected   with   their   source   and   target   address   and
delivered to the virtual memory extension. Combined with
the  functional  memory  model,  written  in  SystemC,  the
access time and energy consumption can be estimated for
any  image  processing  application.  In  contrast  of  testing
application  code  written  in  C  HMSim  provides  a  second
option   for   the   simulation.   This   will   be   introduced   in
Sect.4.4. But not only the non-functional properties can be
estimated. The HMSim Framework provides the option to
show  the  content  of  the  memory.  Therefore,  the  XML-
based  configuration  file  is  used  to  specify  the  memory
space  and  the  options  of  representation.  Every  in  and
output  of  a  specific  memory  space  will  be  detected  and
shown  in a  signal  waveform and assigned  to a part  of an
image  processing  application.  An  example  is  shown  in
## Fig.4.
An  image  processing  application  is  shown  with  two
different   image  processing  algorithms,  the   Sobel  edge
detection and the Hough circle detection. A component of
the simulation environment called virtual sensor is used to
provide input data to the application. There are two ways
the  first  way  is  to  use  the  virtual  sensor  as  a  OVP  bus
component  which  transfers  time  dependent  data  to  the
Table 3Reuse distance example with cache
## Accessx[0]x[1]x[5]x[65]x[37]x[33]x[129]x[257]x[6]x[38]x[70]x[6]x[0]x[1]x[5]
Mem address015653733129257638706015
## Set 2-way
Cache set0151  5  1  11    66  6  6015
Reuse distance1111 1 1 1 1 11 12041
## Set 4-way
Cache set0151  5  1  11    66  6  6015
Reuse distance1111 1 1 1 1 11 12041
Set 8-way associativity
Cache set0151  5  1  11    66  6  6015
Reuse distance1111 1 1 1 1 11 12041
Fig. 3Design of the simulation environment HMSim
Fig. 4Simulation environment
J Real-Time Image Proc (2018) 14:713–728717
## 123

system. The second option is to initialize the memory with
input  images.  The  component  Noise  Gen  provides  the
option  to  create  a  realistic  test  environment  by  including
disturbances  inside  the  sensor  signal.  In  the  component
Monitor   all   signals,   memory   accesses,   the   functional
behavior  and  the  estimation  of  non-functional  properties
can  be  observed.  Any  image  processing  application  and
memory access pattern can be simulated and monitored by
the  simulation  environment.  Also  memory  snapshots  and
memory heat maps can be created by HMSim. Depending
on the user’s interest, the heat map output can be config-
ured  for  different  outputs,  e.g.,  a  heat  map  with  cache
misses only. Figure5shows an example of a heat map for a
directly   mapped,   2-way,   4-way   and   8-way   associative
cache.
The  blue  blocks  show  read/write  access  attempts.  The
brighter  cells  have  a  greater  number  of  read/write  access
attempts.  In  the  heat  map  with  a  directly  mapped  cache
configuration,  only  the  cell  at  address  9  has  two  separate
instances of access. If the data are from different locations
in  the  external  memory  a  replacement  occurs.  Such  an
illustration  can  be  used  for  finding  bottlenecks  or  weak-
nesses  inside  the  memory  configuration.  An  image  pro-
cessing   application   can   be   tested   on   several   memory
architectures  to  find  a  suitable  configuration.  Also  the
temporal dependency of cache access, hits and misses can
be   created   by   using   the   simulation   tool   HMSim.   A
chronology of the processing time and energy consumption
can be illustrated in Fig.6. It is an example of a timeline
for   memory-energy   consumption   of   the   Hough   image
processing  application.  The  energy  consumption  of  the
Hough  algorithm  regarding  its  processing  steps  can  be
observed. At every processing step the energy consumption
decreases, because with more processing steps the hit rate
for every single processing step increases. The variation of
the  time  line  comes  from  the  variation  of  different  input
images.
The timeline resolution on thex-axis can be configured
manually.  The  highest  resolution  is  a  clock  cycle.  In
HMSim’s  timeline  clock  cycles  can  be  grouped  in  a  so-
calledtime group. Thetime groupsmay vary from single
clock cycles to several frames. Figure6shows the timeline
of a Hough algorithm with atime groupequal to the step
distance. The memory size of this example was 512 KB of
directly  mapped  cache  with  a  SRAM  technology  and  a
structure  size  of  32 nm.  The  integration  of  the  timeline
results in the total energy consumption. Varying the cache
configuration  leads  to  an  other  energy  trend,  because  the
energy costs of one cache read/write access depend on the
cache  configuration  and  its  underlying  technology.  Other
effects  of  the  cache  configuration  is  the  influence  on  the
functional behavior and the prevention of external memory
access.  An  example  of  different  cache  configurations  and
their  influence  on  the  functional  behavior  is  shown  in
## Fig.5and Table3.
With HMSim every image processing application can be
tested,  categorized  and  investigated  for  memory  bottle-
necks.  Users  can  test  their  image  processing  application
with  various  memory  hierarchies.  HMSim  simulates  dif-
ferent system configurations and determines the delay and
energy consumption. These results can be used to choose a
suitable memory hierarchy for an image processing appli-
cation in terms of processing time and energy consumption.
4.4 Sensor generated memory pattern
As  an  alternative  to  the  test  with  full  image  processing
applications the user is able to test merely a memory access
pattern  in  the  simulation  environment.  For  that  case  the
Sensor Generated Memory Patternwas  created.  It  allows
image processing applications to be tested before they are
completely   developed.   TheSensor Generated Memory
Patternsimply requires the number of pixel accesses and
the  locality,  the  number  of  steps,  the  step  distance,  the
access frequency each step has and the amount of data for
each single access. Figure7illustrates the memory access
pattern of varying image processing algorithms created by
theSensor Generated Memory Pattern.  Every  figure  rep-
resents the memory access pattern in one processing step of
an image processing algorithm. Figure7illustrates a higher
Fig. 5Memory  heat  map  of  caches:  blue  means  read/write  access;
the brighter the color, the higher the access frequency
Fig. 6Time line of a Hough algorithm. Time group is step distance
718J Real-Time Image Proc (2018) 14:713–728
## 123

access  frequency  with  a  brighter  color  for  one  pixel  ele-
ment. The (x?1) panels show the memory access pattern in
the  subsequent  processing  step.  Figure7a?1  is  the  same
algorithm as Fig.7a, only one processing step later.
Figure7a shows an image processing algorithm with a
high data access frequency, especially in the center of the
memory  access  pattern.  The  colors  illustrate  the  access
frequency in a single pixel. The bright blue points have a
higher  access  frequency  than  the  dark  points.  The  high
spread   shows   a  low   locality  of   the   image   processing
algorithm. The difference between Fig.7a, a?1 illustrates
the  step  distance.  The  algorithm  of  Fig.7b  has  a  lower
locality and a lower access frequency. Figure7c illustrates
an  algorithm  with  a  very  high  locality.  All  three  access
patterns can  be  used  by  HMSim  to test their  behavior  on
different   memory   configurations.   These   three   different
access  patterns  are  chosen  to  represent  global  and  local
operators.  They  are  not  the  result  of  an  concrete  image
processing   algorithm.   Though   the   access   pattern   of   a
concrete  algorithm  can  be  created  by  usingSensor Gen-
erated Memory Pattern.
Figure8shows   the   setup   of   theSensor Generated
Memory Patternin  combination  with  the  memory  hierar-
chies of HMSim.
TheSensor Generated Memory Patternis connected to
the  rest  of  the  Simulation  environment  by  creating  an
assembler  program  for  a  specific  tested  hardware  archi-
tecture.   The   assembly   contains   only   load   and   store
instructions. The order of the load and store instructions is
user defined. TheSensor Generated Memory Patternper-
forms a mapping from the patterns such as shown in Fig.7
to concrete memory addresses.
5 Memory analyzer (MemAn)
The advantage of MemAn is its ability to rapidly estimate
the energy consumption of image processing applications.
In  contrast  to  HMSim,  MemAn  does  not  require  a  time-
consuming  simulation.  It  includes  a  general  classification
of  image  processing  algorithms  in  terms  of  energy  con-
sumption.  A  MemAn  user  does  not  require  a  complete
implementation of the image processing applications; only
a  few  parameters  are  required  and  MemAn  estimates  the
energy  consumption  and  memory  access  time.  The  input
parameters,  which  are  used  for  the  estimation  of  non-
functional properties, shown  in Table4will be explained
in detail in Sect.5.1.
Figure9shows  the  connection  between  MemAn  and
HMSim.  It  provides  an  overview  how  the  two  tools  are
coupled.
Similar to the data acquisition of Sect.3, HMSim pro-
vides data of the simulation tool to MemAn. In contrast to
the data acquisition the non-functional properties of whole
image processing algorithms and not only memory acces-
ses  will  be  provided.  These  algorithms  are  classified  by
their parameters shown in Table4. The HMSim tool stores
the data in a database with the classification parameters. A
run  of  HMSim  which  calculates  the  processing  time  and
the energy consumption of an algorithm stores the results
of the processing time and the energy consumption with the
parameters  shown  in  Table4.  These  information  in  the
database  can  be  used  by  MemAn  to  calculate  the  energy
consumption  and  the  processing  time  of  the  same  image
processing algorithm with other parameters or to calculate
the  processing  time  and  the  energy  consumption  of  an
unknown    image    processing    algorithm    with    similar
parameters.
5.1 Image processing algorithms
Before   starting   with   the   introduction   of   the   MemAn
framework,   a   nomenclature   in   the   image   processing
domain  will  be  introduced.  Image  processing  algorithms
composed  of  computational  parts  and  a  memory  access
pattern.  The  last  one  can  be  classified  according  to  their
memory  access  into  point,  local,  and  global  pattern.  This
well-known classification [2] is shown in Fig.10.
The classification shown in Fig.10can be used as a first
decision   for   mapping   image   processing   algorithms   on
computing  architectures  and  memory  hierarchies.  Other
## (a)
## (b)
## (c)
## (a+1)
## (b+1)
## (c+1)
Fig. 7Memory access patterns of image processing algorithms
Fig. 8Scheme of the sensor generated memory pattern
J Real-Time Image Proc (2018) 14:713–728719
## 123

important more fine-grain classifiers for image processing
applications  using  an  efficient  memory  hierarchy  are  the
access’  step  distance  and  the  locality.  Frequently,  image
processing  algorithms  are  working  in  iterations.  The  step
distance is the spatial distance between two time sequential
processing steps. In the case of the Sobel algorithm the step
distance  is  one,  because  the  Sobel  algorithm  moves  its
window  mask  pixel  by  pixel  over  the  full  image.  These
scheme is called sliding window and is shown in Fig.11.
Thelocalityis a measure for the spatial adjacency of pixels
in  a  fixed  geometrical  shape,  e.g.,  a  window  in  an  edge
detection  procedure.  It  is  defined  as  the  reciprocal  of  the
maximum spatial distance between its input/output data in
one  processing  step.  The  locality  is  normal  less  than  1,
## 1
locality
corresponds to the distance in the geometrical shape.
Table 4Parameters
NameMeaning
LocalitySpatial locality of the image processing algorithm
The maximum distance between each memory access
NoASpecifies the number of accesses in one processing step
data_widthNumber of bytes for each access
access_distanceAverage distance between the data in one processing step
step_distanceThe distance from one processing step to the next. Can be described as an equation or constant value
AlgorithmThe algorithm name can be used for addressing the results of an concrete algorithm if the algorithm is part of the database
cache_sizeCache size
Fig. 9Connection between HMSim and MemAn
Fig. 10Coarse  classification  of  image  processing  algorithms  by
means of the memory access pattern
Fig. 11Sliding window processing scheme
720J Real-Time Image Proc (2018) 14:713–728
## 123

For a Sobel edge detection algorithm with a 33 window
this distance is
ffiffiffiffiffiffiffiffiffiffiffiffiffiffiffi
## 3
## 2
þ3
## 2
p
, because the maximum distance
between  two  points  in  a  33  window  is  between  the
corner points.
Therefore,  specialized  memory  organization  structures
such as full buffering in [2,21] are created. Such memory
access, exploiting this a prior knowledge can make cache
hit  rates  nearly  100  percent.  Finding  a  suitable  memory
hierarchy  for  image  processing  algorithms  with  random-
ized   memory   access   pattern   is   much   more   difficult.
Examples  of  image  processing  procedures  using  global
operators are shown in Fig.12.
The  examples  illustrated  are  the  Hough  algorithm  for
circle detection [4] and the Ramer–Douglas–Peucker [20]
algorithm  used  for  structure  detection.  They  show  the
complexity  of  predicting  the  required  input  data  for  the
next  processing  step.  The  position  of  the  next  input  data
depends on the kind of classifier, e.g., point, local, or global
that  is  used  in  an  algorithm  and  its  implied  access  to  the
memory. For example, given a point operator the next input
data is the next pixel according to the strategy one propa-
gate  through  an  image,  e.g.,  along  columns  or  rows.  In  a
local operator the size and the moving of a sliding window
mask defines the next input data. In a global operator the
next detected edge pixel in an image is the next input data,
which can be found at an arbitrary position in the image.
Further important features of image processing algorithms
are  the  amount  of  data  an  algorithm  reads  and  writes  at
every processing step and the number of processing steps.
The  following  list  enumerates  each  important  property  of
an  image  processing  algorithm  for  describing its  memory
access pattern. Figure13shows the properties by means of
the Hough circle detection algorithm. The subsequent steps
are  determined  by  the  previous  image  processing  algo-
rithms. In the case of the Hough circle detection algorithm
an edge detection algorithm can determine the step distance
by creating the distance between the edge points.
The  example  in  Fig.13includes  only  three  processing
steps, which are illustrated as green points. The blue circles
are  the  output  pixels  of  the  Hough  circle  detection,  with
one  circle  illustrating  the  results  of  one  processing  step.
## The
## 1
locality
shows  the  maximum  distance  for  input  and
output  data  in  one  processing  step.  The  distance  between
the green points is determined as the step distance. In the
example of the Hough algorithm the step distance depends
on  the  location  of  the  contour  points.  As  such,  the  edge
detection  algorithm  that  provides  the  Hough  input  deter-
mines the step distance for the Hough algorithm. Compared
to the sliding window with a step distance of one pixel this
processing  scheme  has  a  variable  non-constant  step  dis-
tance. This knowledge will be used by HMSim/MemAn for
the estimation of the energy consumption depending on the
cache memory accesses.
5.2 MemAn
The   MemAn   framework   does   not   use   the   simulation
environment   of   HMSim   for   its   execution.   However
HMSim  is  used  for  teaching  and  learning  purposes  in
MemAn.  The  results  from  HMSim  are  documented  and
stored   in   a   MemAn   database.   In   that   case   MemAn’s
accuracy can be improved. In the current state the MemAn
database  is  fed  by  hundreds  of  experimental  data  from
different  image  processing  algorithms  and  cache  configu-
rations.  Table5gives  an  overview  of  the  algorithms  that
have already been stored in the MemAn database.
Neither  random  access  nor  global/local  random  access
are  real  algorithms;  they  are  merely  test  patterns  for  ran-
dom memory behavior with different constrained areas. A
description of the other algorithms can be found in [4,7].
From  our  tests,  a  few  regularities  were  found  and  can  be
used   to   estimate   the   energy   consumption   of   image
## (a)(b)
Fig. 12Examples of global memory access pattern: blue dots are the
memory  access,  red  dots  and  lines  are  the  results:aHough  circle
detection [4],bRamer–Douglas–Peucker [20]
1/Locality
## Step Distance
## Step Distance
1/Locality
1/Locality
Fig. 13Hough  circle  detection  algorithm:  the  green  points  are  the
contour points; the blue points are the output points; one circle stands
for one processing step
J Real-Time Image Proc (2018) 14:713–728721
## 123

processing  applications.  Two  of  them  were  shown  in  the
following:
5.2.1 Relation cache size\[amount of data
The first rule introduces the relationship between the cache
size and the amount of data in one processing step. In our
tests we determined the following equation:
cachesize
NoAdata
width
\0:02ð1Þ
If the ratio between the amount of data and the cache sizes
is  less  than  0.02  for  image  processing  algorithms  with
## 1
locality
[100  an  increase  in  the  cache  size  offers  a  better
performance in access time and energy consumption.
5.2.2 Relation step distance\[block size
The  second  rule  says—in  areas  with  a  high  access  fre-
quency/density  the  access  time  and  energy  consumption
decreases upon increasing the block size. This rule is only
valid for algorithms with an high locality
## 1
locality
## \30. The
following equation shows the condition for increasing the
associativity:
NoA
blocksizelocality
[200ð2Þ
If the access density is high enough an increase in the block
size benefits the energy consumption and access time.
These  cases  do  not  claim  to  provide  a  general  energy
equation  for  all  image  processing  algorithms.  However,
they  result  from  our  tests  with  hundreds  of  test  patterns.
Through continuously testing the MemAn database grows
and the estimation becomes more accurate.
6 HMSim/MemAn configuration
The last sections showed the benefit of HMSim/MemAn. In
this   section   the   configuration   and   mapping   to   exe-
cutable code will be described. The user is able to execute
the simulation with HMSim and the analysis with MemAn
by  creating  an  XML-based  description  file.  The  HMSim/
MemAn  framework  includes  an  XML-parser  to  read  the
configuration  parameters  and  to  create  a  simulation  or
analysis  environment.  Figure14shows  an  example  of  an
MemAn configuration.
The  example  in  Fig.14shows  the  input  parameters
separated   by   algorithmic   parameters   (image_process-
ing_op) and memory parameters (memory_hierarchy). The
language is based on the IPOL language introduced in [9].
As it is done in [9] the mapping methodology uses XSLT to
create  a  simulation  and  analysis  environment.  The  XSLT
rules  create  a  SystemC  simulation environment  (HMSim)
and Mathematica conform code for MemAn.
7 Experimental results
The previous sections offered  an overview  of the  simula-
tion  and  analysis  framework.  In  this  section  only  the
HMSim  part  will  be  evaluated.  MemAn  is  not  precise
enough  to  estimate  the  non-functional  properties  of  an
image  processing  algorithm.  In  this  section  the  approach
will   be   evaluated.   Different   algorithms   with   different
access patterns with various localities, accesses frequencies
and step distances will serve as test cases and cover a large
area  of  image  processing  algorithms.  The  simulation  tool
HMSim uses  custom  measurements  on real  hardware and
Cacti for single memory accesses. Therefore the deviation
on simple algorithms is insignificant.
This section is organized as following: Sect.7.1HMSim
is used to demonstrate the energy consumption and access
time  estimation  by  using  an  emulated  level1  cache  with
Table 5List of algorithms
TypeAlgorithms
Local operatorCanny, Sobel, random local access Gauss, LoG, Harris corner detection
Global operatorHough centroid detection, Hough line detection, random global access, Ramer–Douglas–Peucker
Fig. 14IPOL input for the implementation layer
722J Real-Time Image Proc (2018) 14:713–728
## 123

various access patterns of image processing algorithms. In
Sect.7.1the deviation to real hardware is insignificant. In
Sect.7.2a  concrete  image  processing  applications  with
real  image  processing  algorithms  will  be  discussed.  The
quality of the estimation will be compared with results on
real   hardware   (ARM   Cortex   A9/ARM   Cortex   A57
architecture).
7.1 Single cache hierarchy in HMSim
In this subsection the influence of the cache configuration
(cache   size,   associativity,   block   size)   and   the   access
parameters (locality, step distance, amount of data) to the
energy  consumption  and  the  access  time  will  be  investi-
gated.  The  results  of  such  an  experiment  can  be  used  to
train the MemAn layer. The general test parameters for this
Subsection are listed in the following. The list includes an
additional  note  for  variable  parameters.  If  the  parameters
are  not  variable  in  a  test  scenario  the  values  will  be
assigned by a constant default valuedef const.
Constant parameters are:
•Sensor:  the  sensor  provides  various  images  with  a
19201080 size and 8 bit pixel-resolution.
•Accessed the image in each processing step 9600 times
with five processing steps.
•Cache  properties:  32-nm  SRAM  technology,  replace-
ment strategy is LRU
•Number of accesses in total is 39400.
Variable access parameters are:
•Locality:
## 1
locality
varies  between  10 and 300 pixels  (def
const 50).
•Step  Distance:  varies  between  10  and  300  pixels  (def
const 100).
Variable cache parameters are:
•Cache  size:  varies  between  32,  64,  128  and  256 KB
cache sizes. (def const 256).
•Cache  properties:  varies  between  2-way,  4-way  and
8-way associative (def const 4).
Figure15shows memory structure of the test setup. In this
subsection  it  will  be  used  for  the  determination  of  the
energy   consumption   and   processing   time   for   different
access patterns.
The test scenarios examines the energy consumption and
the access time of the memory hierarchy which covers a L1
cache  and  an  external  memory,  shown  in  Fig.15.  The
subsection is organized in four test scenarios. The first test
shows  the  relation  between  the  algorithms  step  distance,
the  energy  consumption  and  access  time  with  different
cache  sizes.  As  introduced  in  the  beginning  of  this  sub-
section  all  parameters  except  of  the  cache  size  and  step
distance assign their constant default value. The energy and
access time trend for the access pattern by varying the step
and cache size of the image processing algorithm is shown
in Fig.16a, b. The error bars of the simulation comes from
the variation of the input images.
As shown in Fig.16b the cache size has a slight influ-
ence  on  the  energy  consumption  in  cases  with  small  step
distance. Only in cases with larger step distance the cache
size becomes important. Due to the larger step distance the
end of a line inside the image frame will be reached in less
processing  steps.  This  leads  to  earlier  line  breaks  and  a
higher chance that the data of the last line are still stored
inside the cache. In the example of Fig.16b only the cache
with 256 KB is large enough to store an amount of data of
the  last  line  that  can  be  reused.  Between  the  processing
steps of the algorithm step 1 and step 5 the memory cache
is accessed a total of 39,400 times. Just for recapitulation
Fig. 15Single cache
architecture
## (a)
## (b)
Fig. 16The  influence  of  different  cache  sizes.aThe  influence  of
different cache sizes to the access time,bthe influence  of different
cache sizes to the energy consumption
J Real-Time Image Proc (2018) 14:713–728723
## 123

Figs.11and13illustrate the meaning of processing steps.
A  higher  amount  of  memory  increases  the  chance  of  ref-
erencing independent memory access on different addres-
ses  in  the  cache,  which  reduces  the  growth  of  the  reuse
distance. If we consider Fig.16a, b the trend of the access
time and the energy consumption seems similar. This effect
is due to the fact that cache misses need both more energy
and more access time.
In   the   next   experiment   different   associativities   and
localities were used to measure the influence on the energy
consumption  and  access  time,  all  other  parameters  are
constant.  The  ratio  between  locality  and  associativity  in
terms of energy consumption and access time is shown in
Fig.17a, b.
The  results  shown  in  Fig.17a,  b  illustrate  a  slight
influence of the cache associativity in the region 0–100 in
## 1
locality
. The advantages to prevent external memory accesses
with an higher associativity is not given in this region. In
this   region   the   disadvantages   of   higher   associativities
dominate, because each single cache read and write access
requires more energy and time with each increase in cache
associativity. A slightly increase in energy consumption at
higher  associativities  can  be  seen  in  this  region.  In  the
region  of  100–300  pixel  distance  an  opposite  tendency
within  the  ratio  emerges.  Because  higher  associativities
lead to a better performance in reducing external memory
access this leads to a reduction in the energy consumption
and access time.
The next test case shows the relationship between cache
size, locality and energy consumption/access time. The test
was conducted with cache sizes of 32, 64, 128 and 256 KB.
Figure18a, b shows the results from this test case.
A  decrease  in  locality  results  in  an  increase  in  energy
consumption and access time. This increase can be attrib-
uted to the fact that the image processing algorithms have a
lower  locality  and  lack  of  any  kind  of  cache  block  size
exploitation.  Second,  a  lower  access  density  and  a  wider
distribution of accessed pixels leads to fewer instances of
redundant  access.  In  combination  with  small  caches  the
memory control unit is forced to map additional, different
RAM  addresses  on  the  same  cache  address.  The  address
space increases without an increase to the cache size. This
leads to a more rapid reuse distance increasing and to faster
replacements.
In  the  last  test  in  this  subsection  the  influence  of  the
block   size   for   the   energy   consumption   was   tested.
## (a)
## (b)
Fig. 17The  effect  of  associativity  and  locality.aThe  effect  of
associativity   and   locality   to   the   access   time,bthe   effect   of
associativity and locality to the energy consumption
## (a)
## (b)
Fig. 18The effect of locality and cache size.aThe effect of locality
and cache size to the access time,bthe effect of locality and cache
size to the energy consumption
724J Real-Time Image Proc (2018) 14:713–728
## 123

Therefore  a  cache  with  a  4-way  associativity  and  32 KB
cache size was used.
The  energy  consumption  and  access  time  shown  in
Fig.19a, b increases with an increase in the step distance,
comparable  to  the  results  in  Fig.17a,  b.  Hence  the  block
size  has  an  enormous  and  important  influence  on  energy
consumption and access time. A cache with a block size of
8 needs much less energy and access time than a cache with
a  lower  block  size.  A  higher  block  size  increases  the
chance of pre-fetching future required data in a cache cell
and  also  reduces  the  replacement  rates.  This  reduces  the
cache miss rate and leads to lower energy consumption and
access  time  rates.  This  specially  applies  for  image  pro-
cessing  algorithms  with  an  higher  locality.  Because  the
required  data  for  one  processing  step  were  covered  in  a
minimum of loaded blocks.
7.2 Multi-cache hierarchies HMSim and real
hardware
This  subsection  shows  a  test  scenario  with  two  level1
caches,  one  shared  level2  cache  and  an  external  DDR
RAM. The emulated memory platform will be compared to
the real memory platform (ARM Cortex A9/ARM Cortex
A57). The quality of the HMSim tool will be evaluated in
this   subsection.   The   test   parameters   are   listed   in   the
following
Constant parameters are:
•Sensor:  the  sensor  provides  different  images  with  a
19201080 size and 8 bit pixel-resolution.
•Locality:
## 1
locality
is 3 for the Sobel and 300 for the Hough
algorithm
•Cache  properties:  4-way  associative,  512 KB  cache
size   for   the   L2   cache,   32-nm   SRAM   technology,
replacement strategy is LRU
Variable algorithm parameters are:
•Quantization of the Hough algorithm is 20, 40, 60, 80
and 100%.
Variable cache parameters are:
•L1  cache  size:  varies  between  4,  8  and  16 KB  cache
sizes for each L1 cache.
Figure20shows  the  memory  configuration  and  the  test
setup.  The  application  is  composed  of  the  Sobel  edge
detection and the Hough circle detection algorithms. Each
algorithm accesses its own level1 cache. For cache misses
the shared level2 cache will be accessed. Misses inside the
level2 cache lead to accessing the external DDR RAM.
In this test the relationship between the amount of data
and the access time will be investigated with various level1
cache sizes. The level2 caches had a constant memory size
of 512 KB, 32-byte block size and a 4-way associativity. A
block size of 32 bytes, an associativity of 4 and a varying
cache size of 4, 8 and 16 KB was used for the level1 cache.
On  the  application  side  the  number  of  memory  accesses
from the Hough circle detection algorithm varied between
20, 40, 60, 80 and 100%. 100% means that the ‘‘help cir-
cles’’  from  the  Hough  circle  detection  algorithm  have  no
quantization. For more details on the Hough circle detec-
tion algorithm please refer to [4]. The results are shown in
## Fig.21.
The error bars of the simulation comes from the varia-
tion  of  images.  The  results  of  Fig.21show  that  a  larger
level1 cache can reduce the application’s access time rates.
The   deviation   between   the   access   time   measured   on
## (a)
## (b)
Fig. 19The  effect  of  block  size  and  step  distance.aThe  effect  of
block size and step distance to the access time,bthe effect of block
size and step distance to the energy consumption
Fig. 20Multi-cache architecture
J Real-Time Image Proc (2018) 14:713–728725
## 123

hardware  ‘‘Cache  Size  16 KB  real’’  is  measured  on  the
ARM Cortex A9 memory system and the HMSim is very
close and less than 10%. For image processing applications
HMSim  is  able  to  estimate  the  energy  consumption  and
access  time  for the memory architecture  at a precision  of
10%. The results show that the memory hierarchy does not
reach 25 fps, what most people conceive as real time. The
ARM Cortex A57 is two times faster than the ARM Cortex
A9  but  also  does  not  reach  25  fps.  The  heat  map,  intro-
duced in Sect.4can be used to detect the bottleneck in the
memory structure and to enhance the system structure. An
other option is  the variation  of the  hardware  architecture.
At Fig.22, the energy consumption of the image process-
ing  application  (Hough  transformation)  is  shown  at  dif-
ferent   memory   architectures.   Such   as  the   access   time
calculation  the  energy  consumption  also  has  a  very  high
precision with an error less than 20%.
7.3 Heterogeneous hardware architecture
In  this  section  a  CPU  is  coupled  with  a  FPGA.  It  imple-
ments the same application as the section before, with the
same  parameters  of  the  input  image  and  the  CPU  (ARM
Cortex A9/A57). The Sobel edge detector is implemented
as Full-buffering processing scheme by using a FPGA. On
simulation  side  a  SystemC  module  implements  the  Full-
buffering [21] and is  directly coupled with the OVP sim-
ulation  environment by using the  standard OVP  SystemC
interface. The system design is shown in Fig.23.
A sensor for the input image creation is directly coupled
to the Sobel edge detector in the FPGA. The Full-buffering
scheme   avoids   redundant   memory   access   at   the   edge
detector and reduces the memory access in total. This has
an impact on the access time shown in Fig.24.
Also  the  energy  consumption  will  be  reduced  in  com-
parison  with  the  Sobel(CPU)–Hough(CPU)  implementa-
tion  of  the  last  Subsection.  As  mentioned  in  the  last
subsection,  an  energy  consumption  result  of  the  Cortex
A57 is not available at the moment.
With  this hardware architecture  a real-time image  pro-
cessing system (25 fps) can be implemented with both, the
FPGA?(A9 or A57). Also the energy consumption will
be  reduced  by  avoiding  redundant  memory  access  at  the
edge detector side. This is shown in Fig.25. This leads to a
better  performance  of  the  image  processing  system.  The
example  shows  that  the  energy  estimation  is  less  precise
than  the  estimation  of  the  processing  time.  This  comes
from  the  low  precision  by  using  difference  measurement
method.
## 8 Limitations
At  this  moment  it  is  possible  to  estimate  non-functional
properties  of  image  processing  applications  with  a  high
precision  by  using  HMSim.  The  MemAn  tool  lacks  in
precision at the moment and will be enhanced in the future.
This is the reason why the example part of this work does
not  show  any  results  about  MemAn.  Also  GPU-based
hardware   architectures   can   not   be   simulated   with   the
framework.  Therefore  a  connection  to  a  GPU  simulator,
such as GPGPUsim [8], is planed for future work.
Fig. 21Multi-cache architecture: the access time trend of the Sobel–
Hough-application  for  different  level1  cache  sizes.  ‘‘Cache  Size
16 KB real’’ are the results of an ARM Cortex A9
Fig. 22Multi-cache  architecture:  the  energy  consumption  trend  of
the Sobel–Hough-application for different level1 cache sizes. ‘‘Cache
Size 16 KB real’’ are the results of an ARM Cortex A9
Fig. 23FPGA-CPU architecture
726J Real-Time Image Proc (2018) 14:713–728
## 123

## 9 Conclusion
In  this  paper  we  introduced  a  novel  methodology  for  the
simulation  and  analysis  of  image  processing  applications.
The  HMSim/MemAn  framework  provides  new  ways  for
the  energy  and  timing  estimations  of  image  processing
applications. With the assistance of the framework devel-
opers  gain  two  advantages.  The  first  advantage  is  that
HMSim/MemAn   assists   in   finding   the   best   memory
architecture for an image processing application in terms of
access   time   and   energy   consumption.   Finding   a   suit-
able memory hierarchy has a major importance for image
processing   applications,   due   to   the   frequent   memory
accesses  in  image  processing  applications.  The  example
section showed that different hardware architectures can be
compared   with   high   precision   without   real   hardware
devices. The second advantage to HMSim/MemAn has its
focus  on  the  software  side.  HMSim/MemAn  assists  soft-
ware  developers  in  finding  the  bottlenecks  in  image  pro-
cessing  applications  in  terms  of  access  time  and  energy
consumption.   By   using   the   tool   introduced   in   Sect.4
developers  are  able  to  localize  the  bottlenecks  in  image
processing  applications.  This  enables  the  improvement  of
image  processing  applications  in  order  to  use  hardware
architectures  more  efficiently.  This  can  be  done  without
real hardware, with less time, and in comparison with real
hardware  tests,  with  more  debugging  options  and  more
detailed reports. In addition Sect.7showed the influence of
algorithmic  specific  and  hardware  parameters  on  the  pro-
cessing  time  and the  energy  consumption. These parame-
ters   were   identified   and  specified  in  this  work   as  an
influencing    factor    on    non-functional    properties.    For
example,  it  shows  that  an  increase  in  locality  and  asso-
ciativity leads to a decrease in processing time and energy
consumption. Also the relation between the locality and the
blocksize   regarding   their   influence   on   non-functionale
properties was demonstrated. This knowledge can be used
to  create  a  methodology  for  the  estimation  of  non-func-
tional properties without a simulation environment or real
hardware  architectures.  In  our  ongoing  work  we  plan  to
improve the precision  of MemAn and to couple the  OVP
instruction  simulator  of  Imperas  [13]  with  our  memory
simulation environment HMSim to create a holistic simu-
lation environment.
AcknowledgementsThis   work   is   supported   by   the   Bavarian
Research   Foundation   (BFS)   as   part   of   their   research   project
## ‘‘FORMUS
## 3
## IC’’.
## References
## 1.  Avnet.http://www.zedboard.org/(2016)
-  Bailey,  D.: Design for Embedded Image Processing  on FPGAs.
## Wiley, New York (2011)
## 3.  Binkert,  N.,  Beckmann,  B.,  Black,  G.,  Reinhardt,  S.,  Saidi,  A.,
## Basu, A., Hestness, J., Hower, D., Krishna, T., Sardashti, S., Sen,
R., Sewel, K., Shoaib, M., Vaish, N., Hill, M., Wood, D.: The gem5
simulator. SIGARCH Comput. Archit. News39(2), 1–7 (2011)
-  Burger,  W.,  Burge,  M.:  Principles  of  Digital  Image  Processing.
## Springer, London (2009)
-  Das, S., Aamodt, T.M., Dally, W.J.: Reuse distance-based prob-
abilistic  cache  replacement.  Trans.  Archit.  Code  Optim.12(4),
## 33:1–33:22 (2015)
## 6.  Eeckhout,  L.:  Computer  Architecture  Performance  Evaluation
Methods. Morgan and Claypool, Wisconsin (2010)
## 7.  Gonzalez,  R.,  Woods,  R.:  Digital  Image  Processing.  Person
## Education Ltd., London (2008)
-  GPGPU-Sim.http://www.gpgpu-sim.org(2017)
-  Hartmann, C., Reichenbach, M., Fey, D.: Ipol—a domain specific
language  for  image  processing  applications.  In:  Proceedings  of
the  International  Symposium  on  International  Conference  on
Systems, pp. 40–43. Barcelona, Spain, IARIA (2015)
## 10.  Hartmann,  C.,  Ha
## ̈
ublein,  K.,  Reichenbach,  M.,  Fey,  D.:  Ipas:  a
design  framework  for  analysis,  synthesis  and  optimization  of
image   processing   applications   for   heterogenous   computing
architectures.  J.  Real  Time  Image  Process.11,  1–16  (2016).
doi:10.1007/s11554-016-0587-x
## 11.  Herglotz,  C.,  Seiler,  J.,  Kaup,  A.,  Hendricks,  A.,  Reichenbach,
M., Fey, D.: Estimation of non-functional properties for embed-
ded  hardware  with  application  to  image  processing.  In:  Pro-
ceedings of the International Parallel and Distributed Processing
Fig. 24Processing  time  of  a  FPGA  (Sobel)  and  CPU  hardware
architecture
Fig. 25Energy consumption of a FPGA (Sobel) and CPU hardware
architecture
J Real-Time Image Proc (2018) 14:713–728727
## 123

Symposium  Workshop,  pp.  190–195.  Hyderabad,  Malay,  IEEE
## (2015)
-  HP Labs.http://www.hpl.hp.com/research/cacti/(2016)
## 13.  Imperas.www.imperas.com(2016)
## 14.  Intel.www.intel.com(2016)
## 15.  Mathematica.http://www.wolfram.com/mathematica/(2016)
-  Naji, O., Hansson, A., Weis, C., Jung, M., Wehn, N.: A high-level
dram  timing,  power  and  area  exploration  tool.  In:  International
Conference   on   Embedded   Computer   Systems   Architectures
Modeling and Simulation, pp. 149–156. IEEE (2015)
-  Nugteren,  C.,  van den  Braak,  G.-J.,  Corporaal,  H.,  Bal,  H.:  A
detailed  gpu  cache  model  based  on  reuse  distance  theory.  In:
Proceedings  of  the  International  Symposium  on  High  Perfor-
mance Computer Architecture (HPCA), pp. 37–48. IEEE (2014)
-  Pan, X., Jonsson, B.: A modeling framework for reuse distance-
based estimation of cache performance. In: Performance Analysis
of  Systems  and  Software  (ISPASS),  pp.  62–71.  Philadelphia,
## USA, IEEE (2015)
-  Pelcat, M., Desnos, K., Heulot, J., Guy, C., Nezan, J-F., Aridhi,
S.:  Preesm:  a  dataflow-based  rapid  prototyping  framework  for
simplifying multicore dsp programming. In: European Embedded
Design   in   Education   and   Research   Conference,   pp.   30–40.
Milano, Italy, IEEE (2014)
-  Schmidt, M., Reichenbach, M., Fey, D.: Traffic sign recognition
with  color-based  method,  shape-arc  estimation  and  svm.  In:
International  Conference  on  Electrical  Engineering  and  Infor-
matics (ICEEI), pp. 1–6. IEEE (2011)
-  Schmidt, M., Reichenbach, M., Fey, D.: A generic vhdl template for
2d stencil code applications on fpgas. In: International Symposium
on   Object/Component/Service-Oriented   Real-Time   Distributed
Computing Workshops (ISORCW), pp. 180–187. IEEE (2012)
-  Xu,  C.,  Chen,  X.,  Dick,  R.,  Mao,  Z.:  Cache  contention  and
application  performance  prediction  for  multi-core  systems.  In:
Performance   Analysis   of   Systems   and   Software   (ISPASS),
pp. 76–86. White Plains, USA, IEEE (2010)
-  Zimmer.http://www.zes.com/en/Products/Precision-Power-Ana
lyzer/LMG640(2016)
Christian Hartmannstudied   Computer   Science   and   Electrical
Engineering at the Munich University of Applied Sciences. He holds
a  Diploma  degree  in  Computer  Science  and  a  Master’s  degree  in
Electrical  Engineering.  After  completing  his  degrees,  he  joined  the
Digital  Camera  Systems  group  of  the  Fraunhofer  IIS.  The  develop-
ment of smart camera systems for Point-of-View applications was one
of his main research tasks at the Fraunhofer IIS. In 2013, he started as
a Ph.D. student at the chair of Computer Architecture at the Friedrich-
Alexander  University  Erlangen-Nuernberg  and  is  a  member  of  the
## Research   Training   Group   Heterogeneous   Image   Systems.   His
research interests are smart cameras, heterogeneous hardware archi-
tectures and system optimization on heterogeneous image processing
architectures.
Dietmar Feyhas  studied  Computer  Science  at  Friedrich-Alexander
University Erlangen-Nuernberg (FAU). He made his Ph.D. thesis on a
work in Optical Computing in 1992. He worked as scientific assistant
and  lecturer  at  the  Universities  of  Jena  and  Siegen.  In  2002,  he
became Professor for Computer Engineering at the University of Jena.
Since 2009 he leads the chair for Computer Architecture at FAU. His
research interests are parallel computer architectures, parallel embed-
ded systems and memristive computing. He has published over 140
conference  contributions  including  3  books,  and  about  20  papers  in
journals.  He  is  a  member  of  the  European  Network  of  Excellence
HiPEAC and is a contributor of the current HiPEAC roadmap.
728J Real-Time Image Proc (2018) 14:713–728
## 123