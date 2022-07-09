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

static double (^linearize)(double, double, double) = ^ double (double range_min, double range_max, double value) {
    double result = (value * (range_max - range_min)) + range_min;
    
    return result;
};

static double (^scale)(double, double, double, double, double) = ^ double (double val_old, double min_new, double max_new, double min_old, double max_old) {
    double val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
    
    return val_new;
};

// 1) randomize block (returns a random double between 0 and 1)
// 2a) distribution block (weights the random according to a given distribution)
// 2b) rescale block (rescales the random to conform to a given range)
// 3) repurpose block (applies a custom calculation to the random)
// 4) join block (connects the results of each successive block)

// Examples:
//      find the split frame position
//      create a frequency
//      create a musical note
//
//      static double (^(^calculate)(void))(void) = ^{
//          return ^ double {
//              return drand48();
//          };
//      };
//



static double (^normalize)(double, double, double) = ^double(double min, double max, double value) {
    double result = (value - min) / (max - min);
    
    return result;
};

static AVAudioFramePosition (^minimum)(AVAudioFramePosition, AVAudioFramePosition) = ^ AVAudioFramePosition (AVAudioFramePosition x, AVAudioFramePosition y) {
    return y ^ ((x ^ y) & -(x < y));
};
//
//static const void * (^(^signal_time)(AVAudioFramePosition *, double))(void) = ^ (AVAudioFramePosition * position, double frames) {
//    static AVAudioFramePosition split;
//    split = frames * drand48();
//    printf("split == %lld\nframes == %f\npercentage == %f\n\n", split, frames, (split/frames) * 100.0);
//    static double index, count, time;
//    count = split;
//    return Block_copy(const void *)(^ double {
//        // position to split
//        // split to frames
//        (count = (count = (((index = minimum(*position, split)) == frames) ?: split)));
//        printf("\t\t\ttime == %f\n\n", index);
//        return (double)time;
//    });
//};

static double (^note)(void) = ^{
    return ^ (long random) {
        double random_note = pow(1.059463094f, random) * 440.0;
        return random_note;
    }(^ long (long random, int n, int m) {
        long result = random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n);
        return result;
    } (random(), -8, 24));
};

static double (^(^(^signal_frequency)(double))(double *))(void) = ^ (double frequency) {
    static double sample_frequency;
    static double * sample_frequency_t;
    sample_frequency_t = &sample_frequency;
    sample_frequency = (2.0 * M_PI * frequency);
    return ^ (double * time) {
        return ^ double {
            return sin(*sample_frequency_t * (*time));
        };
    };
};

static double (^(^(^signal_amplitude)(double))(double *))(void) = ^ (double amplitude) {
    double sample_amplitude = (M_PI * amplitude);
    return ^ (double * time) {
        return ^ double {
            return sin(sample_amplitude * (*time));
        };
    };
};

static double (^(^(^sample_signal)(double(^)(void)))(double(^(^)(double *))(void), double(^(^)(double *))(void)))(void) = ^ (double(^normalized_time)(void)) {
    static double sample_time;
    static double * sample_time_t;
    sample_time_t = &sample_time;
    static double(^sample_frequency)(void);
    static double(^sample_amplitude)(void);
    return ^ (double(^(^frequency_time)(double *))(void), double(^(^amplitude_time)(double *))(void)) {
        sample_frequency = frequency_time(sample_time_t);
        sample_amplitude = amplitude_time(sample_time_t);
        return ^ double {
            *sample_time_t = normalized_time();
            return sample_frequency() * sample_amplitude();
        };
    };
};

@interface ClicklessTones : NSObject

+ (nonnull ClicklessTones *)sharedClicklessTones;
- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock;

@end

NS_ASSUME_NONNULL_END
