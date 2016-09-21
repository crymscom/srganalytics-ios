//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

#if __has_include(< CocoaLumberjack / CocoaLumberjack.h >)
#import <CocoaLumberjack/CocoaLumberjack.h>
#else
// From CocoaLumberjack's DDLog.h
typedef NS_OPTIONS (NSUInteger, DDLogFlag) {
    DDLogFlagError      = (1 << 0),
    DDLogFlagWarning    = (1 << 1),
    DDLogFlagInfo       = (1 << 2),
    DDLogFlagDebug      = (1 << 3),
    DDLogFlagVerbose    = (1 << 4),
};
#endif

@interface SRGAnalyticsLogger : NSObject
// Compatible with CocoaLumberjack's DDLog interface
+ (void)log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(9, 10);
@end

extern Class SRGAnalyticsLogClass(void);

#define SRGAnalyticsLog(_flag, _format, ...) [SRGAnalyticsLogClass() log: YES level: NSUIntegerMax flag: (_flag)context : 0x52545361 file: __FILE__ function: __PRETTY_FUNCTION__ line: __LINE__ tag: nil format: (_format), ## __VA_ARGS__]

#define SRGAnalyticsLogError(format, ...)   SRGAnalyticsLog(DDLogFlagError,   format, ## __VA_ARGS__)
#define SRGAnalyticsLogWarning(format, ...) SRGAnalyticsLog(DDLogFlagWarning, format, ## __VA_ARGS__)
#define SRGAnalyticsLogInfo(format, ...)    SRGAnalyticsLog(DDLogFlagInfo,    format, ## __VA_ARGS__)
#define SRGAnalyticsLogDebug(format, ...)   SRGAnalyticsLog(DDLogFlagDebug,   format, ## __VA_ARGS__)
#define SRGAnalyticsLogVerbose(format, ...) SRGAnalyticsLog(DDLogFlagVerbose, format, ## __VA_ARGS__)
