//
//  ToneGenerator.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

//
//  ToneGenerator.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^PlayToneCompletionBlock)(void);
typedef void (^CreateAudioBufferCompletionBlock)(AVAudioPCMBuffer * _Nonnull buffer1, AVAudioPCMBuffer * _Nonnull buffer2, PlayToneCompletionBlock _Nonnull playToneCompletionBlock);

@interface ToneGenerator : NSObject

+ (nonnull ToneGenerator *)sharedGenerator;

- (void)togglePlayWithAudioEngineRunningStatusCallback:(void (^(^)(void))(BOOL))audioEngineRunningStatus;

@end
