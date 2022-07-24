//
//  AudioRoutePicker.h
//  ToneBarrier
//
//  Created by Xcode Developer on 6/25/22.
//

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioRoutePicker : AVRoutePickerView

- (void)togglePlayWithAudioEngineRunningStatusCallback:(BOOL (^(^)(typeof(^{}) _Nullable))(BOOL, BOOL))audioEngineRunningStatus;
- (void)togglePlayFileWithAudioPlayerNodePlayingStatusCallback:(BOOL (^(^)(void))(BOOL, BOOL))audioPlayerNodePlayingStatus;

@end

NS_ASSUME_NONNULL_END
