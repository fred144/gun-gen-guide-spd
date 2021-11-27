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
