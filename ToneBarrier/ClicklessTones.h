//
//  ClicklessTones.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "ToneGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ClicklessTones : NSObject // <ToneBarrierPlayerDelegate>

+ (nonnull ClicklessTones *)sharedClicklessTones;
- (instancetype)init;
- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock;

@end

NS_ASSUME_NONNULL_END
