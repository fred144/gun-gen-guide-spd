#!/bin/bash  

# first step
# this is your generator / gun configuration 
# https://github.com/cms-sw/cmssw/tree/master/Configuration/Generator/python lists some available pre-configured guns 
# a commonly used one (at least in this group) is SingleElectronE1000_cfi.py


# first step
echo "first step beginning"
cmsDriver.py  SingleElectronE1000_cfi.py  -s GEN,SIM -n 10 --conditions auto:phase2_realistic_T21 --beamspot HLLHC --datatier GEN-SIM --eventcontent FEVTDEBUG --geometry Extended2026D86 --era Phase2C11I13M9 --relval 9000,100 --fileout file:step1.root  > step1.log  2>&1
# second step
echo "second step beginning"
cmsDriver.py step2 -s DIGI:pdigi_valid,L1TrackTrigger,L1,DIGI2RAW,HLT:@fake2 --conditions auto:phase2_realistic_T21 --datatier GEN-SIM-DIGI-RAW -n 10 --eventcontent FEVTDEBUGHLT --geometry Extended2026D86 --era Phase2C11I13M9 --filein  file:step1.root --fileout file:step2.root  > step2.log  2>&1 
# third step
echo "third step begninnig"
cmsDriver.py step3 -s RAW2DIGI,L1Reco,RECO,RECOSIM,PAT,VALIDATION:@phase2Validation+@miniAODValidation,DQM:@phase2+@miniAODDQM --conditions auto:phase2_realistic_T21 --datatier GEN-SIM-RECO,MINIAODSIM,DQMIO -n 10 --eventcontent FEVTDEBUGHLT,MINIAODSIM,DQM --geometry Extended2026D86 --era Phase2C11I13M9 --filein  file:step2.root --fileout file:step3.root  > step3.log  2>&1
