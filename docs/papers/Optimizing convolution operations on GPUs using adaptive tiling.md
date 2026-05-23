

FutureGenerationComputerSystems30(2014)14–26
Contents lists available at ScienceDirect
FutureGenerationComputerSystems
journal homepage: www.elsevier.com/locate/fgcs
OptimizingconvolutionoperationsonGPUsusingadaptivetiling
BenvanWerkhoven
a,∗
,JasonMaassen
a,b
,HenriE.Bal
a
,FrankJ.Seinstra
a,b
a
DepartmentofComputerScience,VUUniversityAmsterdam,DeBoelelaan1081,1081HVAmsterdam,TheNetherlands
b
NetherlandseScienceCenter,SciencePark140,1098XGAmsterdam,TheNetherlands
h i g h l i g h t s
•WepresentanextensivestudyoftheoptimizationprocessofconvolutionsonGPUs.
•Existingoptimizationtechniquesaretoolimitedinperformanceandflexibility.
•WepresentanewoptimizationforconvolutionsonGPUscalledadaptivetiling.
•Ourimplementationisthebestperformingoneinthespatialdomainavailabletodate.
a r t i c l e    i n f o
## Articlehistory:
Received20November2012
## Receivedinrevisedform
6August2013
Accepted5September2013
Availableonline16September2013
## Keywords:
## High-performancecomputing
GPUcomputing
## Parallelapplications
GPUclusters
## High-levelprogrammingmodels
a b s t r a c t
The research domain of Multimedia Content Analysis (MMCA) considers all aspects of the automated
extractionofknowledgefrommultimediadata.High-performancecomputingtechniquesarenecessary
tosatisfytheeverincreasingcomputationaldemandsofMMCAapplications.TheintroductionofGraphics
Processing Units (GPUs) in modern cluster systems presents application developers with a challenge.
While GPUs are well known to be capable of providing significant performance improvements, the
programming complexity vastly increases. To this end, we have extended a user transparent parallel
programming model for MMCA, named Parallel-Horus, to allow the execution of compute intensive
operationsontheGPUspresentinthecluster.ThemostimportantclassofoperationsintheMMCAdomain
are convolutions, which are typically responsible for a large fraction of the execution time. Existing
optimizationapproachesforCUDAkernelsingeneralaswellasthosespecifictoconvolutionoperations
aretoolimitedinbothperformanceandflexibility.Inthispaper,wepresentanewoptimizationapproach,
calledadaptive tiling, to implement a highly efficient, yet flexible, library-based convolution operation
for modern GPUs. To the best of our knowledge, our implementation is the most optimized and best
performingimplementationof2Dconvolutioninthespatialdomainavailabletodate.
©2013ElsevierB.V.Allrightsreserved.
## 1. Introduction
MultimediaContentAnalysis(MMCA)investigatesmethodsof
automated knowledge extraction from image, video, and multi-
media data. Research in the domain is driven by emerging ap-
plications, ranging from real-time analysis of video data from
surveillance cameras, to searching digital television archives [1].
The massive amounts of data in such applications makes storing,
cataloging, processing, and retrieving of information a very chal-
lenging task. As a result, high-performance computing is indis-
pensableintheMMCAdomain.
ItisunrealistictoexpectMMCAresearcherstoalsobecomeex-
pertsinhigh-performancecomputing.Therefore,itisessentialto
## ∗
Correspondingauthor.Tel.:+31205985849.
E-mailaddresses:ben@cs.vu.nl(B.vanWerkhoven),
j.maassen@esciencecenter.nl(J.Maassen),bal@cs.vu.nl(H.E.Bal),
f.seinstra@esciencecenter.nl(F.J.Seinstra).
developefficientprogrammingmodelsthathidetheintrinsiccom-
plexitiesoftheunderlyingcomputinghardware.Intheliterature,
a number of suchuser transparentparallel programming models
have been described (e.g. see [2,3]). These programming models
arebasedonasoftwarelibraryofpre-parallelizedcomputekernels
that cover the bulk of all commonly applied MMCA functionality.
## Generally,thesekernelsaredesignedfordataparallelexecutionon
traditionalcomputeclusters.
Today, many emerging cluster systems are equipped with
Graphics Processing Units (GPUs). Although GPUs are capable of
providing significant performance improvements, programming
complexityvastlyincreases.AscurrentMMCAprogrammingmod-
elsforclustersystemsdonotincorporateGPUs,onlyafractionof
thecomputepowerofmodernclustersisexploited.Clearly,thereis
aneedforeasy-to-useandefficientprogrammingmodelsforhigh-
performancemultimediacomputingonGPU-equippedclustersys-
tems.
In this paper, we present an extensively optimized library-
based implementation for convolution operations. Convolutions
0167-739X/$–seefrontmatter©2013ElsevierB.V.Allrightsreserved.
http://dx.doi.org/10.1016/j.future.2013.09.003

