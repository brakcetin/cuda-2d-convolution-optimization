

2020IEEEInternationalConferenceonClusterComputing(CLUSTER)
OptimizingGPUMemoryTransactionsfor
ConvolutionOperations
GangzhaoLu
ComputerScienceandTechnology
HarbinInstitute
ofTechnology
## China
lugangzhao@hit.edu.cn
WeizheZhang
ComputerScienceandTechnology
HarbinInstitute
ofTechnology
## China
wzzhang@hit.edu.cn
ZhengWang
SchoolofComputing
## University
ofLeeds
UnitedKingdom
z.wang5@leeds.ac.uk
Abstract-Convolutioncomputationisacommonoperation
indeepneuralnetworks(DNNs)andisoftenresponsiblefor
performancebottlenecks
duringtrainingandinferencing.Ex-
istingapproachesforacceleratingconvolutionoperations
aim
toreducecomputationalcomplexity.However,thesestrategies
oftenincreasethememoryfootprintwith
extramemoryaccesses,
therebyleaving
muchroomforperformanceimprovement.This
paperpresentsanovelapproachtooptimizememoryaccess
forconvolutionoperations,specificallytargeting
GPUexecution.
## Ourapproachleveragestwooptimizationtechniquestoreduce
the
numberofmemoryoperationsforconvolutionoperations
performedonthewidth
andheightdimensions.Forconvolu-
tioncomputationsonthewidthdimension,
weexploitshuffle
instructionstoexchangetheoverlappedcolumnsofthe
inputfor
reducingthe
numberofmemorytransactions.Forconvolution
operationsontheheightdimension,wemultiplyeachoverlapped
rowofthe
inputwithmultiplerowsofa filtertocomputemultiple
outputelementstoimprovethedatalocalityofrowelements.
Weapplyourapproachto2Dandmulti-channel2Dcon-
volutionson
anNVIDIA2080TiGPu.For2Dconvolution,
ourapproachdeliversover2xfasterperformancethanthe
state-of-the-artimageprocessinglibraries.
Formulti-channel2D
convolutions,weobtainupto1.3xspeedupsoverthequickest
algorithmofcuDNN.
IndexTerms-PerformanceOptimization,Convolution,Mem-
oryOptimization,GPUs
## I.INTRODUCTION
## Convolutionisafundamentalbuildingblockformany
applicationtasks,includingimageandvideoprocessingand
machinelearningmodels.However,convolutionoperationsare
computationandmemoryintensiveforrepresentativeimage
andmachinelearningprocessingtasks.Therefore,thereisa
criticalneedforacceleratingconvolutionoperations.
## Awiderange
oftechniqueshavebeenproposedtoacceler-
ateconvolutionoperations
## [1],[2],  [3],  [4],  [5],  [6],  [7],[8].
Amongthesemethods,generalmatrixmultiplication(GEMM)
[6],[7],fastfouriertransform(FFT)
## [2]andwinograd[3]
methodsarethebroadlyadoptedones.However,thesemeth-
odscanincurmanyGPUglobalmemorytransactions(or
memoryaccesses)duringthetransformationphaseduetothe
involvement
ofmatrixmultiplicationsandduplicateelements
ofthetransformedmatrices.
## Inthiswork,weintroducetwonoveloptimizationtech-
niquesforoperationsperformedoncolumnsandrowstoim-
## 978-1-7281-6677-3/20/$31.00©2020IEEE
## D0110.1109/CLUSTER49012.2020.00050
## 399
provethememoryperformanceofconvolutionoperations.The
firsttechniqueexploitscolumnreusebyutilizingshufflein-
structions(supportedbybothCUDAandOpenCLandhenceis
applicabletomainstreamGPUs)toexchangeelementsamong
threadswithinthesameGPUwarp(orworkinggroup).Inthis
way,wecanavoidreloadingthesameelementssharedamong
differentthreads.
## Wefurtherextendtheshuffleinstructions
tofacilitatedynamicindexing.Thesecondtechniquetargets
rowreusebymultiplyingoneinputrowwithmultiplerows
of
a  convolutionalkernel(orfilter)tocomputemultipleoutput
elements.Thisstrategyimprovesthedatalocality
ofelements
withina  row,reducingthenumber
ofmemorytransactions
comparedwiththat
oftheexistingconvolutionprocessing
pipeline.
Weapplyouroptimizationtechniquesto2Dandmulti-
channel
2Dconvolutionoperationsandevaluatethemonan
NVIDIA2080TiGPU.
## Wecompareourapproachagainst
a  range
ofhighlyoptimizedconvolutionlibraries,including
cuDNN[9].Experimentalresultsshowthatourapproach
deliversover
## 2xfasterperformanceoverthebest-performing
competitivestrategy.
## Thispapermakesthefollowingtechnicalcontributions:
•Itpresentsanovelalgorithmforcolumnreuse(Sec-
tionII-A),whichhasa bettergeneralizationabilityover
priorwork.
•Itpresentsa  novelrowreusealgorithmtoimprovethe
datalocalityandreducethenumber
ofglobalmemory
transactionswhenperformingconvolutionintherow
direction(SectionII-B).
•Itdescribesa  novelmethodfortransformingdynamic
indicesintostaticindices.Ourapproachenhancesregister
promotion,leadingtobetterperformance(SectionIV).
II.OURApPROACH
## Inthissection,wedescribeourtwooptimizations,column
reuse(SectionII-A)androwreuse(SectionII-B),forreducing
GPUmemorytransactionsforconvolutionoperations.
A.ColumnReuseOptimization
1)Standardconvolution:
Figurelashowsa  standard2D
convolutionoperation,operatingonasingle-channelinput.
## Here,eachthreadloadsthefirstcorrespondinginputelements
Authorized licensed use limited to: ULAKBIM UASL - GAZI UNIV. Downloaded on May 17,2026 at 06:18:30 UTC from IEEE Xplore.  Restrictions apply.

