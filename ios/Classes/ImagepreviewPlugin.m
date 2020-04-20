#import "ImagepreviewPlugin.h"
#if __has_include(<imagepreview/imagepreview-Swift.h>)
#import <imagepreview/imagepreview-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "imagepreview-Swift.h"
#endif

@implementation ImagepreviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImagepreviewPlugin registerWithRegistrar:registrar];
}
@end
