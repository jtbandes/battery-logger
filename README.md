# battery-logger

I created this tool to keep tabs on my laptop's battery health throughout its lifetime. Every ten minutes, this script appends some battery-related information to a log file. The logs are small (a year's worth of data is around 1–2 MB gzipped) and can be analyzed however you like — it's just a CSV file.

```
Timestamp,ExternalConnected,IsCharging,Temperature,CycleCount,CurrentCapacity,MaxCapacity,Voltage,Amperage,InstantAmperage,AvgTimeToEmpty,InstantTimeToEmpty,AvgTimeToFull,InstantTimeToFull,DisplayBrightness,KeyboardBacklightBrightness
1613875121.6658301,1,0,2975,28,100,100,12938,0,0,65535,-,65535,-,0.6822185516357422,0.0
1613875721.881535,1,0,2973,28,100,100,12937,0,0,65535,-,65535,-,0.6822185516357422,0.0
1613877714.909935,0,0,2994,28,100,100,12809,-322,-322,767,-,65535,-,0.5384500622749329,0.2665714621543884
1613878315.103056,0,0,3007,28,100,100,12761,-316,-316,656,-,65535,-,0.46875,0.0878523588180542
```

## Building battery-logger

Run `swift build -c release` to build the logger tool; it will be placed at `.build/release/battery-logger`. (Add `--show-bin-path` to print out the full output path.)

## Setting up automatic logging

The logger itself doesn't know about periodic execution; it simply prints data to standard output. You can leverage [launchd](https://www.launchd.info/) to run it as a periodic job with output saved to a file.

(If you'd rather not bother with the setup below, there appear to be some [GUI tools](https://apple.stackexchange.com/q/19740/8318) that you can use to configure launchd instead.)

Create a file in `/Library/LaunchDaemons/net.bandes-storch.battery-logger.plist` as follows. Change the `Program`, `StandardOutPath`, and `StandardErrorPath` to reference the binary built in the previous section, and the locations you'd like the log files to go. The `StartInterval` indicates how often to run the logger.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>net.bandes-storch.battery-logger</string>
  <key>Program</key>
  <string>/Users/Shared/battery-logger/battery-logger</string>
  <key>StandardOutPath</key>
  <string>/Users/Shared/battery-logger/battery.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/Shared/battery-logger/battery-error.log</string>
  <key>LowPriorityIO</key>
  <true/>
  <key>StartInterval</key>
  <integer>600</integer>
</dict>
</plist>
```

Then enable the service using `sudo launchctl load /Library/LaunchDaemons/net.bandes-storch.battery-logger.plist`. That's it! The configuration should persist across system restarts.

To see info about the loaded daemon, run `launchctl print system/net.bandes-storch.battery-logger`.
