import Foundation

@objc(RNWireguard)
class RNWireguard: NSObject {
    @objc
    func constantsToExport() -> [String: Any]! {
        return ["EV_TYPE_EXCEPTION": "EV_TYPE_EXCEPTION",
            "EV_TYPE_REGULAR": "EV_TYPE_REGULAR",
            "EV_REVOKED": "EV_REVOKED",
            "EV_HOST_DESTROYED": "EV_HOST_DESTROYED",
            "EV_HOST_RESUMED": "EV_HOST_RESUMED",
            "EV_HOST_PAUSED": "EV_HOST_PAUSED"]
    }

    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc(Connect:session:notif:resolve:reject:)
    func Connect(config: String, session: String, notif: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("x", "x", nil)
    }

    @objc(Disconnect:reject:)
    func Disconnect(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("x", "x", nil)
    }

    @objc(Version:reject:)
    func Version(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("x", "x", nil)
    }

    @objc(Status:reject:)
    func Status(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("x", "x", nil)
    }
}
