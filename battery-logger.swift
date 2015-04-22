// Battery logger
// Jacob Bandes-Storch
// April 22, 2015


import Foundation
import IOKit


func write(_ s: String, to file: UnsafeMutablePointer<FILE>)
{
    _ = Array((s + "\n").utf8).withUnsafeBufferPointer { buf in
        fwrite(buf.baseAddress, 1, buf.count, file)
    }
}


func logInfo()
{
    let desc = IOServiceMatching("AppleSmartBattery")
    
    var iter: io_iterator_t = 0
    if IOServiceGetMatchingServices(kIOMasterPortDefault, desc, &iter) != KERN_SUCCESS {
        write("battery logging: no matching services", to: stderr)
        return
    }
    
    let obj = IOIteratorNext(iter)
    if obj == 0 {
        write("battery logging: no results returned", to: stderr)
        return
    }
    
    var cfProperties: Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(obj, &cfProperties, nil, 0) != KERN_SUCCESS {
        write("battery logging: error getting properties", to: stderr)
        return
    }
    
    if let properties = cfProperties?.takeRetainedValue() as NSDictionary? {
        let columns = [
            "ExternalConnected",
            "IsCharging",
            "Temperature",
            "CycleCount",
            "CurrentCapacity",
            "MaxCapacity",
            "Voltage",
            "Amperage",
            "InstantAmperage",
            "AvgTimeToEmpty",
            "InstantTimeToEmpty",
            "AvgTimeToFull",
            "InstantTimeToFull",
        ]
        
        let fields: [String] = columns.map { key in
            if let val = properties[key] {
                return "\(val)"
            }
            return "-"
        }
        
        let output = "\(NSDate().timeIntervalSince1970)," + fields.joined(separator: ",")
        
        write(output, to: stdout)
    }
    else {
        write("battery logging: nil properties", to: stderr)
    }
}

logInfo()
