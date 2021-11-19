import MotoGPPack from 0xMotoGPPack

pub fun main(packType: UInt64): MotoGPPack.PackType {
    return MotoGPPack.getPackTypeInfo(packType: packType)
}