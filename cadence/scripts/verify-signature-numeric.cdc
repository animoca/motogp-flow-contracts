pub fun main(message: String, signature: String): Bool {    

    let pk = PublicKey(
        publicKey: "31ebdd6c0b8280b9593c616335598437a09424a2b663ed742db499d179c9b170ef4aa83efc3ea0acc2fc9bae8a1a43070e90e7fe12db3b62f3a2b01a02f6c0ae".decodeHex(),
        signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
    )

    let isValid = pk.verify(
        signature: signature.decodeHex(),
        signedData: message.decodeHex(),
        domainSeparationTag: "FLOW-V0.0-user",
        hashAlgorithm: HashAlgorithm.SHA3_256
    )

    return isValid
}