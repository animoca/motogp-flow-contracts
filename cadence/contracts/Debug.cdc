pub contract Debug {
    pub event LogEvent(message: String)

    pub fun Log(message: String){
        emit LogEvent(message: message)
    }

}