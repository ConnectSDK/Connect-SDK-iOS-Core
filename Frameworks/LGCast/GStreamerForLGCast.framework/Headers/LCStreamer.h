//
//  LCStreamer.h
//  LGCast
//
//  Created by LGE Device Connectivity on 2021/04/21.
//

#import <Foundation/Foundation.h>

typedef enum {
    Video = 0,
    Audio,
    AV
} LCStreamerMediaType;

extern NSString* const LCStreamerAudioSourceBinName;
extern NSString* const LCStreamerAudioRtpBinName;
extern NSString* const LCStreamerAudioSrtpBinName;

extern NSString* const LCStreamerVideoSourceBinName;
extern NSString* const LCStreamerVideoRtpBinName;
extern NSString* const LCStreamerVideoSrtpBinName;

@protocol LCStreamerDelegate <NSObject>
- (void)gstreamerDidInitialize;
- (void)gstreamerDidSendMessage:(NSString *)message;
@end

@interface LCStreamer: NSObject

@property (nonatomic, weak) id<LCStreamerDelegate> delegate;

- (id)init:(id)delegate;
- (void)setDebugLevel:(int)level;
- (BOOL)setStreamerInfo:(NSDictionary *)info;
- (void)start;
- (BOOL)sendMediaData:(int32_t)mediaType pts:(UInt64)pts data:(NSData *)data;
- (void)stop;

@end
