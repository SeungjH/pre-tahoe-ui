import AppKit
import Darwin

// A SkyLight application space stays in place while the user switches desktops.
// Keep the private API isolated here so the HUD can fall back to its normal window.
@MainActor
final class StationarySpace {
    static let shared = StationarySpace()

    private let connection: Int32
    private let space: Int32
    private let addWindows: @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

    private init?() {
        guard let library = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW),
              let connectionSymbol = dlsym(library, "SLSMainConnectionID"),
              let createSymbol = dlsym(library, "SLSSpaceCreate"),
              let levelSymbol = dlsym(library, "SLSSpaceSetAbsoluteLevel"),
              let showSymbol = dlsym(library, "SLSShowSpaces"),
              let addSymbol = dlsym(library, "SLSSpaceAddWindowsAndRemoveFromSpaces")
        else { return nil }

        let getConnection = unsafeBitCast(connectionSymbol, to: (@convention(c) () -> Int32).self)
        let createSpace = unsafeBitCast(createSymbol, to: (@convention(c) (Int32, Int32, Int32) -> Int32).self)
        let setLevel = unsafeBitCast(levelSymbol, to: (@convention(c) (Int32, Int32, Int32) -> Int32).self)
        let showSpaces = unsafeBitCast(showSymbol, to: (@convention(c) (Int32, CFArray) -> Int32).self)
        let addWindows = unsafeBitCast(addSymbol, to: (@convention(c) (Int32, Int32, CFArray, Int32) -> Int32).self)

        let connection = getConnection()
        let space = createSpace(connection, 1, 0)
        guard space > 0 else { return nil }
        let levelResult = setLevel(connection, space, 0)
        let showResult = showSpaces(connection, [NSNumber(value: space)] as CFArray)
        // On the tested macOS version, showing this space returns 3 even though it works.
        guard levelResult == 0 || levelResult == 3,
              showResult == 0 || showResult == 3
        else { return nil }

        self.connection = connection
        self.space = space
        self.addWindows = addWindows
    }

    func add(_ window: NSWindow) -> Bool {
        let ids = [NSNumber(value: window.windowNumber)] as CFArray
        // Adding the window also returns 3 on the tested system when successful.
        let result = addWindows(connection, space, ids, 0x7)
        return result == 0 || result == 3
    }
}
