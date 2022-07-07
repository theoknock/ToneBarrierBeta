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
#include <stdio.h>
#include <stdlib.h>

NS_ASSUME_NONNULL_BEGIN

static double (^(^signal_time)(AVAudioFramePosition *, AVAudioFrameCount))(void) = ^ (AVAudioFramePosition * time, AVAudioFrameCount frames) {
    return ^ double {
        return (double)((double)(*time) / frames);
    };
};


static double (^(^signal_frequency)(double *))(double) = ^ (double * time) {
    return ^ double (double frequency) {
        return sin(2.0 * (*time * M_PI * frequency));// pow(sinf(M_PI * time * 1000.0), 2.0);
    };
};

static double (^(^signal_amplitude)(double *))(double) = ^ (double * time) {
    return ^ double (double amplitude) {
        return sin(*time * M_PI * amplitude);
    };
};

static double (^(^(^sample_signal)(double *))(double, double))(void) = ^ (double * time) {
    return ^ (double frequency, double amplitude) {
        return ^ double {
            return (signal_frequency(time))(frequency) * (signal_amplitude(time))(amplitude);
        };
    };
};

@interface ClicklessTones : NSObject // <ToneBarrierPlayerDelegate>

+ (nonnull ClicklessTones *)sharedClicklessTones;
- (instancetype)init;
- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock;

@end

NS_ASSUME_NONNULL_END
