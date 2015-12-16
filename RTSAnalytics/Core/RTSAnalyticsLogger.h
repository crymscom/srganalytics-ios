//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
#import <CocoaLumberjack/CocoaLumberjack.h>
#else
// From CocoaLumberjack's DDLog.h
typedef NS_OPTIONS(NSUInteger, DDLogFlag) {
	DDLogFlagError      = (1 << 0), // 0...00001
	DDLogFlagWarning    = (1 << 1), // 0...00010
	DDLogFlagInfo       = (1 << 2), // 0...00100
	DDLogFlagDebug      = (1 << 3), // 0...01000
	DDLogFlagVerbose    = (1 << 4), // 0...10000
};
#endif

@interface RTSAnalyticsLogger : NSObject
// Compatible with CocoaLumberjack's DDLog interface
+ (void) log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);
@end

extern Class RTSAnalyticsLogClass(void);

#define RTSAnalyticsLog(_flag, _format, ...) [RTSAnalyticsLogClass() log:YES level:NSUIntegerMax flag:(_flag) context:0x52545361 file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ tag:nil format:(_format), ##__VA_ARGS__]

#define RTSAnalyticsLogError(format, ...)   RTSAnalyticsLog(DDLogFlagError,   format, ##__VA_ARGS__)
#define RTSAnalyticsLogWarning(format, ...) RTSAnalyticsLog(DDLogFlagWarning, format, ##__VA_ARGS__)
#define RTSAnalyticsLogInfo(format, ...)    RTSAnalyticsLog(DDLogFlagInfo,    format, ##__VA_ARGS__)
#define RTSAnalyticsLogDebug(format, ...)   RTSAnalyticsLog(DDLogFlagDebug,   format, ##__VA_ARGS__)
#define RTSAnalyticsLogVerbose(format, ...) RTSAnalyticsLog(DDLogFlagVerbose, format, ##__VA_ARGS__)
