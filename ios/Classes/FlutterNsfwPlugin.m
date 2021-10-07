#import "FlutterNsfwPlugin.h"
#if __has_include(<flutter_nsfw/flutter_nsfw-Swift.h>)
#import <flutter_nsfw/flutter_nsfw-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_nsfw-Swift.h"
#endif

@implementation FlutterNsfwPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterNsfwPlugin registerWithRegistrar:registrar];
}
@end
