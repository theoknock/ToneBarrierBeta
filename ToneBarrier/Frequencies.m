//
//  Frequency.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 1/18/20.
//  Copyright © 2020 The Life of a Demoniac. All rights reserved.
//

#import "Frequencies.h"

@implementation Frequencies

- (instancetype)initWithFrequency1:(double)frequency1 frequency2:(double)frequency2 stereoChannel:(NSUInteger)channel time:(AVAudioTime *)time
{
    self = [super init];
    
    if (self)
    {
        self->_frequency1 = @(frequency1);
        self->_frequency2 = @(frequency2);
        self->_channel    = @(channel);
        self->_time       = time;
    };
    
    return self;
}

@end
