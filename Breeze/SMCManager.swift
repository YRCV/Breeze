import Foundation
import Combine

struct FanData: Identifiable {
    let id: Int
    let name: String
    let actualSpeed: Float
    let minimumSpeed: Float
    let maximumSpeed: Float
    
    var percentage: Float {
        let rpm = max(actualSpeed - minimumSpeed, 0.0)
        let pct = rpm / (maximumSpeed - minimumSpeed)
        return min(max(pct * 100.0, 0.0), 100.0)
    }
}

class SMCManager: ObservableObject {
    static let shared = SMCManager()
    
    @Published var cpuTemperature: Double = 0.0
    @Published var gpuTemperature: Double = 0.0
    @Published var fans: [FanData] = []
    
    private var timer: AnyCancellable?
    private var isOpened = false
    
    private init() {
        let openResult = SMCOpen()
        if openResult == kIOReturnSuccess {
            self.isOpened = true
            print("Successfully opened SMC.")
            self.refresh()
            self.timer = Timer.publish(every: 2.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.refresh()
                }
        } else {
            print(String(format: "Failed to open SMC: %08x", openResult))
        }
    }
    
    deinit {
        timer?.cancel()
        if isOpened {
            SMCClose()
            print("SMC Connection closed.")
        }
    }
    
    func refresh() {
        guard isOpened else { return }
        self.cpuTemperature = readTemp(key: SMC_KEY_CPU_TEMP)
        self.gpuTemperature = readTemp(key: SMC_KEY_GPU_TEMP)
        
        var newFans: [FanData] = []
        var val = SMCVal_t()
        
        let fnumStr = strdup("FNum")
        let result = SMCReadKey(fnumStr, &val)
        free(fnumStr)
        
        if result == kIOReturnSuccess {
            let numFansStr = withUnsafeBytes(of: val.bytes) { rawBuffer in
                let buff = rawBuffer.bindMemory(to: CChar.self)
                return String(cString: buff.baseAddress!)
            }
            
            let numFans: Int
            if let parsed = Int(numFansStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                numFans = parsed
            } else {
                numFans = Int(val.bytes.0)
            }
            
            for i in 0..<numFans {
                let idStr = String(format: "F%dID", i)
                let cIdStr = strdup(idStr)
                var idVal = SMCVal_t()
                var name = "Fan \\(i)"
                if SMCReadKey(cIdStr, &idVal) == kIOReturnSuccess {
                    let nameData = Data(bytes: &idVal.bytes, count: 32).dropFirst(4)
                    let nameStr = String(data: nameData, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
                    if let n = nameStr, !n.isEmpty {
                        name = n
                    }
                }
                free(cIdStr)
                
                // Actual
                let acStr = strdup(String(format: "F%dAc", i))
                let actual = SMCGetFanRPM(acStr)
                free(acStr)
                
                // Min
                let mnStr = strdup(String(format: "F%dMn", i))
                let minimum = SMCGetFanRPM(mnStr)
                free(mnStr)
                
                // Max
                let mxStr = strdup(String(format: "F%dMx", i))
                let maximum = SMCGetFanRPM(mxStr)
                free(mxStr)
                
                if actual >= 0.0 && maximum > 0.0 {
                    let fanData = FanData(id: i, name: name, actualSpeed: actual, minimumSpeed: minimum, maximumSpeed: maximum)
                    newFans.append(fanData)
                }
            }
            self.fans = newFans
        }
    }
    
    private func readTemp(key: String) -> Double {
        let cString = strdup(key)
        let temp = SMCGetTemperature(cString)
        free(cString)
        return temp
    }
}