step1step3step2
## ::~)!:,..~y~
## ~--~I~W1~~
t212l'lJlM'6:
t3~vr'iiII~YG=l
~--~IIIw:L.J
step1step4step3step5step2
(a)Directconvolution:Eachthreadloads5 input(b)Optimizedconvolution:eachthreadretrieves(c)Ourapproach:eachthreadretrievesitssecond
elementsfromglobalmemory.itsthirdelementfromthecorrespondingthread.andfourthelementsfromcorrespondingthreads.
## Fig.
1.Illustrationofdirectandoptimizedconvolution.Weusea 5 x 5filterandeachthreadcalculatestheconvolutionforoneoutputelement.Thisexample
showshowa threadprocessesthefirst5  correspondinginputelements.
fromtheGPUglobalmemory.Giventhattheindicesofthese
elementsare  contiguous,i.e.,0,
1,2,and3  inthisexample,
concurrentaccesstotheseelementswillbecoalescedtoforma
singlememorytransaction.Aftercompletingstep5,eachpair
ofadjacentthreadswillhavefourduplicateinputelements.
2)Anoptimizedversion:Toeliminatetheredundantloads,
wecouldusetheshuffleinstructionstoexchangeinputel-
ementsamongdifferentthreads.Figure1bdepictssuchan
optimization.Specifically,insteps1 and2
ofFigureIb,each
threadloadsthecorrespondingfirstandfifthinputelements
fromtheglobalmemory.Instep3,eachthreadutilizesthe
shuffleinstructiontoretrievethethirdelementfromanother
thread.
## Sincetheindicesandtheaccesspatternto
iTemparenot
availableatcompile-time,thecompilercannotdecidewhich
oftheelementsiniTempwillbefrequentlyaccessedandhas
toplace
iTempinthelocalmemorywhichwouldstillincur
anaccesslatency
ofaround500cycles.Ifwecanpromote
registerallocationfor
iTemp,wecanthenfurtherimprove
theperformance
ofconvolution.
3)Ourapproach:Ourcolumnreuseapproach(Figurelc)
is describedinAlgorithm
1.Here,wefirstloadthecorrespond-
ingfirstandfifthinputelementsinto
iTempbeforepassingit
toAlgorithm
1.Then,wepacktwo32-bitelementsintoa 64-
bitvariable
exchange,whereiTemp[4]andiTemp[O]arethe
highandlow32bits,respectively(Line2).Asthreads
toand
t1 willprovidethefifthelementofthedatatheyload,which
arethehigh32bits
ofexchange,werightshiftexchangefor
boththreadsbyanoffset
of32toplaceiTemp[4]inthelow
32bits.Next,weunpack
exchangeintoiTemp[2](high32
bits)and
iTemp[l](low32bits)(Line5).Bydoingso,we
canretrievetheelementa threadneedstosupplyfroma fixed
location,
iTemp[I].Finally,weusetheshuffleinstructionto
exchangetheelementsamongthethreads(Line6).
B.RowReuseOptimization
1)Standardconvolution:
## Assumeweuseonethreadto
calculateonecolumn
ofoutputelements.Fortheworking
examplegiveninFigure
## 2,theconvolutionwillbecomputed
asfollows:
## 400
Algorithm1:RetrieveThirdElement
IIiTemp:Bufferforstoringinputelements
loadedfrommemoryorgeneratedthrough
shuffleinstructions.
Input:iTemp
Output:iTemp
1tidt-threadIdx.x;
2movexchange,{iTemp[O],iTemp[4]};
## 3shiftt-((tid+2)&2)<<4;
## 4exchanget-exchange»shift;
5mov{iTemp[l],iTemp[2]},exchange;
6iTemp[2]t-shfCxor(iTemp[l],2);
rowiO
DDO-i
thread0
## Towil
## ~D-DD':
rowjVDDD
## ..-,
## IIII
auto~_~
## Towi2
~o-Ddi
rowflDDD
## ..-,
## IIII
out]~_~
## II-------~
row
i
## 3
## !DDD
rowj2DDD
## ..-,
out2~_~
row
i
## 4
iDDD
InputPilter
## Output
Fig.2.A  3  x  3filterisusedtoslideovertheinputimagealongheight
dimension,whichproducesa columnofoutputelements.
outo=TOWiO.TOWfO+TOWil.TOWfl+TOWi2.TOWf2
outl=TOWil.TOWfO+TOWi2.TOWfl+TOWi3.TOWf2
out2=TOWi2.TOWfO+TOWi3.TOWfl+TOWi4.TOWf2
TheaboveequationssuggestthatTOWilandTOWi3are
loadedtwice,and
TOWi2isloadedthreetimes;ninerows
shouldbeloadedintotal.Theredundantloadstothesame
read-onlyrowthusincurextramemorytransactionsandaddi-
tionaloverhead.
2)Ouroptimization:Toremoveredundantloadstothe
samerow,weredesigntheexecutionflow
oftheconvolution.
Specifically,afterloadinga  rowfromtheinput,wecompute
thenumber
ofoutputelementsthatdependontheloadedrow.
## Ourapproachtranslatestheexecutionflow
oftheworking
examplepresentedinFigure2 to:
Authorized licensed use limited to: ULAKBIM UASL - GAZI UNIV. Downloaded on May 17,2026 at 06:18:30 UTC from IEEE Xplore.  Restrictions apply.

