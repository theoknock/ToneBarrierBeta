//
//  Frequency.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 1/18/20.
//  Copyright © 2020 The Life of a Demoniac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, StereoChannel) {
    StereoChannelRight,
    StereoChannelLeft
};

@interface Frequencies : NSArray

- (instancetype)initWithFrequency1:(double)frequency1 frequency2:(double)frequency2 stereoChannel:(NSUInteger)channel time:(AVAudioTime *)time;

@property (strong, nonatomic) NSNumber *frequency1;
@property (strong, nonatomic) NSNumber *frequency2;
@property (strong, nonatomic) NSNumber *channel;
@property (strong, nonatomic) AVAudioTime *time;

// TO-DO: add schedule offset and duration property (although only duration is needed for now)


@end

NS_ASSUME_NONNULL_END
