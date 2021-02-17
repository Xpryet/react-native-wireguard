#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface RCT_EXTERN_MODULE(RNWireguard, NSObject)

RCT_EXTERN_METHOD(Connect: (NSString *)config session: (NSString *)session notif: (NSString *)notif resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(Disconnect: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(Version: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(Status: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject)

@end
