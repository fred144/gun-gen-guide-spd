# Guide to Sample Generation in CMSSW

We'll discuss the step-by-step process of generating samples for a given CMSSW Release for single particle gun simulations. 

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
34601.0 is the workflow number, which is linked to a detector geometry version (in this case, version 2026V76 which we can change). 

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


## Running Generation Sequence 

This part assumes you have cloned this repository and will make use of the files above. 

```console
user:~$ git clone https://github.com/fred144/sample-gen-guide-spd
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