Algorithm2:RowReuse
Input:row,index,filter,Out
Output:Out
1ifindex<FH-1 then
2Iforit-Otoindex+1 do
3IOut[i]t-Out[i]+row.filter[index-i];
## 4end
## 5end
6elseifindex2:FH-1andindex<IH-FH+1 then
7forit-OtoFHdo
8IOindext-index-FH+1+i;
9Out[Oindex]t-Out[Oindex]+row·filter[FH-1-i];
## 10end
## 11end
## 12else
13forit-FH-1 to0  do
14IOindext-IH-FH+1;
15OUt[Oindex]t-OUt[Oindex]+row.filter[FH-i];
## 16end
## 17end
loadrowiO:outo=rowiO.rowfO
loadrOWi1:outo=outo+rOWi1.rOWf1
out1=rowi1.rowfO
loadrowi2:outo=outo+rowi2.rowf2
out1=out1+rowi2.rowf1
out2=rowi2.rowfO
loadrOWi3:out1=out1+rOWi3.rOWf2
out2=out2+rowi3.rowf1
loadrowi4:out2=out2+rowi4.rowf2
## Inthisnewimplementation,wewouldonlyissueloads
tofiverowstocalculatetheoutputelements.
## Wenotethat
althoughthenumber
ofaccessestotheoutputcolumnout
isincreased,theoverheadisnegligiblebecauseoutismuch
smallerthanmultiplerowsandhencecanbestoredinregisters.
Wedescribea  generalsolutionforrowreuseinAlgorithm
## 2,whererowdenotestherowloadedfromtheinput,index
denotestheindexofrow,filterdenotesthevectoroffilter
rowsand
filter[i]meanstheithrowofthefilter.Pseudocode
atLines
1-5processthefirstPH-1 rows(rowioandrOWi1
inFigure2)thatareneededbylessthanPHoutputelements.
Codeat lines6-11processtherowsneededbyexact
PHoutput
elements(e.g.,
rOWi2inFigure2).Finally,codeatLines12-
17processthelastPH-1 rows,whichareneededbyless
than
PHoutputelements(e.g.,rOWi3andrOWi4inFigure2).
## III.EXPERIMENTALSETUP
WeevaluateourapproachonanNVIDIARTX2080Ti
GPU,whichintegrates4350  CUDAcoresforfloatingpoint
computationand4350 CUDAcoresforintegeroperations.
## We
useCUDAToolkitversion10.2.
## Wecompareourapproachagainstthefollowingstate-of-the-
artimageandconvolutionlibraries:
(1)cuDNNversion7.6.4.
cuDNNisa  state-of-the-artconvolutionimplementationthat
## 401
## TABLEI
## LAYERCONFIGURATIONSUSEDFORMULTI-CHANNEL2D
CONVOLUTIONSt.
INIe=FeIHxIwFN   FHXFw
## CONVI128
## 1,3
## 28x281283x3
## CONV2128
## 1,3
## 56x56643x3
## CONV3128
## 1,3
## 12x12645x5
## CONV4128
## 1,3
## 14x14165x5
## CONVS128
## 1,3
## 24x242565x5
## CONV6128
## 1,3
## 24x24645x5
## CONV7128
## 1,3
## 28x28165x5
## CONV8128
## 1,3
## 28x285123x3
## CONV9128
## 1,3
## 56x562563x3
## CONVIO128
## 1,3
## 112x1121283x3
CONVll128
## 1,3
## 224x224643x3
t Weuse
I,F,and0torepresenttheinput,thefilter,andtheoutput
respectively,
N,C,H,andWtodenotethebatchsize,thechannel,
theheight,andthewidth,respectively.
supports2Dandmulti-channel2DconvolutionsonGPU.(2)
ArrayFire[10],version3.6.4.ArrayFireis a popularimageand
signalprocessinglibrary.(3)NVIDIAPerformancePrimitives
(NPP).This
isanimageandsignalprocessinglibrary.(4)
GEMM-im2col.
WeextracttheimplementationoftheGEMM-
im2colfromCaffe[11].
Weapplyourapproachto2Dand
multi-channel
2Dconvolutions.
## IV.EXPERIMENTALRESULTS
A.2DConvolution
1)Setup:Inthisexperiment,wecompareourapproach
againstthe
2DconvolutionimplementationsfromcuDNN,
GEMM-im2col,ArrayFire,and
NPP.AscuDNNprovides
multipleimplementations,weempiricallychoosethefastest
version,denotedascuDNN-fastest,forevaluation.
## Weapply
eachmethodtoimageswithsizesrangingfrom256x  256to
4Kx4K.
2)Overallresults:Figure3reportsthespeedupsof
cuDNN,ArrayFire,NPPandourapproachoverGEMM-
im2col.WhilecuDNNhasbeenheavilyoptimizedfor
NVIDIAGPUs,itdoesnotshowanotableperformance
advantage.Whenusinga  3 x  3filter,ourapproachgivesthe
bestoverallspeedup
of5.4x(upto9.7xforthelargestinput),
whichtranslatestoanimprovement
ofmorethan30%over
thesecond-bestmethod,
NPP.Wenotethatourapproachis
basedonthestandard
2Ddirectconvolutionbyapplyingthe
columnandrowreusealgorithms.Therefore,theperformance
gainismainlyattributedtothereduction
ofthenumberof
memorytransactions.Whenusinga 5 x 5filter,ourapproach
achievesa betteroverallspeedup
of7.7x .
B.Multi-channel2DConvolution
1)Setup:Inthisexperiment,wecompareourapproach
againstthemulti-channel
2Dconvolutionimplementationsin
cuDNNanduseGEMM-im2col
asthebaseline.Sinceour
workfocusesonoptimizingmemorytransactionsofconvo-
lutionsbutnotoperationsoninputchannels,weapplyour
approachtoconvolutionswithoneandthreeinputchannels,
whicharetypicallyusedinthefirstlayer
ofa CNN.Weusethe
Authorized licensed use limited to: ULAKBIM UASL - GAZI UNIV. Downloaded on May 17,2026 at 06:18:30 UTC from IEEE Xplore.  Restrictions apply.

