// Battery logger
// Jacob Bandes-Storch
// April 22, 2015

import Foundation
import IOKit


func write(_ s: String, to file: UnsafeMutablePointer<FILE>) {
  _ = Array((s + "\n").utf8).withUnsafeBufferPointer { buf in
    fwrite(buf.baseAddress, 1, buf.count, file)
  }
}

func firstServiceMatching(_ name: String) throws -> io_object_t? {
  var iter: io_iterator_t = 0
  if IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(name), &iter) != KERN_SUCCESS {
    return nil
  }

  let obj = IOIteratorNext(iter)
  return obj == 0 ? nil : obj
}

func properties(of object: io_registry_entry_t) throws -> NSDictionary? {
  var dict: Unmanaged<CFMutableDictionary>?
  if IORegistryEntryCreateCFProperties(object, &dict, nil, 0) != KERN_SUCCESS {
    return nil
  }
  return dict?.takeRetainedValue() as NSDictionary?
}

func getBrightness() -> (display: Double?, keyboard: Double?) {
  let task = Process()
  task.launchPath = "/usr/libexec/corebrightnessdiag"
  task.arguments = ["status-info"]
  let pipe = Pipe()
  task.standardOutput = pipe
  task.launch()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  task.waitUntilExit()

  var displayBrightness: Double?
  var keyboardBrightness: Double?

  if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSDictionary {
    if let displays = plist["CBDisplays"] as? [String: [String: Any]] {
      for display in displays.values {
        if let displayInfo = display["Display"] as? [String: Any],
           displayInfo["DisplayServicesIsBuiltInDisplay"] as? Bool == true,
           let brightness = displayInfo["DisplayServicesBrightness"] as? Double {
          displayBrightness = brightness
          break
        }
      }
    }
    if let keyboards = plist["CBKeyboards"] as? [String: [String: Any]] {
      for keyboard in keyboards.values {
        if let backlightInfo = keyboard["CBKeyboardBacklightContainer"] as? [String: Any],
           backlightInfo["KeyboardBacklightBuiltIn"] as? Bool == true,
           let brightness = backlightInfo["KeyboardBacklightBrightness"] as? Double {
          keyboardBrightness = brightness
          break
        }
      }
    }
  }
  return (displayBrightness, keyboardBrightness)
}

func logInfo() throws {
  guard let battery = try firstServiceMatching("AppleSmartBattery") else {
    write("battery logging: no battery found", to: stderr)
    return
  }
  guard let batteryProps = try properties(of: battery) else {
    write("battery logging: error getting battery properties", to: stderr)
    return
  }

  let batteryFields = [
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
  ].map { batteryProps[$0].map(String.init(describing:)) ?? "-" }

  let brightness = getBrightness()
  let brightnessFields = [
    brightness.display.map(String.init(describing:)) ?? "-",
    brightness.keyboard.map(String.init(describing:)) ?? "-",
  ]
  let output = "\(Date().timeIntervalSince1970)," + (batteryFields + brightnessFields).joined(separator: ",")

  write(output, to: stdout)
}

try logInfo()
