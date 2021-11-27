# Guide to Sample Generation in CMSSW

We'll discuss the step-by-step process of generating ntuple samples for a given CMSSW Release for single particle gun simulations. 

## Building a Release
Connect to T3 Cluster
```console
user:~$ fire[year]_[user]@hepcms-in2.umd.edu 
> password: [enter pasword] 
```

See available releases. 
```console
user@console:~$ scram list -a 
```

Command above can take a while to parse through certain releases.\
To filter available [releases](https://twiki.cern.ch/twiki/bin/view/CMSPublic/WorkBookWhichRelease); e.g., all CMSSW_12_x_x_x.
```console
user:~$ scram list -a | grep CMSSW_12     
```
For this tutorial, we'll check out and generate samples on CMSSW_12_2_0_pre1. Check [this](https://github.com/cms-sw/cmssw/releases) for stable builds. 
```console
user:~$ cmsrel CMSSW_12_2_0_pre1
```

This should build CMSSW_12_2_0_pre1 in your current directory. We can go into it and initialize environment. 
```console
user:~$ cd CMSSW_12_2_0_pre1
user:~$ cmsenv
```
## Getting Generation Files
Your release environment should look like this 
```console
user:~$ ls
> biglib  bin  cfipython  config  doc  include  lib  logs  objs  python  src  static  test  tmp
```
Let's checkout a workflow for sample generation. 
```console
user@console:~$ cd src
user@console:~$ runTheMatrix.py -w upgrade -l 34601.0 --dryRun
```
34601.0 is the workflow number, which is linked to a detector geometry version (in this case, version 2026V76 which we can change if needed). 

```console
user:~$ ls
> 34601.0_SingleElectronPt10+2026D76+SingleElectronPt10_pythia8_GenSimHLBeamSpot+DigiTrigger+RecoGlobal+HARVESTGlobal  
> runall-report-step123-.log
user:~$ cd 34601.0_SingleElectronPt10+2026D76+SingleElectronPt10_pythia8_GenSimHLBeamSpot....
```

## Editing Generation Files
```console
user:~$ ls
> cmdLog
```
The ```cmdLog```  contains all the commands for the sample generation workflow. Currently, 34601.0 is the workflow number for Electron Particle Gun Simulations at 1 TeV. 

**But you can use this workflow as an outline to make various other sample generations with different geometeries and particle gun types/ configurations**
```console
user:~$ [text editor] -nw cmdLog 
```
The file should have similar contents to the file with the same name above. These are just all the terminal commands one would use, but all written in a text file.

The two main parts of a sample generation run is this cmdLog executable and a configuration file for the particle gun. 
Link below lists some available pre-configured guns, just copy them and edit them appropriately.  

> https://github.com/cms-sw/cmssw/tree/master/Configuration/Generator/python 

I have included an editted version of ```SingleElectronE1000_cfi.py```. Note, the name suggests that it's a 1 TeV (1000 GeV) Electron gun, but you can edit the parameters of the gun and change even the particle. It contents are below (note we have change the electron to a photon). 

***The name should be left as is, since we are going through the sample generation from scratch-- the default names are needed to be correctly referenced by CMSSW***

```python
import FWCore.ParameterSet.Config as cms

pid = 22 # particle id of the particle;e.g., 22 for photon, 11 for electron, etc.
energy = 1000 # the energy of the particles from the particle gun in GeV
event_num = 10 # number of back to back events, helps set the name, rest is set in the cmdLog_v2
# set the vertical bounds of the particle gun, default cms range is from [2.5, -2.5]
# HGCAL bounds is [3.0, 1.5]
eta_bottom = 3.0
eta_top = 1.5

generator = cms.EDProducer("FlatRandomEGunProducer",
    PGunParameters = cms.PSet(
        PartID = cms.vint32(pid),
        MaxEta = cms.double(eta_bottom),
        MaxPhi = cms.double(3.14159265359),
        MinEta = cms.double(eta_top),
        MinE = cms.double(energy - 0.01),
        MinPhi = cms.double(-3.14159265359), ## in radians
        MaxE = cms.double(energy + 0.01)
    ),
    Verbosity = cms.untracked.int32(0), ## set to 1 (or greater)  for printouts
    psethack = cms.string('single_pid_{}_E_{}_nevts_{}'.format(int(pid), int(energy), int(event_num))),
    AddAntiParticle = cms.bool(True),
    firstRun = cms.untracked.uint32(1)
)
```


Brief note about the contents of the executable, nicely formatted it looks like this. 
```bash
#!/bin/bash  
# first step
# this is your generator / gun configuration 
# https://github.com/cms-sw/cmssw/tree/master/Configuration/Generator/python lists some available pre-configured guns 
# a commonly used one (at least in this group) is SingleElectronE1000_cfi.py
# commonly edited parameters are marked with ###
cmsDriver.py single_particle_gun_cfi.py \ 
-s GEN,SIM \
-n 10 \ ### match the number of events entered in  SingleElectronE1000_cfi.py
--conditions auto:phase2_realistic_T21 \
--beamspot HLLHC \ 
--datatier GEN-SIM \
--eventcontent FEVTDEBUG \
--geometry Extended2026D86 \ ###
--era Phase2C11I13M9 \ 
--relval 9000,100 \
--fileout file:step1.root  > step1.log  2>&1
# second step
cmsDriver.py step2  \
-s DIGI:pdigi_valid,L1TrackTrigger,L1,DIGI2RAW,HLT:@fake2 \
--conditions auto:phase2_realistic_T21 \
--datatier GEN-SIM-DIGI-RAW \
-n 10 \ ###
--eventcontent FEVTDEBUGHLT \
--geometry Extended2026D86 \ ###
--era Phase2C11I13M9 \
--filein  file:step1.root \ 
--fileout file:step2.root  > step2.log  2>&1 
# third step
cmsDriver.py step3  \
-s RAW2DIGI,L1Reco,RECO,RECOSIM,PAT,VALIDATION:@phase2Validation+@miniAODValidation,DQM:@phase2+@miniAODDQM \
--conditions auto:phase2_realistic_T21 \ 
--datatier GEN-SIM-RECO,MINIAODSIM,DQMIO \
-n 10 \ ###
--eventcontent FEVTDEBUGHLT,MINIAODSIM,DQM \
--geometry Extended2026D86 \  ###
--era Phase2C11I13M9 \
--filein  file:step2.root  \
--fileout file:step3.root  > step3.log  2>&1
```
**Note, this won't work copy pasted since the line continuation characters are being funky**.
A machine readable formatted one ```cmdLog_v2.sh``` is above. This is basically the same cmdLog_v2.sh but with some output names shortened. 

## Running Generation Sequence 

This part assumes you have cloned this repository and will make use of the files above.\
You can do this anywhere on the cluster as long as you have issued ```cmsenv``` in any of the releases.

```console
user:~$ git clone https://github.com/fred144/gun-gen-guide-spd
user:~$ cd sample-gen-guide-spd
user:~$ ls 
> SingleElectronE1000_cfi.py  cmdLog_v2.sh  logs  sample_gen.jdl  
```

```sample_gen.jdl``` is a sample job submission file for the cluster with uses [condor](https://htcondor.readthedocs.io/en/latest/) to handle job distribution. 

```bash
universe = vanilla
executable = ./cmdLog_v2.sh
getenv = True
should_transfer_files = NO
Requirements = TARGET.FileSystemDomain == "privnet"
Output =./logs/output_$(cluster)_$(process).stdout
Error  =./logs/output_$(cluster)_$(process).stderr
Log    =./logs/output_$(cluster)_$(process).log
notify_user = fgarcia4@umd.edu # put you email here if you want to be notified
notification = always
# can request more cores, memory, etc. if allowed T3 is defaulted to 1 core
#request_cpus = 2
#request_memory = 4096
#request_disk = 16383
Arguments = 100
Queue
```
To submit the job. 
```console
user:~$ condor_submit sample_gen.jdl 
```
To check you jobs.
```console
user:~$ condor_q
```
or go to this page (your job may be intially put on idle). 
> http://hepcms-hn.umd.edu/condor_status.txt
To cancel you job any time
```console
user:~$ condor_rm [job_id found using condor_q]
```
Can check the job logs. 
```console
user:~$ cd logs
```

If the job ran succesfully, you should have the following in your directory.
```console
user:~$ ls
>
logs                                    sample_gen.jdl 
SingleElectronE1000_cfi.py              step2.root
SingleElectronE1000_cfi_py_GEN_SIM.py   step2_DIGI_L1TrackTrigger_L1_DIGI2RAW_HLT.py 
step3.log                               cmdLog_v2.sh                            
step3.root                              step3_RAW2DIGI_L1Reco_RECO_RECOSIM_PAT_VALIDATION_DQM.py
step1.log                               step3_inDQM.root
step1.root                              step3_inMINIAODSIM.root
step2.log
```
```step3.root``` is the main sample file that we will turn into an ntuple. 

## Ntuplizing
Navigate to the CMSSW release's src folder and clone the ntuple generator tool then install 
> https://github.com/chrispap95/reco-ntuples
```console
user:~$ cd CMSSW_x_x_x_pre1/src
user:~$ cmsenv
user:~$ git clone https://github.com/chrispap95/reco-ntuples
user:~$ cd .. 
user:~$ scram b -j4 #install 
```

The ```reco-ntuples``` tools should now be installed.

>Note, if installation fails, try installing the tool in an earlier release of CMSSW (do the cmsrel etc.) and use that tool instead. 

Go to
```console
user:~$ cd /reco-ntuples/HGCalAnalysis/test
```

```exampleConfig.py``` is a template to reconstuct your ```step3.root``` into an ntuple. 

You can edit the following lines 
```python
...
# change the geometry version to the version you generated the step3.root from.
process.load('Configuration.Geometry.GeometryExtended2026D76Reco_cff') 
...
# change the sample size to the number contained in you step3.root.
process.maxEvents = cms.untracked.PSet( input = cms.untracked.int32([#sample size#]) )  
...
process.source = cms.Source("PoolSource",
    # replace 'step3.root' with the source file you want to use
    fileNames = cms.untracked.vstring(
        'file:/full/path/to/your/step3.root'
    ),
    duplicateCheckMode = cms.untracked.string("noDuplicateCheck")
)
...
process.TFileService = cms.Service(
                       "TFileService", 
                       fileName = cms.string("path/to/your/ntuple/folder/pid_[#]_e_[#energy#]_nevts_[#sample size#].root")
                        )

...
```

To run the ntuplization process, issue
```console
user:~$ nohup cmsRun exampleConfig.py > & log.txt & 
```
```nohup``` allows the script to run on the background and spits out the outputs/ errors to ```log.txt```

If the ntuplization is succesful, you can very if the ntuple is filled by doing  
```console
user:~$ edmDumpEventContent #ntuplename#.root 
```

# Final Notes

CMSSW is a very dynamic software and is prone to breakage.
> If something doesn't work, try this process for older releases, e.g., ```CMSSW_11_3_0_pre5```. 

There are also other tools that can do particle gun simulations. Like
> https://github.com/chrispap95/particleGun

If there are any questions, comments, and concerns feel free to reach out to me at ```fgarcia4@umd.edu```
*Fred Angelo Garcia, Simulating Particle Detection Group, Fall 2021*