B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–2615
are essential to signal and image processing applications, and
are typically responsible for a large fraction of the application’s
executiontime.
## Thisworkispartofalargerefforttoobtainanimplementation
oftheParallel-Horus[4]programmingmodelthatallowssequen-
tiallywrittenMMCAprogramstoexecuteashighlyoptimizedap-
plications for GPU-clusters without requiringanyparallelization
effort from the application programmer. Because 2D convolution
operations can be parallelized over multiple compute nodes sim-
ply by splitting and merging the input and output images across
thenodes,thispaperonlydiscussesoptimizationswithinasingle
GPUcomputenode.
## Thispaperprovidesthefollowingcontributions:
•Wepresentanextensivestudyoftheoptimizationprocessof2D
convolution and separable convolution operations on modern
graphicscards.
•We demonstrate that once all the well-known optimization
techniques have been applied, there are many optimizations
stillpossible.
•We introduce a new optimization approach for implementing
efficient GPU-enabled library-based convolution operations,
calledadaptive tiling, which we also combine with loop un-
rolling.
•Tothebestofourknowledge,ourimplementationisthemost
optimizedandbestperformingimplementationof2DConvolu-
tioninthespatialdomainavailabletodate.
## Wehavemadethesourcecodeofourkernelsavailablefromthe
firstauthor’shomepageaspartofthedata-parallelParallel-Horus
programmingmodel.
The remainder of this paper is organized as follows. Section 2
discusseswell-knownoptimizationtechniquesthathavetobeap-
pliedtoourCUDAkernelsbeforewecanapplyourownoptimiza-
tionapproach.Section3presentsourapproachforavoidingshared
memory bank conflicts. Section 4 presents our new optimization
approachcalledadaptivetilinganddiscussestheperformanceim-
provements.Section5combinesadaptivetilingwithloopunrolling
to create our most efficient implementation. Section 6 evaluates
theperformanceimprovementsofeachoptimizationsteponvari-
ousgraphicshardware.Section7discussesthelimitationsthatare
inherent to spatial solutions to the 2D convolution problem. Sec-
tion8discussesrelatedworkandSection9andconcludes.
- Naive implementation and well-known optimizations
This section presents a naive CUDA implementation and dis-
cussesexistingoptimizationtechniquesthatformastartingpoint
for our own optimizations. The discussion of these techniques is
included to present the reader with a complete overview of the
optimizationprocess.ReaderswithmuchexperienceinGPUpro-
grammingandoptimizationmaychoosetoskipthissection.Asde-
tailed in Section 8, the implementation approach presented also
improvesuponexistingwork.
In this paper, we continuously report performance results ob-
tainedontheNvidiaGTX680KeplerGPU[5].Whenevernecessary,
wealsoreportresultsobtainedontheGTX480FermiGPU[6]and
theTeslaK20[7],alsooftheKeplerarchitecture.TheKeplercards
have significantly more compute cores than the Fermi cards, for
example, 8 SMs of 192 cores (i.e. 1536 cores) for the GTX680
versus 15 SMs of 32 cores (i.e. 480 cores) for the GTX480. The
Kepler cores run at a lower clock frequency to improve energy
efficiency.Therespectivetheoreticalpeakperformance,computed
ascores×frequency×2,oftheGTX480,GTX680,andK20is1344.96,
3090.43, and 3519.36 GFLOP/s. The theoretical peak global mem-
ory bandwidth, however, has not scaled up proportionally with
the increased compute performance of the newer cards. The re-
spectivetheoreticalpeakglobalmemorybandwidth,computedas
(buswidth×memoryclock)/8,oftheGTX480,GTX680,andK20is
177,192,and208GB/s.OntheKeplerarchitectureglobalmemory
loadsandstoresareonlycachedinL2andnotinL1.TheL1cacheis
reservedforaccessestolocalmemoryandregisterspilling.Onthe
Fermi architecture, however, global memory loads and stores are
cached in L2 and L1. The caches give an important, yet very hard
to predict, performance boost to the 2D convolution kernels. The
KeplerSMsalsohaveincreasedspaceforregistersandcansupport
ahighernumberofthreadsexecutingconcurrentlyperSM.How-
ever,theamountofsharedmemoryperSMonKeplerisexactlythe
sameasonFermi,48KBperSM.WhiletheGTX680onlyhas8SMs,
theK20has13,andtheGTX480has15,therefore,intotaltheolder
GTX480hasevenmoresharedmemorythaneitherKeplercard.
Ineachofourmeasurements,thekernelperformsa2Dconvo-
lution of an image of 4096×4096 floating point pixels and uses
filtersizesrangingfrom3upto43inbothdimensions.Usinglarger
orsmallerimagesinfluencesthetotalexecutiontimeoftheopera-
tion,butonlyhasaverylimitedeffectontheperformancebehavior
ofthekernelintermsofGFLOP/s.3Dgraphsareusedastheperfor-
manceofour2Dconvolutionimplementationsoftenvariesinboth
dimensions.Someconfigurationscauseperformancecliffs,thatis
asignificantdropinperformanceoccurswhenthefiltersizeisin-
creasedbeyondacertainpoint.
In image processing, a convolution operation computes a new
value for every pixel based on a weighted average of the original
pixel and the pixels in itsneighborhood. These weights are stored
in aconvolution filter, which also determines the size of the
neighborhood. To ensure that every pixel can be evaluated (even
attheedgeoftheimage)weassumethattheinputimageincludes
aborderandisthuslargerthantheoutputimage.
An implementation in C for the 2D convolution kernel, shown
in Fig. 1(a), uses two loops to iterate over all pixels in the image.
The inner two loops iterate over each pixel in the neighborhood
of the current pixel and compute a weighted average using the
weights stored in the convolution filter. The algorithm takes an
imageIofsize(I
w
## ×I
h
)andafilterFofsize(F
w
## ×F
h
## )asarguments.
A naive CUDA implementation, shown in Fig. 1(b), is obtained by
creating one CUDA thread for each output pixel. This way, every
CUDA thread computes the weighted average of a single pixel’s
neighborhood and writes a single pixel to the output image. The
inputandoutputimagescanbepaddedtomultiplesofthethread
blockwidthandheight,toallowimagesofanysizetobeprocessed
bythekernel.
ThefirststepintheprocessofoptimizingCUDAkernelsisen-
suringthatthekernelisnotglobalmemorybandwidthbound.This
can be easily checked using the Roofline Model [8]. The key idea
behind the roofline model is to calculate the arithmetic intensity
(FLOP/byte ratio) of a kernel and multiply this by the theoretical
peakbandwidthofthedevice.Theresultisanestimateofthepeak
performance that can be achieved by the kernel. If this exceeds
thetheoreticalpeakperformanceofthedevicethekernelisclearly
computebound,otherwiseitismemorybandwidthbound.
Thearithmeticintensityofthe2Dconvolutionkerneliscalcu-
lated as follows. For every weight in the convolution filter, each
threadloads2floatingpointvalues,thepixelandthefilterweight
making up a total of 8 bytes. These two inputs are multiplied
and added to a local sum, giving an arithmetic intensity of 0.25
FLOP/byte. On a device with no hardware managed caches, the
maximum compute performance of the kernel is computed by
multiplying the memory bandwidth of the device with the arith-
meticintensityofthekernel.However,ondeviceswithhardware
managedcaches,manypixelvaluescanbeloadedfromthecache
asneighboringthreadswillrequiretheoverlappingpixeldata.
Rather than relying on the hardware caches to cope with the
high memory bandwidth requirements, parts of the data can be
stored in different device memories. First of all, half of the loads

16B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–26
ab
Fig. 1.(a)Pseudocodeforasimple2Dconvolution.(b)PseudocodeforthesamealgorithmasaCUDAkernel.
Fig. 2.Layoutofthedatastoredinsharedmemory.Exampleshowsa16×16thread
blockprocessingan11×7filter.
in the kernel are values from the convolution filter, of which all
threadsinawarploadthesamevaluesimultaneously.Thisaccess
pattern is ideally suited for constant memory. Secondly, threads
within a block can cooperate by sharing data through shared
memory. As neighboring threads will require largely overlapping
regions from the input image, the threads within a block may
cooperatively load the entire area needed by all threads in the
block, this approach is occasionally referred to as tiled convolu-
tion [9] and is illustrated in Fig. 2. This way, the threads load the
area required by this thread block exactly once, instead of many
times. For 2D convolution it is crucial to assign 2-dimensional
workloadstothreadblocks,inordertomaximizedatareuse.Thisis
becausethreadsthatrequiremostlyoverlappingregionsfromthe
inputimageneighboreachotherin2dimensions.
The exact bandwidth requirements of the kernel now depend
ontheconvolutionfilterandthreadblockdimensions,andisgiven
by(F
w
## −1+B
w
## )×(F
h
## −1+B
h
## )×4bytesperthreadblock,where
## F
w
andF
h
arethewidthandtheheightoftheconvolutionfilterand
## B
w
andB
h
are the width and the height of the thread block. The
arithmeticintensitythenbecomes,
## AI=
## 2×F
w
## ×F
h
## ×B
w
## ×B
h
## (F
w
## −1+B
w
## )×(F
h
## −1+B
h
## )×4
## .(1)
Given a thread block of 32×32 and the smallest possible 2D fil-
ter3×3,thearithmeticintensityis3.99FLOP/byte.Giventhatthe
GTX680 has 192.26 GB/s of global memory bandwidth, a 2D con-
volutionkernelthatusessharedmemoryhasapeakperformance
of 766.36 GFLOP/s, which is still lower than the theoretical peak
ofthedevice(3090.43GFLOP/s).However,arithmeticintensityin-
creasesasthefiltersizeincreases.Formostfiltersizesinourtest
range,exceptforthe20smallest,thetheoreticalpeakofthekernel
exceedsthetheoreticalpeakofthedeviceandthereforethekernel
iscomputeboundratherthanmemorybandwidthboundformost
filters. In Section 4, we will discuss how the arithmetic intensity,
especially for the smallest filters, can be further increased using
ouradaptivetilingapproach.
## Fig.3showstheperformanceforthecomputeboundkernelthat
usesconstantandsharedmemory.Theperformancefirstincreases
as the filter size gets larger. However, as the filter size increases
the amount of shared memory used by the kernel also increases,
reducingtheperformanceasfewerthreadblockscanrunconcur-
rently on each SM. In Fig. 3(a), the number of thread blocks that
executeconcurrentlyoneachSMdecreasesfrom8to3asthefil-
tersizeincreases.Thisisvisibleinthegraphasfivedistinctedges
where performance decreases slightly. Between these edges per-
formanceslightlyincreasesagain,becauselargerfiltersizeshavea
higherarithmeticintensity.
## Fig.3(a)alsoshowsafewperformancepeaks,thelargestatthe
highedgewhenthefilterwidthis33.Thishighedgeoccursbecause
the other filter sizes suffer from shared memory bank conflicts
thatoccurwhenmultiplethreadstrytoaccessdifferentvaluesin
thesamebank.Ourtechniquesforavoidingsharedmemorybank
conflictsin2DconvolutionkernelsarediscussedinSection3.The
smallerpeaksoccuratfilterwidths5,9,and17,whichexecutewith
fewerbankconflictsthanotherfilterwidths,exceptforwidth33.
This is because multiple rows of border and pixel data add up to
multiples of 32 banks, for these filter widths, and therefore some
ofthememoryaccesseswillrunconflictfree.Formoreinformation
on shared memory bank conflicts see the CUDA Programming
## Guide[10].
In the convolution kernels, discussed so far, each thread block
processesasingletileofpixelsfromtheinputimage.However,the
numberoftileseachthreadblockcomputescanbeincreased.The
approachofprocessingmultipletilesinthehorizontaldimensionis
oftenreferredtoas1×N tiling[11]orthread-blockmerging[12].
Increasing the amount of work per thread eliminates redundant
instructionssuchasarrayindexcalculations,loopaccounting,and
loadingvaluesfromtheconvolutionfilterthatwerepreviouslydis-
tributed across different threads, as shown in Fig. 4. Additionally,
a thread block that computes two neighboring tiles from the in-
put image no longer needs to load the overlapping borders be-
tween the two tiles, further increasing arithmetic intensity. The
totalamountofsharedmemoryallocatedtoeachthreadblockin-
creasesto(F
w
## −1+B
w
## ×N)×(F
h
## −1+B
h
),when1×Ntilingis
used.Whentheamountofworkperthreadisdoubled,onlyhalfthe
numberofthreadblocksarecreatedtoexecutethesamekernel.
Fig.4showshow1×2tilingmaybeappliedtothe2Dconvolu-
tionkernel.Sisthedynamicallyallocatedsharedmemory.B
w
isthe
widthofthethreadblock.ThecodeonLine5isinsertedtoallow
threadstocomputetwointermediatesums,whilereusingthefil-
terweightstoredinF.Registerusageincreasesbyoneregisterper
threadtostoretheadditionalintermediateresult.Tilingincreases
theamountofworkperthread,whichrequiresmoreregistersper
threadandmoresharedmemoryperthreadblock.Therefore,the
tilingfactorcanonlybeincreasedwithintheresourcelimitsofthe
device.
## Fig.5showstheperformanceofthe1×2and1×4tiledkernels
on a GTX680 using a 32×32 thread block. Using large thread
blocks reduces memory bandwidth consumption of the kernel,
because with fewer thread blocks there are fewer overlapping
neighborhoodsbetweenthetilesprocessedbyeachthreadblock.
Because of the large number of threads in each thread block at
most two thread blocks can execute on each SM at any given

B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–2617
ab
Fig. 3.Performanceofthekernelusingsharedmemoryand(a)a16×16threadblocksizeand(b)a32×32threadblocksize.
Fig. 4.Pseudocodeforthemainloopofthe1×2tiled2Dconvolutionkernel.
time. However, as the filter size increases shared memory usage
alsoincreases,whichlimitsthenumberofblocksthatcanexecute
concurrentlyoneachSM.Theedgeinbothperformancegraphsis
caused by this exact drop in occupancy, from 64 warps (i.e. two
32×32 thread blocks) to 32 warps (i.e. a single 32×32 thread
block).Infact,forthe1×4tiledkernel,filtersizes(41×43)and
(43×43)requiremoresharedmemorythanavailableperSMand
thereforecannotbeexecuted.
## Fig.6showstheperformanceofthe1×2and1×4tiledkernels
onaGTX680usinga16×16threadblock.Theperformanceinboth
figures decreases as the filter size increases, because increased
sharedmemoryusagedecreasesthenumberofthreadblocksthat
can execute concurrently. Overall, the performance for both ker-
nelsisdominatedbysharedmemorybankconflicts,exceptwhen
thefilterwidthisexactly17.Thenextsectionexplainswhyshared
memorybankconflictsoccurandhowtheycanbeavoided.
- Avoiding shared memory bank conflicts
The previous section discussed an implementation of a 2D
convolution kernel based on existing optimization techniques,
such as 1×Ntiling. We showed that kernels with higher tiling
factors often execute more efficiently, but may require more
shared memory than available on the device when combined
with a large thread block size (32×32). The shared memory
ab
Fig. 5.Performanceof(a)1×2and(b)1×4tiledkernelsexecutedwith32×32threadblock.
ab
Fig. 6.Kernelsexecutedwitha16×16threadblock,mostfilterwidthscausebankconflicts,(a)usinga1×2tiledkernel(b)usinga1×4tiledkernel.

18B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–26
Fig. 7.Pseudocodethatallowsthreadswithinathreadblocktocooperativelyload
a rectangular area of size(F
h
## −1+B
h
## )×(F
w
## −1+B
w
)and store it in shared
memory.
requirementsofthekernelcanbereducedbyreducingthethread
blocksizeto,forexample16×16.However,usingsmallerthread
blocks may cause shared memory bank conflicts. Therefore, this
section explains in detail why shared memory bank conflicts
occur and presents a novel approach to avoid bank conflicts in
convolutionkernels.
To understand why bank conflicts can occur we need to un-
derstand how the threads access the shared memory data struc-
ture.Thecodeforloadingthedataintosharedmemoryisshownin
Fig.7.In2Dconvolution,itiscrucialtoassign2-dimensionalwork-
loadstothreadblockstomaximizedatareuse.Inourapproach,the
threadswithinathreadblockcooperativelyloadtheareaneeded
from the input image and store it in shared memory as shown in
Fig.7.ThestatementatLine4setstheinputimagepointertothe
start of the area loaded by the thread block. Note, that this does
not include individual thread indices yet. The for-loops on lines
9 and 10 ensure that each thread loads a different item and that
thethreadscooperativelyloadtherequired2Dareaofpixelsinto
sharedmemory.
## Inmoderngraphicshardware,anysharedmemoryreadorwrite
ofnaddressesthatfallinndistinctmemorybankscanbeserviced
simultaneously, yielding an overall bandwidth that isntimes as
high as the bandwidth of a single module [10]. In CUDA, multi-
dimensionalarraysarewrappedrow-wiseacrossdifferentshared
memorybanks.Whenevertwothreadsfromthesamewarpaccess
differentvaluesinthesamememorybank,asharedmemorybank
conflict occurs, causing the accesses to be serialized. Given the
accesspatterninFig.7,itdependsonthethreadblockwidthand
theconvolutionfilterwidthwhetherornotasharedmemorybank
conflictwilloccur.Notethatwhenthethreadblockwidthisequal
tothenumberofmemorybanks,nosharedmemorybankconflicts
occurasallthreadsineachwarpaccessvaluesindifferentbanks,
independentofthefilterdimensions.
## Fig.8illustrateshowbankconflictsoccurwhenthethreadblock
width is 16 and the convolution filter width is 23. The light gray
coloredvaluesrepresentthevaluesthatbelongtothefirstrowof
pixelsrequiredbythisthreadblock.Thedarkgraycoloredvalues
belong to the second row; note that both rows include border
pixels.Inthetopfigure,bankconflictsoccurasthreads6–15and
16–25 access different values in the same memory banks. In the
bottom figure, bank conflicts are avoided as threads 16–32 are
directedtowardsdifferentmemorybanks.Thiscanbeachievedby
introducing a number of padding columns to the array stored in
shared memory. Padding was introduced as a technique to solve
sharedmemorybankconflictsin[13].
Our approach to avoiding bank conflicts is to extend the
2-dimensional array stored in shared memory with zero or more
padding columns. The width of the array without padding is
defined asS
w
## =F
w
## −1+B
w
. The width of the padded array is
obtainedbyincreasingF
w
## −1tothefirstmultipleofthenumber
ofmemorybanks,S
w
## =⌈
## F
w
## −1
## M
## ⌉×M+B
w
,whereMisthenumberof
memorybanks.Thenewwidthofthearrayischosensuchthateach
consecutive group of threads from the same row (i.e. with same
threadIdx.y)withinasinglewarpstartsatthefirstunusedmemory
bank. This guarantees that all threads within that warp access
valuesindifferentmemorybanks,andthusguaranteesconflictfree
access to shared memory. Note that whenB
w
is a multiple of the
numberofmemorybanksnopaddingisrequired,andwhenB
w
is
lessthanhalfthenumberofmemorybanksthisapproachmayuse
more padding than strictly necessary. However, the advantage of
thisapproachisthatthesamekernelcodeaslistedinFig.7maybe
usedtoobtainabankconflictfreeimplementation.
An alternative approach to avoiding bank conflicts may con-
sider rearranging the order in which threads compute their local
sum. The idea behind this approach is that threads may compute
their local sum in any order, and as such, may direct themselves
todifferentmemorybanksinordertoavoidbankconflicts.There
are two important drawbacks to this approach. First of all, when
threads within a warp compute their local sum in different or-
derings, weights from the convolution filter can no longer be
broadcast,increasingmemorybandwidthconsumption.Secondly,
reordering the computations for threads within the same warp
introduces a significant number of instructions for index calcula-
tions,increasingtheexecutiontime.
The performance of both kernels with and without padding is
showninFig.9,whichclearlyshowsthatthekernelwithpadding
outperformstheonewithoutpaddinginnearlyallcases.Forfilter
size 17×17 in Fig. 9(a) and (b) the performance of both kernels
isexactlythesame.Thisisbecauseforthisparticularfiltersizeall
kernelsrunconflict-freeandnopaddingisrequired.Forfiltersize
## 41×41,theadditionalsharedmemoryrequiredforpaddinglimits
the occupancy and causes a drop in performance larger than the
performancehitcausedbybankconflicts.Fig.9(b)showsthatour
approach for avoiding shared memory bank conflicts also applies
to the GTX480, because cards of the Fermi architecture also have
32memorybanks.Theperformanceacrossdifferentfiltersizesis
lessstableontheGTX680,comparedtotheGTX480,becausedrops
in occupancy have a much larger effect on performance for the
GTX680[14].ThisisbecausetheKeplercardshavefewer,butlarger
SMs. Therefore, the SMs on Kepler are capable of executing more
thread blocks concurrently. However, as the amount of shared
Fig. 8.Mappingsbetweendataandmemorybanksinsharedmemory,bothwithoutpadding(topfigure)andwithpadding(bottomfigure).

B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–2619
ab
Fig. 9.Kernelsexecutedwitha16×16threadblock.Paddingisusedtopreventbankconflicts.(a)showsexecutionontheGTX680and(b)ontheGTX480.
ba
Fig. 10.Kernelsexecutedwitha16×16threadblock.Paddingisusedtopreventbankconflicts.(a)usinga1×2tiledkernel(b)usinga1×4tiledkernel.
memory per SM is the same for both Kepler and Fermi SMs, only
a smaller filter can be executed at higher occupancy. A more
detailed analysis of the implications of both architectures on 2D
convolutionisgiveninSection6.
## Fig.10showstheperformanceforthefullrangeoftestedfilter
sizes using padding to prevent bank conflicts. Fig. 10 may be
comparedtoFig.6toseethatpaddingimprovestheperformance
of the kernel for nearly all filter sizes. The performance drop that
occurs right after the filter width is increased beyond 17 occurs
because of the increase in shared memory use by the padding
columnsthatavoidbankconflicts.Performancedropsintheother
direction, when the filter height is increased, also occur because
the increase in shared memory usage causes a reduction in the
occupancy.
## Convolutionoperationswithlargefiltershavelargeoverlapping
borders between tiles, and thus require more shared memory
per thread block. However, tiling further increases the use of
sharedmemory.Infact,the1×4tiledkernel,showninFig.5(b),
requiresmoresharedmemorythanavailableonthedevicewhen
executed with filter sizes (41×43) and (43×43). This shows
theverylimitedflexibilityofthe1×Ntilingapproach.Therefore,
tiling must be kept to a minimum when the kernel is required to
executeconvolutionoperationswithlargefilters.However,when
only small filters are used, which is typical in many applications,
a higher tiling factor may be applied to achieve more efficient
executionontheGPU.Thenextsectionpresentsouradaptivetiling
approachthataddressesexactlythisissue.
- Adaptive tiling
For many CUDA kernels, such as the matrix multiplication
kerneldescribedin[11],thereexistsaone-size-fits-allbesttiling
factor that can be set at compile time and will create the most
efficientkernelforanyinputsizeusedatruntime.Forconvolution
operations this approach is too restrictive as the efficiency of the
kernel is dictated by the size and shape of the convolution filter.
In this section, we presentAdaptive Tilingas a new optimization
approachforconvolutionoperationsonGPUs.Withadaptivetiling
thetilingfactorisselectedatruntimedependingontheinputdata
andtheresourcelimitationsofthedevice.
Adaptive tiling allows our convolution operations with rela-
tivelysmallfilterstobeexecutedwithhighertilingfactorsandop-
erations with relatively larger filters by kernels with lower tiling
factors. This approach further increases the arithmetic intensity,
especiallyforsmallconvolutionfilters,whichisgivenby
## AI=
## 2×F
w
## ×F
h
## ×B
w
## ×T×B
h
## (F
w
## −1+B
w
## ×T)×(F
h
## −1+B
h
## )×4
## (2)
whereTisthetilingfactor.
In fact, to select a tiling factor at run time means to select a
particularimplementationofakerneltorun.Asmallscriptisused
to generate the variations of the kernel for a set of tiling factors
beforecompilation.Thesekernelsareallincludedinthelibraryand
can be selected by the run-time system. Instead of using a script,
onemightalsouseforexample,C++templates.Ouradaptivetiling
approachworksindependentlyofhowthekernelsaregenerated.
There are two main resource constraints that need to be
considered when increasing the tiling factor: shared memory
and the register file. First, before the tiling factor is increased,
sharedmemoryonlycontainsthepixelsprocessedbythisthread
block and their overlapping borders, using relatively little shared
memory.Moreefficientexecutioncanbeachievedwhenthetiling
factorisincreased,atthecostofincreasingtheamountofshared

20B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–26
ab
cd
Fig. 11.(a)and(b)performanceusingtheadaptivetilingoptimizationonGTX680andGTX480.(c)and(d)thetilingfactorsselectedbytheruntimesystem.
memory the kernel uses. Therefore, the tiling factor can only be
increasedaslongasthetilesandtheborderaroundthemstillfitin
sharedmemory.
Second, as the tiling factor increases, more registers are re-
quiredperthread.Therefore,thetilingfactorcanonlybeincreased
uptothepointwhereonethreadblockconsumestheentireregis-
terfileonanSM.However,thetotalnumberofregistersusedbya
thread block may be reduced, by reducing the number of threads
perthreadblock.Thisslightlyincreasestheuseofglobalmemory
bandwidthasmorethreadblockswillberequiredtocompletethe
computation.However,ifthedecreaseinthreadblocksizeallowsa
furtherincreaseinthetilefactor,thetotalnumberofthreadblocks
doesnotnecessarilyincrease.Thissuggeststhatitmightbeworth-
whiletolowerthenumberofthreadsperthreadblocktoallowfor
highertilingfactors.
## Usingacompile-timefixedthreadblocksize,thehighestpossi-
bletilingfactorisselectedatruntimebasedonthelargestpossible
fitwithinthesharedmemoryavailableonthedeviceandthecon-
volutionfiltersizeoftheoperationathand.Notethatthismeans
each SM can execute no more than one thread block simultane-
ously,becausethissinglethreadblockwillconsumealmostallof
the available shared memory. While this approach yields a very
flexible and efficient implementation on the Fermi, the selection
schemeneedssomefinetuningtobeefficientfortheKeplercards.
TheSMsoftheKeplerarchitectureneedroughlytwiceasmuch
parallelismperSM,comparedtoFermiSMs[14].For2Dconvolu-
tion,increasedparallelismperSMcanonlybeachievedbyincreas-
ingoccupancy,whichmeanseithercreatinglargerthreadblocksor
allowing multiple thread blocks to execute concurrently on each
SM.Bothapproachesforincreasingoccupancyimplyasignificant
increaseintherequiredamountofsharedmemory,whiletheKe-
plerSMsdonothavemoresharedmemorythanFermiSMs.Thatis
whytherun-timeselectionschemeontheKeplerchoosesthehigh-
est possible tiling factor such that two thread blocks can still run
concurrentlyoneachSMforsmallfiltersizes.Forlargerfiltersizes
itisstillefficienttosimplyselectthehighestpossibletilingfactor.
Fig.11showstheachievedperformanceforthe2Dconvolution
kernel that uses the adaptive tiling optimization for the best
performing thread block sizes. The filter dimensions are used to
determinetheresourcerequirementsofthekernel,whicharethen
usedtoselectthebesttilingfactorwithintheresourcelimitations
of the device present at runtime. The edges in the performance
graphs(a)and(b)arecausedbychangesinthetilingfactor.Figures
(c) and (d) show the actual tile factors that were selected by the
run-timesystemtocreatethecorrespondingperformancegraphs
shownin(a)and(b).
The adaptive tiling approach for the GTX680 uses a 32×32
threadblocksize,similartoFig.5.ComparedtoFig.5(b)adaptive
tiling improves the efficiency of 121 out of the 441 tested filter
sizes,fortheotherfiltersizesthesametilingfactorisselectedand
thereforetheperformanceisthesame.Additionally,theadaptive
tiling implementation is able to execute filter sizes 41×43
and 43×43, because the run-time system decreases the tiling
factoriftheresourcerequirementsexceedthatofthedevice.The
relatively large thread block size used on the GTX680 limits the
rangeofpossibletilingfactors,butisnecessarytosupplysufficient
parallelismtotheKeplerSMs.However,thefixedthreadblocksize
of32×32isnotthebestperformingforeachfiltersizewithinour
test range. Therefore, our parameter sweep discussed in the next
section, also uses different thread block sizes for operations with
differentfiltersizes.
- Adaptive tiling combined with loop unrolling
## Oneimportantoptimizationthatwehavenotconsidereduntil
nowisloopunrolling.Loopunrollingintroducestradeoffbetween
flexibility and efficiency, as the number of iterations for all loops
of a given kernel have to be known at compile time. This means
that for each possible filter size we create a unique CUDA kernel
and optimize it individually. Instead of selecting the highest
possibletilingfactorthatstillfitsinsharedmemory,theruntime
system now selects the CUDA kernel with the best performing

B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–2621
combinationofblocksizeandtilingfactorgivenaparticularfilter
size.Wehaveimplementedthisusingalookuptablewhichholds
thisinformationforeachpossiblefiltersizeintheexpectedrange
offiltersizes.
This approach has a number of drawbacks: First of all, the
numberofCUDAkernelsbecomesquitelarge,whichalsoincreases
compilation times. Secondly, the range of filter sizes that may
be used by the applications have to be known at the time the
library is compiled. However, it is important to know exactly
howmuchperformancecanbegainedfromunrollingeachkernel.
Although creating an optimized library using this optimization is
considerably more work, it is still worthwhile considering that
many researchers from the multimedia domain can benefit from
thiseffort.
WehavegeneratedtheunrolledversionsofourCUDAkernels
foreachpossiblefiltersizerangingfrom3to43inbothdimensions.
At the time the kernel is generated, the thread block width and
height as well as the tiling factor have to be known, as these
determine the number of iterations of each unrolled loop. For
eachfiltersize,asearchisperformedthrougharangeofselected
threadblockdimensionsandtilingfactors.Theselectedrangesfor
thread block dimensions are powers of two from 16 to 64 in the
x-dimension and 4 to 64 in they-dimension. The tiling factors
rangefrom1to10.Inthissearch,wehavetestedtheperformance
of 110 (11 block sizes×10 tiling factors) unrolled kernels
generatedspecificallyforeachofthe441evaluatedfiltersizes.The
resultsarestoredinalookuptable,whichforeachfiltersizestores
a reference to the best performing unrolled kernel as well as the
execution parameters required at launch time, such as the tiling
factorandthreadblockdimensions.
## Wheneverthehostcodeofthelibraryisrequiredtoexecutea
2DconvolutionoperationontheGPUatruntime,itusesthelookup
tabletoselectthebestperformingimplementationthatshouldbe
usedbasedonthefilterdimensionsoftheoperationathand.The
lookuptablealsospecifiesthetilingfactorandthreadblockdimen-
sions, which are used to compute several execution parameters,
suchastheamountofdynamicallyallocatedsharedmemory,pos-
siblyincludingpadding,andthetotalnumberofthreadblocksre-
quiredtocompleteexecutionofthekernel.
The lookup table, which is unfortunately too large to be
includedinthistext,essentiallydescribesseveraloftheproperties
oftheunderlyingdeviceandcouldpotentiallybeusedtoguidethe
optimizationprocessofotherkernels.For2Dconvolution,thread
block size 16×32 was the best performing thread block size for
49.7% of the tested filter sizes. In fact, 342 out of the 441 best
performingkernelsuseathreadblockwidthof16.Thismeansour
techniqueforavoidingsharedmemorybankconflicts,asdescribed
inSection3,isusedin77.6%ofthebestperforming2Dconvolution
kernels.Whileusingathreadblockwidthof16increasesresource
usage in terms of shared memory, and possibly reduces the
occupancy, the fact that the thread block size is small, allows
for higher tiling factors. High tiling factors significantly reduce
the number of redundant instructions previously spread across
differentthreads,whichhasalargeimpactontheperformanceof
compute-boundkernels.Theaveragetilingfactorusedinthe441
bestperformingkernelsis4.16,tilingfactor2isusedfor21.3%of
thefiltersizes,factor4in33.6%,andtilingfactorslargerthan4are
usedin34.2%ofthekernels.Thisconfirmsthelimitationsofusing
acompile-timefixedtilingfactorandshowswhyadaptivetilingis
soimportanttoconvolutionoperations.
Fig.12showstheachievedperformanceforthe2Dconvolution
kernelthatusesaspecificallygeneratedCUDAkernelforeachfilter
size.InFig.12,thebestperformingkernelistheonethatperforms
a convolution with filter size 17×43 and achieves about 938.4
GFLOP/s,whichusesathreadblocksizeof16×64andtilingfactor
- More importantly, the smallest and most commonly used 2D
Fig. 12.Performance for 2D convolution using a uniquely generated tiled and
unrolledkernelforeachfiltersize.
filtersize(3×3)improvedfrom135.9withadaptivetilingto251.3
GFLOP/swhencombiningadaptivetilingwithunrolling.
## Theoptimizationapproachpresentedherecanalsobeapplied
to other operations from the image processing domain, including
neighborhoodoperations,suchaserosion,dilation,separablecon-
volution,andanisotropicGaussianfiltering.Separableconvolution,
forexample,considersconvolutionoperationswith2-dimensional
filtersthatmaybesplitintwo1-dimensionalfilters,whichareap-
pliedconsecutivelytoobtainthesameresultaswhenperforminga
full2Dconvolution.Theseparableconvolutionoperationhascon-
siderablylowercomplexity,butunfortunatelycannotbeusedfor
all2Dconvolutionfilters.Wehaveimplementedseparableconvo-
lutionbyimplementingandoptimizingthehorizontalandvertical
## 1-dimensionalfilteringoperationsastwoseparateoperationsand
appliedtheadaptivetilingcombinedwithunrollingoptimization
tobothoperations.
The tested thread block sizes range from 16 to 64 in the
x-dimension and 4 to 64 in they-dimension. The tested range
of tiling factors is from 1 to 20. Note that tiling for the vertical
filtering operation is performed vertically, instead of in the
x-direction as described in Section 2. This is necessary for
increasingdatareusewithinthreadblocks,wherehorizontaltiling
wouldonlyincreasethenumberofborderpixelseachthreadblock
loads, without actually increasing data reuse. Because of the 1D
filters,theseparableconvolutionoperationusesconsiderablyless
shared memory than 2D convolution. Therefore, it is possible to
allowformuchhighertilingfactors.
## Theresultinglookuptableforseparableconvolutionisconsid-
erably smaller than the lookup table for 2D convolution and is
therefore shown in Table 1. The lookup table again provides in-
sights that could guide future optimization searches for similar
kernels. For the horizontal filtering operation we observe thread
blocksize32×4wasthemostefficientforthe10smallestfilters.
## Forlargerfilters,threadblocksize16×8createdthemostefficient
kernelswhencombinedwithtilingfactorsof6orhigher.In11out
ofthe21filtersizesathreadblockwidthof16isused,whichmeans
the kernel also uses our technique for avoiding shared memory
bankconflictsasexplainedinSection3.However,forthevertical
1D-filteringoperationbankconflictscannotoccur,becausenobor-
der pixels are loaded in thex-direction. For the vertical filtering,
threadblocksize32×4isthemostefficientfor18outof21filters
using tiling factors ranging from 3 to 8. Fig. 13 shows the perfor-
manceofthekernelsfromTable1forbothhorizontalandvertical
filtering.
## 6. Evaluation
## Inthissection,wepresentashortevaluationoftheperformance
effects of each individual optimization step for the GTX680. The
performanceresultsofeachoptimizationsteparealsogivenforthe

22B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–26
## Table 1
## Lookuptableforhorizontal(left)andvertical(right)filteringasusedinseparable
convolutionontheGTX680.
## F
w
Tilingfactor   BlocksizeF
h
## Tilingfactor   Blocksize
## 3   432×43   564×4
## 5   432×45   432×4
## 7   532×47   432×4
## 9   432×49   332×4
## 11   432×411   432×4
## 13   832×413   332×4
## 15   832×415   632×8
## 17   832×417   632×8
## 19   832×419   732×8
## 21   832×421   732×8
## 23   716×823   632×8
## 25   716×825   532×8
## 27   716×827   632×8
## 29   716×829   632×8
## 31   716×831   832×8
## 33   716×833   432×8
## 35   616×835   532×8
## 37   616×837   532×8
## 39   616×839   732×8
## 41   816×841   816×8
## 43   816×843   616×8
Fig. 13.PerformanceofseparableconvolutionontheGTX680usingadaptivetiling
combinedwithunrolling.
GTX480andTeslaK20GPUstoshowtheeffectsondifferentarchi-
tectures.Tosimplifythediscussionweonlyshowtheperformance
resultsforthesquarefiltersizesinourtestrange,i.e.3×3,5×5,
etc.
Fig. 14 shows the performance of each optimization step dis-
cussedinthispaperontheGTX680.Theperformanceofthenaive
kernel implementation is limited by the memory bandwidth and
doesnotexceed106.3GFLOP/s.Fig.14clearlyshowsthateachop-
timizationstepweapplyfurtherimprovesperformance.Theadap-
tivetilingoptimizationagainusesafixedthreadblocksizeof32×
32 and dynamically chooses the tiling factor at runtime. The per-
formanceoftheadaptivetilingandthestatically1×4tiledimple-
mentationissimilar,becausetheadaptivetilingselectstilingfactor
4forthemajorityofthesquarefiltersontheGTX680.Notethatfor
filter size 43×43 the statically 1×4 tiled implementation can-
notexecute,asitrequiresmoresharedmemorythanavailableper
SM, while the adaptive tiling algorithm simply selects to execute
the 43×43 filter with tiling factor 3. Our final optimization step
demonstratesaperformanceimprovementofuptoafactorof9.14
overthenaiveimplementation.Thisisnotonlyduetotheunrolling
optimization,butalsobecausethebestperformingcombinationof
threadblocksizeandtilingfactorisselectedforeachindividualfil-
ter.Notethatunrollingtheloopsisonlypossiblewhenthenumber
ofiterationsofallloopsisknownatcompiletime.Thismeansthat
anindividualimplementationiscreatedforeachfiltersize.
Fig. 14.Performanceforseveraldifferentimplementationsofthe2Dconvolution
problemontheGTX680.
Fig. 15.Performanceforseveraldifferentimplementationsofthe2Dconvolution
problemontheGTX480.
The performance effects of each optimization step on the
GTX480 is shown in Fig. 15. The performance of the naive imple-
mentationontheGTX480isquitesimilartothenaiveperformance
ontheGTX680.Forfiltersizes3×3and5×5,thenaiveimplemen-
tationoutperformstheimplementationthatexplicitlyusesshared
memory.Thisisbecausethenaiveapproachbenefitsfromthefact
that global memory loads are cached in L1 on the GTX480. The
sharedmemoryimplementationalsobenefitsfromcachinginL1,
albeitwiththeintroductionofasmalloverheadforadditionalin-
structionsandsynchronization.However,usingsharedmemoryis
veryimportanttoachievinghighperformance,forlargerfiltersizes
orwhenthetilingfactorisincreased.Forfiltersize43×43,thetiled
1×4 implementation cannot execute, because it requires more
memory than available on the device. The adaptive tiling imple-
mentationdoesnotsufferfromthisissue,becauseitsimplyselects
theimplementationwiththelargestpossibletilingfactorthatstill
fitsinsharedmemory.Theadaptivetilingimplementationusesa
threadblocksizeof16×32,whichmeansitalsousesourapproach
for avoiding shared memory bank conflicts as explained in Sec-
tion 3. The adaptive tiling combined with unrolling implementa-
tionagainimprovessignificantlyovertheotherimplementations.
TheGTX680(Fig.14)outperformstheGTX480(Fig.15)formost
filter sizes. However, the difference is less than what one would
expect from the theoretical peak performance of both devices.

B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–2623
Fig. 16.Performanceforseveraldifferentimplementationsofthe2Dconvolution
problemontheK20.
There are several architectural differences between Kepler and
Fermithatlimittheperformanceof2Dconvolutionoperationson
Kepler cards. The most important one for 2D convolution is that
## Keplerhas6timeslesssharedmemorypercomputecoreineach
SMcomparedtoFermi.Therefore,itbecomesmuchhardertokeep
all192coresinanSMoccupied.Whenthereisnotenoughshared
memory,itisnotpossibletoeitherincreasethethreadblocksizeor
toincreasethenumberofthreadblocksthatrunsimultaneouslyon
eachSM.ThiscauseslowoccupancyofeachSMandthereforelow
utilization of the 192 compute cores, as well as lower utilization
of global memory bandwidth and higher dependence on long
latency operations. All involved factors explain why performance
isexpectedtobefurtherfromthetheoreticalpeak.
## Fig.16showstheperformanceofeachoptimizationsteponthe
K20. The performance of the naive implementation on the K20 is
about 24% faster than the naive performance on the GTX480 and
GTX680.ItisimportanttonotethatFig.16againshowsthateach
optimizationstepweapplyfurtherimprovesperformance.
TheK20alsohas48KBofread-onlycacheatL1thatmaybeused
by global memory loads for read-only data [7]. This requires that
the global memory loads are explicitly enclosed by the__ldg()
intrinsic. The compiler transforms these loads into non-coherent
loads that pass through the read-only cache. In Fig. 16, our most
efficient implementation (adapt+unroll+nc) uses this specific
optimization.Thefactthattheperformanceofmanyofthekernels
in Fig. 16 improves by this optimization also indicates that the
performanceisrelatedtotheachievedglobalmemorybandwidth.
Note that Fig. 16 shows only a very small subset of the filters
thatweretestedandthatperformancevarieswiththefiltersizein
bothdimensions.Forexample,forfiltersize17×43ouradaptive
tilingcombinedwithunrollingoptimizationexecutesatjustover
a teraflop. Finally, the adaptive tiling combined with unrolling
optimization, both with and without using the read-only cache,
demonstrates a performance improvement of up to a factor 8.3
overthenaiveimplementation.
We observe that the tiling factors used in the best performing
kernels on the GTX680 and the K20 are generally lower than on
theGTX480.However,selectingthetilingfactoratruntimeiseven
moreimportantontheGTX680andtheK20,thanontheGTX480.
## Whilethetilingfactorsforthebestperformingkernelsrangefrom
2 to 10 on the GTX480 and from 1 to 8 on the K20, tiling factor
## 4isthemostcommonforbothcardsaccountingfor44.2%onthe
GTX480andonlyfor24.9%ontheK20.
The lookup tables for both the GTX680 and the K20 also
demonstratethatselectingthethreadblocksizeatruntimeisstill
very important. We observe that the thread block sizes used in
Fig. 17.Speedup of spatial solution over the FFT-based approach. Filter sizes in
thegrayareaareexecutedfasterwithourimplementationthanwiththeFFT-based
implementation.
the best performing kernels on the Kepler cards are on average
56.5%largerthanontheGTX480.Thisconfirmsthatlargerthread
blocksarerequiredtoachievesufficientoccupancyontheKepler
cards. Thread block size 16×64 is the most common among the
best performing kernels on the GTX680 and K20, accounting for
49.7% and 36.5%. For both Kepler cards, the vast majority of the
bestperformingkernelsusethreadblockwidthof16,83.2%onthe
GTX680 and 92.1% on the K20. Therefore, for most filter sizes in
ourtestrange,thebestperformingkernelhasathreadblockwidth
thatrequirestheuseofourapproachtoavoidsharedmemorybank
conflicts,asdescribedinSection3.
## 7. Limitations
A 2D convolution operation in geometric space can also be
implemented as a point-wise multiplication in frequency space.
Nvidia’sWhitepaper[15]explainstheirimplementationof2Dcon-
volutionbasedontheCUFFTlibrary.Theadvantageofthismethod
isthatithaslowercomplexityforverylargefilters.Thispresents
a limitation that is inherent to spatial solutions to the 2D convo-
lution problem. We therefore present a short comparison of both
approaches.
TheFFTapproachhassomeminorlimitationsinthefactthatit
usesmorememorythanaspatialsolution.Theinputimageneeds
toberoundeduptothenearestpoweroftwoifthepaddeddimen-
sionislessthanorequalto1024,ortothenearestmultipleof512
otherwise.Thenthefilteriswrappedandstoredinanotherimage
ofthesamesize,roughlydoublingtheamountofGPUmemoryre-
quired for the operation. However, due to the lower complexity
the FFT-based approach will become increasingly faster than any
spatial solution as the filter size increases. The question is which
approachisfastestforwhichrangeoffiltersizes.
We have tested both our implementation and Nvidia’s imple-
mentationfortheFFT-basedapproach[15]thatusestheCUFFTli-
brary, on the GTX680 given an image size of 4096×4096 for a
filter range of 3 to 43 elements in both dimensions. The contour
plot,showninFig.17,showstherelativespeedupofourapproach
over the FFT approach. For the most commonly used filter sizes,
3×3and5×5,thespeedupofourapproachovertheFFT-based
approach is 18.96 and 10.09, respectively. Operations with filter
sizesbelowandleftofthe‘1’line,thegrayareainthefigure,exe-
cutefasterwithourimplementationthanwiththeFFT-basedim-
plementation. However, for very large filter sizes the FFT-based
approachisfaster,simplybecauseofthelowercomplexityofthe
algorithm.
It should be noted that the use of very large filters is rare in
MMCA applications. It is however also possible to implement a

24B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–26
library routine for 2D convolution such that a run time choice is
madebetweenourimplementationandanFFT-basedimplemen-
tationbasedonthefiltersizeoftheoperationathand.Weconsider
thisasfuturework.
- Related work
The work presented in this paper extends earlier work on
implementingandoptimizingconvolutionoperationsfortheGPU.
VeryearlyworkonimplementingconvolutionoperationsonGPUs
usedshaderprogramsingraphicsAPIs[16,17],whichcansupport
onlylimitedfiltersizesduetothelimitednumberofinstructions
per pixel. This section discusses more recent work which is all
basedonCUDA.Wealsopresentperformanceresultstocompare
ourmethodofusingsharedmemoryfortiledconvolutionagainst
a different method suggested by Hwu [9]. Finally, we compare
ouroptimizedkernelswithkernelscreatedbytheauto-optimizing
source-to-sourcecompilerbyYangetal.[12].
OpenCV[18]isanopensourcelibraryforComputerVisionand
containsseveralimplementationsformanyimageprocessingop-
erations. OpenCV has a special module named GPU operations,
whichalsocontainsvariousimplementationsforconvolutionop-
erations. The 2D convolution operations discussed in this paper
correspondwiththefilter2DmethodinOpenCV.OpenCV’scurrent
implementationof2DconvolutionforGPUsusesCUDAandislim-
ited to 2D filters with a total size not greater than 256 elements.
The only optimization that is applied to their CUDA implementa-
tionistheuseofconstantmemorytostoretheconvolutionfilter.
## Nosharedmemoryorotheroptimizationsareused.
## Russoetal.[19]comparevariousimplementationsofseparable
convolution on GPUs using CUDA, on FPGAs using Verilog and on
CPUs using C and Matlab. The optimizations that are applied to
their CUDA implementation consist of using shared memory and
static1×Ntiling.TheyconcludethatCUDAonGPUsoutperforms
theirFPGAandCPUimplementations.
Hartungetal.[20]comparevariousimplementationsof2Dcon-
volution using CUDA on GPUs and ANSI-C and OpenMP on CPUs.
Theyrefertotheimplementationof2Dconvolutioninthespatial
domain as applying a spatially-varying kernel. The optimizations
theyapplytotheirCUDAimplementationareusingsharedmem-
oryandstatic1×Ntiling.TheyconcludethattheirCUDAimple-
mentationoutperformstheirvariousCPUimplementations.
Nugteren et al. [21] introduce a classification of algorithmic
skeletonimplementationsforimageprocessing,whichenableGPU
code generation and mapping of the algorithm to the GPU hard-
ware. 2D convolution is discussed as an example of the skeleton
class for neighborhood-to-pixel image processing operations. Lo-
caldatareuseisexploitedthroughtheuseofsharedmemory.The
thread block size is increased to the maximum allowed by the
hardwaretominimizetheamountofborderpixelssharedbetween
threadblocks.Nofurtheroptimizationstoincreasearithmeticin-
tensityorinstructionefficiency,suchas1×Ntiling,areapplied.
Al Umairy et al. [22] attempt to improve the performance of
Nvidia’s FFT-based implementation of 2D convolution. They op-
timize towards a specific use case within the domain of elec-
tromagnetic diffraction modeling. While they argue that many
applications use small convolutions, it is unclear if this refers to
small input data or small convolution filters. Their conclusion is
thattheCUFFTlibraryshouldbeextendedwithanoperationthat
directlyperformsacomplete2Dconvolutionoperation,asopposed
to using separate forward and inverse FFT transformations. Their
solution is not compared to an implementation in the spatial do-
main.
Dastgeer et al. [23] have developed two performance metrics
based on either occupancy or tiling factor for our Adaptive Tiling
optimization,basedonourearlierwork[24].Thesemetricshelpto
guidethedecisionmakingprocessinselectingthetilingfactorat
runtime.Theirexperimentalresultsconfirmthatmaximizingthe
tilingfactorratherthanoccupancyresultsinthebestperformance
for GPUs of the Fermi architecture and older cards. As we have
shown in Section 4, GPUs of the Kepler architecture require a
more balanced approach. In this paper, we also show that even
more efficient implementations can be obtained by combining
adaptive tiling with unrolling and choosing the best performing
combination of thread block size and tiling factor for each filter
size.
The 2D convolution problem is well known in the context of
GPUComputingandisoftenusedasexampletoillustrateorteach
howconstantandsharedmemorymaybeusedtoreducetheglobal
memory bandwidth consumption of a kernel [25,9,26]. However,
these descriptions of the optimization process do not go beyond
the discussion of well-known techniques presented in Section 2
andonlyconsiderastatic5×5filtersize.
## Incontrasttoourapproachofusingsharedmemory(explained
in Section 2), Hwu [9] suggests keeping the number of elements
in shared memory equal to the number of threads in the block.
This simplifies the loading process, as each thread loads only one
element from the input image. As a consequence, not all threads
can be active during the computation as the threads near the
edgeofthetiledonothaveenoughinformationtocompletetheir
computation.Therearetwoimportantdrawbackstothisapproach.
First, as some threads are not participating in the computation,
morethreadblocksmustbecreatedtocompletethecomputation.
## Thislimitstheopportunityfordatareusewithinthethreadblock
and increases overall global memory bandwidth consumption.
## Secondly,thisapproachdoesnotscalewithincreasingfiltersizes.
## Forthe5×5filtersize,threadsinthelastfourrowsandcolumns
donotparticipateinthecomputation.Asthefiltersizeisincreased,
the number of active threads within each thread block drops
dramatically. More importantly, while the opportunity for data
reuseincreaseswithlargerfiltersizes,datareuseinthisapproach
actually decreases as there are less active threads in each thread
blocktoreusedata.
The question that remains is which approach executes more
efficiently considering only the 5×5 2Dconvolution filter. We
haveimplementedbothapproachestousingsharedmemoryand
unrolled both kernels since the filter size is known at compile
time. We have tested on GTX480 with an image of 4096×4096
and a static filter of 5×5. Our implementation of Hwu’s ap-
proachachieves180.8GFLOP/s,whileourapproachofhavingsome
threadsloadmultipleelementsandkeepingallthreadsactivedur-
ingcomputationachieves229.8GFLOP/s.
We have also compared our optimized kernels with kernels
createdbytheauto-optimizingsource-to-sourcecompilerbyYang
et al. [12]. Their GPGPU compiler takes a slightly modified naive
kernelasinputandoutputsanoptimizedkernel.Theoptimization
strategy that the source-to-source compiler applies to the 2D
convolution kernel is primarily focused on using shared memory
to convert noncoalesced global memory accesses into coalesced
memory accesses. To this end, the compiler assumes that the
number of loop iterations is always a multiple of 16. This results
inakernelwherethedatarequiredforthefirst16iterationsofthe
innermostloopisloadedintosharedmemorybyallthreadsinthe
threadblock,followingthedesignthatsomethreadsloadmultiple
elements. This guarantees coalesced memory accesses, as well as
data reuse within each block of 16 iterations for the innermost
loop.
Unfortunately, many opportunities for data reuse are unex-
ploited. After the first 16 iterations the data in shared memory is
overwrittenwiththedatarequiredforthenext16iterationswhich
areagainloadedfromglobalmemory,althoughtheelementscould
havebeenreusedfromsharedmemoryaswell.Incontrast,ourim-
plementationtriestomaximizedatareuseinbothdimensionsand

B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–2625
foralliterations,insteadofonlywithineachblockof16iterations
inthehorizontaldimension.However,wedobelievethattheop-
timizationtechniquespresentedinthispapercouldbeintegrated
intoanauto-optimizingcompilersuchastheGPGPUCompiler.
## Toconfirmthatourapproachyieldsamoreefficientkernel,we
have tested the performance of a 2D convolution kernel created
for a static filter size of 32×32. On the GTX480 with an input
imageof4096×4096,theoptimizedkernelcreatedbytheGPGPU
compilerfora32×32filteringoperationtakes143.7ms,achieving
239.0 GFLOP/s. Our optimized kernel took 45.8 ms for the same
operation,achieving749.6GFLOP/s.
- Conclusions and future work
## Convolutionoperationsareanessentialtoolinsignalandimage
processingandaretypicallyresponsibleforalargefractionofthe
application’sexecutiontime.Inthispaper,wehavediscussedthe
implementation and optimization of convolution operations for
thedomainofmultimediacontentanalysis(MMCA).Aspartofour
work on transparent parallelization tools for the MMCA domain,
ourgoalistoobtainanefficientlibrarybasedimplementationfor
convolutionoperations.
We have evaluated the performance effects of many different
implementations for the 2D convolution operation and separable
convolutionontheGTX680,GTX480andTeslaK20graphicscards.
We have introduced a new approach for solving shared memory
bank conflicts in the context of convolution operations as well as
anoptimizationapproach,calledadaptivetiling,forimplementing
efficient,yetflexible,convolutionoperationsonmodernGPUs.We
have also presented an implementation that combines adaptive
tiling with loop unrolling to obtain a less flexible, yet highly ef-
ficient implementation. The approach is less flexible, as the filter
sizesusedbytheapplicationatruntimehavetobeknownatcom-
piletime.Whiletheapproachpresentedinthispaperfocuseson2D
convolution,thetechniquesalsoapplytoseparableconvolution.
## Alloptimizationscombineddohaveaverylargeimpactonper-
formance.Moreimportantly,eachoptimizationstepweintroduce
provides a significant performance improvement for each tested
GPU.FortheGTX680,themostcommonlyused2Dfiltersizeinim-
ageprocessing(3×3)executesat66.6GFLOP/susingthefirstnaive
implementation, 133.2 GFLOP/s when adaptive tiling is used, and
finally 251.3 GFLOP/s using tiling combined with loop unrolling.
ThebestperformingkernelontheGTX680istheonethatperforms
aconvolutionwithfiltersize17×43andachieves938.4GFLOP/s,
using a thread block size of 16×64 and tiling factor 6. GPUs of
the Kepler architecture have much less shared memory and less
globalmemorybandwidthpercomputecorecomparedtoGPUsof
theFermiarchitecture.Asaresult,thecomputeperformanceof2D
convolution operations does not come as close to the theoretical
peak performance as on the GTX480. For example, our best per-
forming kernel on the K20 executes a 2D convolution operation
withfiltersize17×43andachievesabout1003GFLOP/s,whichis
onlyat28.5%ofthetheoreticalpeakperformance.
## Thelookuptablestorestheresultsofasearchthroughasetof
generated unrolled CUDA kernels and stores which thread block
size and which tiling factor was used in the creation of the best
performing kernel for each filter size. The resulting table essen-
tiallydescribessomeofthepropertiesoftheunderlyingdeviceand
couldpotentiallybeusedtoguidetheoptimizationprocessofother
kernels.Thelookuptablealsodemonstratestheimportanceofour
approachforsolvingsharedmemorybankconflicts,whichenabled
ustoalsousethreadblockswithawidthof16threadsinaneffi-
cientmanner.For2DConvolutionontheGTX480,76.2%ofthebest
performingkernelsuseathreadblockwidthof16threads.Forthe
GTX680 and the K20, even 83.2% and 92.1% of the best perform-
ing kernels use a thread block width of 16 and therefore require
paddingtoavoidbankconflicts.Whilepaddingincreasesresource
usageintermsofsharedmemory,andpossiblyreducestheoccu-
pancy,thefactthatthethreadblocksizeissmall,allowsforhigher
tilingfactors.Hightilingfactorssignificantlyreducethenumberof
redundantinstructionspreviouslyspreadacrossdifferentthreads,
which has a large impact on the performance of compute-bound
kernels.
## Ourevaluationsshowthelimitationsofimplementingconvolu-
tionoperationswithacompiletimefixedtilingfactor.Thelookup
tablesfor2Dconvolutionandseparableconvolutiondemonstrate
theimportanceofouradaptivetilingapproach.Forexamplein2D
convolutionontheGTX480,tilingfactor2isusedfor24.0%ofthe
filtersizes,factor4in44.2%,andtilingfactorslargerthan4in31.8%.
Selecting the tiling factor at run time is even more important on
theGTX680andtheK20.Whilethetilingfactorsforthebestper-
forming kernels range from 2to 10 on the GTX480 and from 1 to
8ontheK20,tilingfactor4isthemostcommonforbothcardsac-
counting for 44.2% on the GTX480 and only for 24.9% on the K20.
## Thisagainshowswhyouradaptivetilingapproachissoimportant
to optimizing convolution operations. Our evaluation also shows
thatselectingthethreadblocksizeatruntimeisalsoveryimpor-
tantforhighperformance.Weobservethatthethreadblocksizes
usedinthebestperformingkernelsontheKeplercardsareonav-
erage 56.5% larger than on the GTX480. This confirms that larger
threadblocksarerequiredtoachievesufficientoccupancyonthe
## Keplercards.
FFT-based implementations of the 2D convolution operation
havealowercomplexityforconvolutionoperationswithverylarge
convolution filters, compared to spatial implementations such as
the ones discussed in this paper. Therefore, for very large 2D
convolution filters an FFT-based implementation will outperform
any spatialsolution tothe 2D convolution problem. However, for
themostcommonlyused2Dfiltersizes,3×3and5×5,thespeedup
ofourapproachoverNvidia’sFFT-basedapproachontheGTX680
isafactor18.96and10.09,respectively.
The lookup tables used for selecting the most efficient tiled
andunrolledkernelimplementationaretightlylinkedtoaspecific
GPU architecture. Therefore, future work is directed towards
developingperformancemodels,asconstructingthelookuptable
currentlyrequiresaconsiderableamountofperformancetesting.
## Wehavemadethesourcecodeofourkernelsavailablefromthe
firstauthor’shomepageaspartofthedata-parallelParallel-Horus
programmingmodel.ThelookuptablesforalltestedGPUsandour
performancemeasurementdataisalsomadeavailableontheweb.
Seehttp://www.cs.vu.nl/~ben/mp/Convolution2D_data/.
## Acknowledgments
## Wewouldliketothanktheanonymousreviewersfortheirvalu-
ablecommentsandsuggestions.Thispublicationwassupportedby
theDutchnationalprogramCOMMIT.
## References
[1] C.Snoek,M.Worring,J.Geusebroek,D.Koelma,F.Seinstra,A.Smeulders,The
semantic pathfinder: using an authoring metaphor for generic multimedia
indexing, IEEE Transactions on Pattern Analysis and Machine Intelligence 28
## (10)(2006)1678–1689.
[2] A. Galizia, D. D’Agostino, A. Clematis, A grid framework to enable parallel
andconcurrentTMAimageanalysis,InternationalJournalofGridandUtility
## Computing1(3)(2009)261–271.
[3] A.Plaza,etal.,Commoditycluster-basedparallelprocessingofhyperspectral
imagery,JournalofParallelDistributedandComputing66(3)(2006)345–358.
## [4] F. Seinstra, J. Geusebroek, D. Koelma, C. Snoek, M. Worring, A. Smeulders,
## High-performancedistributedimageandvideocontentanalysiswithparallel-
horus,IEEEMultimedia14(4)(2007)64–75.
[5] Nvidia,GeForceGTX680,NVIDIACorporationWhitepaper,2012.

26B.vanWerkhovenetal./FutureGenerationComputerSystems30(2014)14–26
[6] Nvidia,FermiComputeArchitecture,NVIDIACorporationWhitepaper,2010.
[7] Nvidia,KeplerGK110Architecture,NVIDIACorporationWhitepaper,2012.
[8] S. Williams, A. Waterman, D. Patterson, Roofline: an insightful visual
performancemodelformulticorearchitectures,CommunicationsoftheACM
## 52(4)(2009)65–76.
[9] W.Hwu,Lecturenotes,2011.
http://courses.engr.illinois.edu/ece408/fall2011/ece408_syll.html.
[10] Nvidia,CUDAProgrammingGuide,2013.http://docs.nvidia.com/cuda/.
[11] S. Ryoo, C. Rodrigues, S. Stone, S. Baghsorkhi, S. Ueng, J. Stratton, W. Hwu,
ProgramoptimizationspacepruningforamultithreadedGPU,in:Proceedings
ofthe6thAnnualIEEE/ACMInternationalSymposiumonCodeGenerationand
Optimization,ACM,2008,pp.195–204.
[12] Y.Yang,P.Xiang,J.Kong,H.Zhou,AGPGPUcompilerformemoryoptimization
and parallelism management, in: Proceedings of the 2010 ACM SIGPLAN
Conference on Programming Language Design and Implementation, ACM,
## 2010,pp.86–97.
[13] G. Ruetsch, P. Micikevicius, Optimizing matrix transpose in cuda, in: NVIDIA
CUDASDKApplicationNote,2009.
[14] Nvidia,KeplerTuningGuide,NVIDIACorporationWhitepaper,2012.
[15] V.Podlozhnyuk,FFT-based2DConvolution,NVIDIACorporationWhitepaper,
## 2007.
[16] B. Payne, S.O. Belkasim, G. Owen, M.C. Weeks, Y. Zhu, Accelerated 2D image
processingonGPUs,ComputationalScience–ICCS2005(2005)256–264.
[17] O.Fialka,M.Cadik,FFTandconvolutionperformanceinimagefilteringonGPU,
in: Tenth International Conference on Information Visualization, IEEE, 2006,
pp.609–614.
[18] OpenSourceComputerVision,OpenCV2.4.5,2013.http://www.opencv.org/.
[19] L.M. Russo, E.C. Pedrino, E. Kato, V.O. Roda, Image convolution processing:
a GPU versus FPGA comparison, in: 2012 VIII Southern Conference on
ProgrammableLogic,SPL,IEEE,2012,pp.1–6.
[20] S. Hartung, H. Shukla, J.P. Miller, C. Pennypacker, GPU acceleration of image
convolution using spatially-varying kernel, in: 2012 19th IEEE International
ConferenceonImageProcessing,ICIP,IEEE,2012,pp.1685–1688.
[21] C. Nugteren, H. Corporaal, B. Mesman, Skeleton-based automatic paralleliza-
tionofimageprocessingalgorithmsforGPUs,in:2011InternationalConfer-
enceonEmbeddedComputerSystems,SAMOS,IEEE,2011,pp.25–32.
[22] S.A.AlUmairy,A.S.VanAmesfoort,I.D.Setija,M.C.VanBeurden,H.J.Sips,On
theuseofsmall2dconvolutionsonGPUs,in:ComputerArchitecture,Springer,
## 2012,pp.52–64.
[23] U. Dastgeer, C. Kessler, A performance-portable generic component for 2d
convolutioncomputationsonGPU-basedsystems,in:Proc.MULTIPROG-2012
WorkshopatHiPEAC-2012,Paris,2012,pp.1–12.
[24] B.vanWerkhoven,J.Maassen,F.Seinstra,Optimizingconvolutionoperations
in cuda with adaptive tiling, in: Second Workshop on Applications for Multi
and Many Core Processors, A4MMC at ISCA 2011, San Jose, California, 2011,
pp.1–12.
[25] J. Stam, Convolution Soup: A case study in CUDA optimization, 2009.
http://www.nvidia.com/content/GTC/documents/1412_GTC09.pdf.
[26] W. Hwu, Convolution Lab, 2011. http://courses.engr.illinois.edu/ece408/
fall2011/MPs/MP3-README.txt.
Ben van WerkhovenisaPhDstudentintheDepartment
of Computer Science at VU University Amsterdam, the
Netherlands. His current research interests include high-
performancedistributedcomputingonlargecollectionsof
multi-andmany-coreprocessorswith themainfocuson
developing efficient high-level programming models for
suchplatforms.
Jason MaassenisaneScienceengineerattheNetherlands
eScienceCenterandcurrentlyworksontheeSalsaclimate
modellingproject.
Henri E. BalisafullprofessorintheDepartmentofCom-
puterScience,whereheheadstheHighPerformanceDis-
tributedComputingresearchgroup,atVUUniversityAm-
sterdam,theNetherlands.
Frank J. Seinstrais a senior eScience Engineer and Exec-
utive Board member at the Netherlands eScience Center,
wherehecoordinatestheresearchanddevelopmentofin-
novative eScience solutions in multidisciplinary research
projects.