## ...
## '"
## 10-
m..t
c::::JcuDNNfastest
## PO
c::::JcuDNNfastest
_ArrayFire
## 14-
_ArrayFire
## '"
## ~
## 8-
## _NPP
## ..:
## _NPP
## ..;
## _ours
## 12-
## PO
## _ours
lO-
a.
## 6-
## N
a.
## "
## ...
## ,,;
## "
## 1
## ..t
## ...
## 8-
## I
## I
a.
## III
## 4-
## III
## 6-
## J
## 4-
## 2-
po.
## 2-
## 0
## D-O-
## 256x256256x256
(a)3  x  3filter(b)5  x  5filter
## Fig.
3.Speedupsof2DconvolutionsoffourimplementationsoverGEMM-im2colwhenusinga 3  x  3(a)anda 5  x  5filter(b).
## 3.12.6
## IEII
CONV1-EIlIIDlI
## 8.2
## 4.1
## IBD
## 2.31.8
## Ell
## CONV2-IIIIEIII_
## 3.34.2
## 0.012.9
## Ell
CONV3-EllB!II
## 38••
## 21.2
IIlIII
## 0.010.4
## Ell
CONV4-l1lil1li
## 15.5
## 11.7
## I1!D
## 0.02.9
EIlI
## CONV5-21.1
EDEll
## 10.3
IIlIlI
## 0.06.8
## Ell
CONV6-lillEll
## 23.4
## 13.4
## IB.I
## 0.07.4
IEfI.I
CONV7-ElIIIEEI
## 8.48.5
## Ell
## 1.31.0
## ..
CONV8-1IIiI1EIlII
## 4.6
## 2.1
## Ell
## 0.90.6
## III
CONV9-IIIIIIlIIil
## 0.70.9
## 0.20.30.40.3
## 0.7
CONVlO-1IlIiIEIlIIIlDI
## 0.4
## 0.8
## 0.10.20.30.2
## 0.5
CONVll-~~~
## 0.20.30.50.4
## 0.7
## ,,,,,,
\t<'\,\\c.~(ec.ot<'\'Q,et<'t<'
## ~
## '!.\W,Q,OQ,(3
## 6
:r-'Oo'se
## 6
outS
\t<'\,\\c.~(ec.ot<'\'Q,et<'t<'
## ~
'!.\\\:r-~\:r-oQ,(3:0:r-'Oo'se6
outs
## ",\:r-:r-0
Fig.4.SpeedupsofourapproachandcuDNNoverGEMM-im2colforone(left)andthree(right)inputchannels.
layerconfigurationsfromfourpopularCNNmodels,namely,
AlexNet[12],VGG[13],ResNet[14]andGoogleLeNet[15].
Weuse3 x 3and5 x 5filterswitha batchsizeof128.Table
I liststhelayerconfigurationsusedinthisexperiment.
2)Overallresults:Figure4  showsthatourimplementa-
tionachievesanaveragespeedup
of19.5xand25.6xover
GEMM-im2colforoneandthreeinputchannels,respectively.
## Thistranslatestoanimprovement
of1.3x  and1.1x  overthe
fastestalgorithmincuDNN,foroneandthreeinputchannels,
respectively.Sinceourapproachdoesnotoptimizeforinput
channels,it doesnotgiveperformanceimprovementforlayer
configurationsthathavea  largenumber
ofchannels.This
canbeimprovedbycarefuloptimizationsoninputchannels.
## Nonetheless,ourapproachimprovestheperformance
ofcon-
volutionlayerswitha  smallnumber
ofchannels.
## V.RELATEDWORK
## Numerouseffortshavebeendedicatedtooptimizingcon-
volutionoperations.
Aspreviouslymentioned,GEMM-,FFT-
andWinograd-basedconvolutionsarebroadlyadoptedconvo-
lutionalgorithms.Chellapillaet
al.[7]developedanunrolling
convolutionalgorithm.Mathieuetal.
[16]proposedanFFT-
basedconvolutiontocomputeconvolutionsaspointwiseprod-
uctsintheFourierdomain.Lavinetal.
[3]usedWinograd's
minimalfilteringalgorithmtoacceleratetheconvolutionon
## 402
GPu.Thisalgorithmcanreducethearithmeticcomplexity
ofconvolutionbyuptofourtimescomparedwithdirect
convolution.
## Recentstudieshavelookedintominimizingthememory
overheadofthetransformationphases.Choetal.
## [4]reduced
thememoryoverheadofGEMM-basedconvolutionsusinga
compactloweringschemetoreducetheredundancyinthe
loweredmatrixandthenperformedmultiplesmallmatrix
multiplicationsinparallel.Iandolaet
al.[1]reducedmem-
orycommunication
of2DconvolutionsonGPU.Theyalso
prefetchedtheimageregionstotheregisters.
## VI.
## CONCLUSION
## Ourapproachimprovesthedatalocalityforconvolutional
operationsperformedontherowandcolumndirectionsto
reducethememoryaccess.
## Weevaluateourapproachby
applyingitto
2Dandmulti-channel2Dconvolutionsand
evaluateitonanNVIDIARTX2080TiGPUplatform.
## We
compareourapproachagainsta  widerangeofheavilyopti-
mizedconvolutionalgorithms.Experimentalresultsshowthat
ourapproachconsistentlyoutperformsthecompetingmethods
bydeliveringthebestoverallperformancefortheconvolution
tasks.
Authorized licensed use limited to: ULAKBIM UASL - GAZI UNIV. Downloaded on May 17,2026 at 06:18:30 UTC from IEEE Xplore.  Restrictions apply.

