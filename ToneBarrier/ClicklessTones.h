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

static double (^scale)(double, double, double, double, double) = ^ double (double min_new, double max_new, double val_old, double min_old, double max_old) {
    double val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));

    return val_new;
};

static double (^random_source_drand48)(double, double) = ^ double (double lower_bound, double higher_bound) {
    double random = drand48();
    double result = (random * (higher_bound - lower_bound)) + lower_bound;

    return result;
};

static double (^random_distributor_gaussian_mean_standard_deviation)(double, double, double, double) = ^ double (double lower_bound, double upper_bound, double mean, double standard_deviation) {
    double result        = sqrt(1 / (2 * M_PI * standard_deviation)) * exp(-(1 / (2 * standard_deviation)) * (random_source_drand48(lower_bound, upper_bound) - mean) * 2);
    printf("\n\nresult == %d\n", result);
    double scaled_result = scale(0.0, 1.0, result, lower_bound, upper_bound);
    printf("scaled_result == %d\n\n", scaled_result);
    return scaled_result;
};

@interface ClicklessTones : NSObject // <ToneBarrierPlayerDelegate>

+ (nonnull ClicklessTones *)sharedClicklessTones;
- (instancetype)init;
- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock;

@end

NS_ASSUME_NONNULL_END
