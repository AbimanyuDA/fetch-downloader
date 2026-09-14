import Foundation
import IOKit.pwr_mgt

public final class PowerManagementService: @unchecked Sendable {
    public static let shared = PowerManagementService()

    private let lock = NSLock()
    private var assertionID: IOPMAssertionID = 0
    private var activeTaskCount: Int = 0

    private init() {}

    /// Call when a download or conversion starts
    public func retainSleepPrevention(reason: String = "MediaFetch is actively downloading or processing media") {
        lock.lock()
        defer { lock.unlock() }

        activeTaskCount += 1
        if activeTaskCount == 1 {
            let cfReason = reason as CFString
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                cfReason,
                &assertionID
            )
            if result != kIOReturnSuccess {
                assertionID = 0
            }
        }
    }

    /// Call when a download or conversion completes or fails
    public func releaseSleepPrevention() {
        lock.lock()
        defer { lock.unlock() }

        activeTaskCount = max(0, activeTaskCount - 1)
        if activeTaskCount == 0 && assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
}
