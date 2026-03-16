import Foundation
import IOKit

print("Initializing SMC connection from Swift...")
let result = SMCOpen()

func readTemp(key: String) -> Double {
    let cString = strdup(key)
    let temp = SMCGetTemperature(cString)
    free(cString)
    return temp
}

if result == kIOReturnSuccess {
    let cpuTemp = readTemp(key: SMC_KEY_CPU_TEMP)
    let gpuTemp = readTemp(key: SMC_KEY_GPU_TEMP)

    print(String(format: "CPU Temperature: %.1f °C", cpuTemp))
    print(String(format: "GPU Temperature: %.1f °C", gpuTemp))
    
    print("\nReading Fans:")
    readAndPrintFanRPMs()
    
    SMCClose()
} else {
    let resStr = String(format: "%08x", result)
    print("Failed to open SMC connection: " + resStr)
}
