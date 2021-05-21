# SimplyNFC

Simply read and write NFC tags with iPhone (iOS 14.0+)

[![GitHub license](https://img.shields.io/github/license/yanngodeau/SimplyNFC)](https://github.com/yanngodeau/SimplyNFC/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/plateform-iOS-yellow)](https://github.com/yanngodeau/SimplyNFC)
[![Swift](https://img.shields.io/badge/swift-5.1%2B-orange)](https://swift.org)


## Installation

### Swift package manager

Go to `File | Swift Packages | Add Package Dependency...` in Xcode and search for « SimplyNFC »

### Cathage

You can use [Carthage](https://github.com/Carthage/Carthage) to install `SimplyNFC` by adding it to your `Cartfile`.

```swift
github "yanngodeau/SimplyNFC"
```

### Manual

1. Put SimplyNFC repo somewhere in your project directory.
2. In Xcode, add `SimplyNFC.xcodeproj` to your project
3. On your app's target, add the SwiftMessages framework:
   1. as an embedded binary on the General tab.
   2. as a target dependency on the Build Phases tab.

## Usage

### Read tag

Reading NCFNDEFMessage from tag

```swift
import SimplyNFC

let nfcManager = NFCManager()
nfcManager.read { manager in
    // Session did become active
    nfcManager.setMessage("👀 Place iPhone near the tag to read")
} didDetect: { manager, result in
    switch result {
    case .failure:
        nfcManager.setMessage("👎 Failed to read tag")
    case .success:
        nfcManager.setMessage("🙌 Tag read successfully")
}
```

### Write on tag

Writing NFCNDEFMessage on tag

```swift
import SimplyNFC

let nfcManager = NFCManager()
nfcManager.write(message: ndefMessage) { manager in
    // Session did become active
    nfcManager.setMessage("👀 Place iPhone near the tag to be written on")
} didDetect: { manager, result in
    switch result {
    case .failure:
        nfcManager.setMessage("👎 Failed to write tag")
    case .success:
        nfcManager.setMessage("🙌 Tag successfully written")
}
```

## Contribute

- Fork it!
- Create your feature branch: `git checkout -b my-new-feature`
- Commit your changes: `git commit -am 'Add some feature'`
- Push to the branch: `git push origin my-new-feature`
- Submit a pull request

## License

SimplyNFC is distributed under the [MIT License](https://mit-license.org).

## Author

- Yann Godeau - [@yanngodeau](https://github.com/yanngodeau)

Based on code by [@tattn](https://github.com/tattn)

