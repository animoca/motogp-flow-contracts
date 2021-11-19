pub fun main(signature: String, nonce: UInt32, skuName: String, recipientAddress: Address): [AnyStruct] {

    let pk = PublicKey(
        publicKey: "31ebdd6c0b8280b9593c616335598437a09424a2b663ed742db499d179c9b170ef4aa83efc3ea0acc2fc9bae8a1a43070e90e7fe12db3b62f3a2b01a02f6c0ae".decodeHex(),
        signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
    )

    let msg = skuName.concat(recipientAddress.toString()).concat(nonce.toString())

    let isValid = pk.verify(
        signature: signature.decodeHex(),
        signedData: msg.utf8,//messageHex.decodeHex(),
        domainSeparationTag: "FLOW-V0.0-user",
        hashAlgorithm: HashAlgorithm.SHA3_256
    )

    return [isValid, msg]
}