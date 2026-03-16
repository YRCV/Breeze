import Foundation
import IOKit

let kSMCUserClientOpen: UInt8 = 0
let kSMCUserClientClose: UInt8 = 1
let kSMCHandleYPCEvent: UInt32 = 2
let kSMCReadKey: UInt8 = 5

struct SMCParamStruct {
    var key: UInt32 = 0
    var vers: UInt8 = 0
    var pLvl: UInt8 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data16: UInt32 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

func stringToUInt32(_ str: String) -> UInt32 {
    guard let data = str.data(using: .utf8) else { return 0 }
    var val: UInt32 = 0
    (data as NSData).getBytes(&val, length: 4)
    return UInt32(bigEndian: val)
}

var conn: io_connect_t = 0

func openSMC() -> Bool {
    let matchingDict = IOServiceMatching("AppleSMC")
    var iterator: io_iterator_t = 0
    
    // Use 0 or kIOMainPortDefault, kIOMasterPortDefault is 0
    let result = IOServiceGetMatchingServices(0, matchingDict, &iterator)
    if result != kIOReturnSuccess { return false }
    
    let device = IOIteratorNext(iterator)
    IOObjectRelease(iterator)
    if device == 0 { return false }
    
    let openResult = IOServiceOpen(device, mach_task_self_, 0, &conn)
    IOObjectRelease(device)
    
    return openResult == kIOReturnSuccess
}

func closeSMC() {
    IOServiceClose(conn)
}

func callSMC(input: inout SMCParamStruct, output: inout SMCParamStruct) -> kern_return_t {
    let inputSize = MemoryLayout<SMCParamStruct>.size
    var outputSize = inputSize
    
    return IOConnectCallStructMethod(conn, kSMCHandleYPCEvent,
                                     &input, inputSize,
                                     &output, &outputSize)
}

func readKey(_ key: String) -> SMCParamStruct? {
    var input = SMCParamStruct()
    input.key = stringToUInt32(key)
    input.data8 = kSMCReadKey
    
    var output = SMCParamStruct()
    if callSMC(input: &input, output: &output) == kIOReturnSuccess {
        return output
    }
    return nil
}

if openSMC() {
    print("SMC Connection Opened Successfully")
    // FNum gives the number of fans
    if let out = readKey("FNum") {
        let numFans = out.bytes.0
        print("Number of fans: \\(numFans)")
        
        for i in 0..<numFans {
            if let fanOut = readKey("F\\(i)Ac") {
                let val = Int(fanOut.bytes.0) << 8 | Int(fanOut.bytes.1)
                let speed = Float(val) / 4.0
                print("Fan \\(i) Speed: \\(speed) RPM")
            }
        }
    } else {
        print("Could not read FNum")
    }
    
    // Read CPU temperature
    if let cpuOut = readKey("TC0F") {
        let temp = Float(cpuOut.bytes.0) + Float(cpuOut.bytes.1) / 256.0
        print("CPU Temp (TC0F): \\(temp) °C")
    } else if let cpuOut2 = readKey("TC0P") {
        let temp = Float(cpuOut2.bytes.0) + Float(cpuOut2.bytes.1) / 256.0
        print("CPU Temp (TC0P): \\(temp) °C")
    } else {
        print("Could not read CPU temperature sensors.")
    }
    
    closeSMC()
} else {
    print("Failed to open SMC.")
}