## REFERENCES
[1]F.N.Iandola,D.Sheffield,M.J.Anderson,P.M.Phothilimthana,
and
K.Keutzer,"Communication-minimizing2dconvolutioningpu
registers,"inIEEEInternationalConferenceonImageProcessing,2014.
## [2]
N.Vasilache,J.Johnson,M.Mathieu,S.Chintala,S.Piantino,and
Y.LeCun,"Fastconvolutionalnetswithfbfft:AGPUperformanceeval-
uation,"in3rdInternationalConferenceonLearningRepresentations,
ICU?2015,SanDiego,CA,USA,May7-9,2015,ConferenceTrack
## Proceedings,2015.
[3]A.Lavinand
S.Gray,"Fastalgorithmsforconvolutionalneuralnet-
works,"inProceedings
oftheIEEEConferenceonComputerVision
andPatternRecognition,2016,pp.4013-4021.
[4]M.ChoandD.Brand,"Mec:memory-efficientconvolutionfordeep
neuralnetwork,"inProceedings
ofthe34thInternationalConference
onMachineLearning-Volume70.JMLR.org,2017,pp.815-824.
## [5]
1.Zhen,A.Zlateski,F.Durand,andL.Kai,"Optimizingn-dimensional,
winograd-basedconvolutionformanycorecpus,"inAcmSigplanSym-
posiumonPrinciples
&PracticeofParallelProgramming,2018.
[6]A.Vasudevan,A.Anderson,andD.Gregg,"Parallelmultichannel
convolutionusinggeneralmatrixmultiplication,"inIEEEInternational
ConferenceonApplication-specificSystems,2017.
[7]K.Chellapilla,S.Puri,andP.Simard,"Highperformanceconvolutional
neuralnetworksfordocumentprocessing,"TenthInternationalWorkshop
onFrontiers
inHandwritingRecognition,2006.
## [8]
W.Zhang,A.M.Cheng,andJ.Subblok,"Dwarfcode:a  performance
predictiontoolforparallelapplications,"IEEETransactionsonCom-
puters,vol.65,no.2,pp.495-507,2015.
[9]S.Chetlur,C.Woolley,
P.Vandermersch,J. Cohen,1.Iran,B.Catanzaro,
andE.Shelbamer,"cudnn:Efficientprimitivesfordeeplearning,"CaRR,
vol.abs/141O.0759,2014.
## [10]
P.Yalamanchili,U.Arshad,Z.Mohammed,P.Garigipati,P.Entschev,
B.Kloppenborg,1.Malcolm,andJ.Melonakos,"ArrayFire-
## Ahighperformancesoftwarelibraryforparallelcomputingwith
aneasy-to-useAPI,"Atlanta,2015.[Online].Available:https:
// github.com/arrayfire/arrayfire
## [11]
Y.Ea,E.Shelhamer,1.Donahue,S.Karayev,1.Long,R.Girshick,
S.Guadarrama,andI.Darrell,"Caffe:Convolutionalarchitecturefor
fastfeatureembedding,"arXivpreprintarXiv:1408.5093,2014.
[12]A.Krizhevsky,I.Sutskever,and
G.E.Hinton,"Imagenetclassification
withdeepconvolutionalneuralnetworks,"inInternationalConference
onNeuralInformationProcessingSystems,2012.
## [13]
K.SimonyanandA.Zisserman,"Verydeepconvolutionalnetworks
forlarge-scaleimagerecognition,"in3rdInternationalConferenceon
LearningRepresentations,ICU?2015,SanDiego,CA,USA,May7-9,
2015,ConferenceTrackProceedings,2015.
## [14]
K.He,X.Zhang,S.Ren,and1.Sun,"Deepresiduallearningforimage
recognition,"in2016IEEEConferenceonComputerVisionandPattern
Recognition,CVPR2016,Las
Vegas,NY,USA,June27-30,2016,2016,
pp.770-778.
[15]C.Szegedy,
W.Liu,Y.Ea,P.Sermanet,S.E.Reed,D.Anguelov,
D.Erhan,
V.Vanhoucke,andA.Rabinovich,"Goingdeeperwith
convolutions,"inIEEEConferenceonComputerVisionandPattern
Recognition,CVPR2015,Boston,MA,
USA,June7-12,2015,2015,
pp.1-9.
[16]M.Mathieu,M.Henaff,andY.LeCun,"Fasttrainingofconvolutional
networksthroughffts,"arXivpreprintarXiv:1312.5851,2013.
## 403
Authorized licensed use limited to: ULAKBIM UASL - GAZI UNIV. Downloaded on May 17,2026 at 06:18:30 UTC from IEEE Xplore.  Restrictions apply.