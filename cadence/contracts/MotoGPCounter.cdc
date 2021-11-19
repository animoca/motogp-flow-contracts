import ContractVersion from 0xContractVersion

pub contract MotoGPCounter: ContractVersion {

    pub fun getVersion(): String {
        return "0.7.8"
    }

    access(self) let counterMap:{String:UInt64}

    access(account) fun increment(_ key:String): UInt64 {
        if self.counterMap.containsKey(key) {
            self.counterMap[key] = self.counterMap[key]! + UInt64(1)
        } else {
            self.counterMap[key] = UInt64(1)
        }
        return self.counterMap[key]!
    }

    access(account) fun incrementBy(_ key:String, _ value:UInt64){
        if self.counterMap.containsKey(key) {
            self.counterMap[key] = self.counterMap[key]! + value
        } else {
            self.counterMap[key] = value
        }
    }

    pub fun hasCounter(_ key:String): Bool {
        return self.counterMap.containsKey(key)
    }

    pub fun getCounter(_ key:String): UInt64 {
        return self.counterMap[key]!
    }

    init(){
        self.counterMap = {}
    }

}