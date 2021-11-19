import MotoGPPack from 0xMotoGPPack

pub fun main(packType: UInt64, serial: UInt64): Bool {
    let packTypeInfo = MotoGPPack.getPackTypeInfo(packType: packType)
    return packTypeInfo.assignedPackNumbers[serial]!
}
