import Foundation
import IOKit

print("Initializing SMC connection from Swift...")
let result = SMCOpen()

if result == kIOReturnSuccess {
    let cpuTempStr = strdup(SMC_KEY_CPU_TEMP)
    let temp = SMCGetTemperature(cpuTempStr)
    free(cpuTempStr)
    
    let tempStr = String(format: "%.1f", temp)
    print("CPU Temperature: " + tempStr + " °C")
    
    print("\nReading Fans:")
    readAndPrintFanRPMs()
    
    SMCClose()
} else {
    let resStr = String(format: "%08x", result)
    print("Failed to open SMC connection: " + resStr)
}
