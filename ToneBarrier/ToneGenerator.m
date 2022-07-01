//
//  ToneGenerator.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <GameKit/GameKit.h>

#import "ToneGenerator.h"
//#import "ToneBarrierPlayer.h"
#import "ClicklessTones.h"
//#import "FrequenciesPairs.h"
#import "Frequencies.h"

#include "easing.h"

//static const float high_frequency = 6000.0;
//static const float low_frequency  = 1000.0;

@interface ToneGenerator ()
{
    bool                    _multichannelOutputEnabled;
    
    // mananging session and configuration changes
    BOOL                    _isSessionInterrupted;
    BOOL                    _isConfigChangePending;
}

@property (nonatomic, readonly) AVAudioEngine * audioEngine;
@property (nonatomic, readonly) AVAudioMixerNode * mixerNode;
@property (nonatomic, readonly) AVAudioPCMBuffer * pcmBufferOne;
@property (nonatomic, readonly) AVAudioPCMBuffer * pcmBufferTwo;
@property (nonatomic, readonly) AVAudioEnvironmentNode * environmentNode;
@property (nonatomic, readonly) AVAudioMixerNode *submixer;
@property (nonatomic, readonly) AVAudioUnitReverb *reverb;



@end

@implementation ToneGenerator

static ToneGenerator *sharedGenerator = NULL;
+ (nonnull ToneGenerator *)sharedGenerator
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
        if (!sharedGenerator)
        {
            sharedGenerator = [[self alloc] init];
        }
    });
    
    return sharedGenerator;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _audioEngine = [[AVAudioEngine alloc] init];
        _mixerNode = _audioEngine.mainMixerNode;
        [_mixerNode setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmSoundField];
        [_mixerNode setSourceMode:AVAudio3DMixingSourceModeSpatializeIfMono];
        
//        _environmentNode = [[AVAudioEnvironmentNode alloc] init];
//        [_environmentNode setOutputType:AVAudioEnvironmentOutputTypeHeadphones];
//        [_environmentNode setOutputVolume:1.0];
//        _environmentNode.reverbParameters.enable = YES;
//        _environmentNode.reverbParameters.level = -20.0;
//        [_environmentNode.reverbParameters loadFactoryReverbPreset:AVAudioUnitReverbPresetLargeHall];
//
//        [_audioEngine attachNode:_environmentNode];
        
        _submixer = [[AVAudioMixerNode alloc] init];
        [_submixer setReverbBlend:1.0];
        [_submixer setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmSoundField];
        [_submixer setSourceMode:AVAudio3DMixingSourceModePointSource];
        
        _reverb = [[AVAudioUnitReverb alloc] init];
        [_reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall];
        [_reverb setWetDryMix:50];
        
        _playerOneNode = [[AVAudioPlayerNode alloc] init];
        [_playerOneNode setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmSoundField];
        [_playerOneNode setSourceMode:AVAudio3DMixingSourceModeSpatializeIfMono];
        
        _playerTwoNode = [[AVAudioPlayerNode alloc] init];
        [_playerTwoNode setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmSoundField];
        [_playerTwoNode setSourceMode:AVAudio3DMixingSourceModeSpatializeIfMono];
        
        [_audioEngine attachNode:_submixer];
        [_audioEngine attachNode:_reverb];
        [_audioEngine attachNode:_playerOneNode];
        [_audioEngine attachNode:_playerTwoNode];
         
        [_audioEngine connect:_playerOneNode to:_submixer format:[_playerOneNode outputFormatForBus:0]];
        [_audioEngine connect:_playerTwoNode to:_submixer format:[_playerTwoNode outputFormatForBus:0]];

        [_audioEngine connect:_submixer to:_reverb format:[_submixer outputFormatForBus:0]];
        
        [_audioEngine connect:_reverb to:_mixerNode format:[_reverb outputFormatForBus:0]];
        
        [self initAudioSession];
    }
    
    return self;
}

- (void)initAudioSession {
    __autoreleasing NSError *error = nil;
    
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) NSLog(@"\nsetCategory error:\n\n%@\n\n", error.debugDescription);
    if (error) NSLog(@"\nsetMode error:\n\n%@\n\n", error.debugDescription);
    [sessionInstance setPreferredOutputNumberOfChannels:2 error:&error];
    if (error) NSLog(@"\nsetPreferredOutputNumberOfChannels error:\n\n%@\n\n", error.debugDescription);
    [sessionInstance setActive:YES error:&error];
    if (error) NSLog(@"\nsetActive error:\n\n%@\n\n", error.debugDescription);
}

- (float)generateRandomNumberBetweenMin:(int)min Max:(int)max
{
    return ( (arc4random() % (max-min+1)) + min );
}



//- (AVAudioPCMBuffer *)createAudioBufferWithLoopableSineWaveFrequency:(NSUInteger)frequency
//{
//    AVAudioFormat *mixerFormat = [_mixerNode outputFormatForBus:0];
//    NSUInteger randomNum = [self generateRandomNumberBetweenMin:1 Max:4];
//    double frameLength = mixerFormat.sampleRate / randomNum;
//    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerFormat frameCapacity:frameLength];
//    pcmBuffer.frameLength = frameLength;
//
//    float *leftChannel = pcmBuffer.floatChannelData[0];
//    float *rightChannel = mixerFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;
//
//    NSUInteger r = arc4random_uniform(2);
//    double amplitude_step  = (1.0 / frameLength > 0.000100) ? (((double)arc4random() / 0x100000000) * (0.000100 - 0.000021) + 0.000021) : 1.0 / frameLength;
//    double amplitude_value = 0.0;
//    for (int i_sample = 0; i_sample < pcmBuffer.frameCapacity; i_sample++)
//    {
//        amplitude_value += amplitude_step;
//        double amplitude = pow(((r == 1) ? ((amplitude_value < 1.0) ? (amplitude_value) : 1.0) : ((1.0 - amplitude_value > 0.0) ? 1.0 - (amplitude_value) : 0.0)), ((r == 1) ? randomNum : 1.0/randomNum));
//        amplitude = ((amplitude < 0.000001) ? 0.000001 : amplitude);
//        double value = sinf((frequency*i_sample*2*M_PI) / mixerFormat.sampleRate);
//        if (leftChannel)  leftChannel[i_sample]  = value * amplitude;
//        if (rightChannel) rightChannel[i_sample] = value * (1.0 - amplitude);
//    }
//
//    return pcmBuffer;
//}

//

/// / To-Do: Use dispatch_io to read buffers instead

static const float high_frequency = 6000.0;
static const float low_frequency  = 1000.0;

NSArray<NSDictionary<NSString *, id> *> *(^tonesDictionary)(void) = ^NSArray<NSDictionary<NSString *, id> *> *(void)
{
    NSMutableArray *tones = [NSMutableArray arrayWithCapacity:90];
    for (int i = 0; i < 180; i++)
    {
        AVAudioTime *time = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
        NSDictionary *td = @{@"time" : time,
                             @"frequency_right" : @((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)),
                             @"frequency_left" : @((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency))};
        [tones addObject:td];
        
        float randomNum = (((double)arc4random() / 0x100000000) * (1.0 - 0.0) + 0.0);
        CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
        time = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
        td = @{@"time" : time,
               @"frequency_right" : @((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)),
               @"frequency_left" : @((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency))};
        [tones addObject:td];
    }
    
    return tones;
};

- (void)togglePlayWithAudioEngineRunningStatusCallback:(void (^(^)(void))(BOOL))audioEngineRunningStatus
{
        if (![self->_audioEngine isRunning])
        {
            __autoreleasing NSError *error = nil;
            audioEngineRunningStatus()([self.audioEngine startAndReturnError:&error]);
            if (error) NSLog(@"\nstartAndReturnError error:\n\n%@\n\n", error.debugDescription);
            
            [self initAudioSession];
            
            ([self->_playerOneNode isPlaying]) ?: [self->_playerOneNode play];
            ([self->_playerTwoNode isPlaying]) ?: [self->_playerTwoNode play];
             
            [[ClicklessTones sharedClicklessTones] createAudioBufferWithFormat:[_mixerNode outputFormatForBus:0] completionBlock:^(AVAudioPCMBuffer * _Nonnull buffer1, AVAudioPCMBuffer * _Nonnull buffer2, PlayToneCompletionBlock playToneCompletionBlock) {
                
                // TO-DO: Combine buffer1 and buffer2 into a single buffer and play on one node only for AirPlay (which seems to only play one node)
                
                
                (!self->_playerOneNode) ?: [self->_playerOneNode scheduleBuffer:buffer1 atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
//                    playToneCompletionBlock();
                }];
                
                (!self->_playerTwoNode) ?: [self->_playerTwoNode scheduleBuffer:buffer2 atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
                    playToneCompletionBlock();
                }];
                
            }];
            
        } else {
            [self->_audioEngine pause];
            audioEngineRunningStatus()([self.audioEngine isRunning]);
        }
}

NSArray<Frequencies *> * (^pairFrequencies)(NSArray<Frequencies *> *, AVAudioTime *) = ^NSArray<Frequencies *> * (NSArray<Frequencies *> * frequenciesPair, AVAudioTime *time)
{
    NSMutableArray<Frequencies *> *pairs = [NSMutableArray new];
    [pairs addObject:[[Frequencies alloc] initWithFrequency1:frequenciesPair.lastObject.frequency1.doubleValue
                                                  frequency2:frequenciesPair.lastObject.frequency2.doubleValue
                                               stereoChannel:(StereoChannel)frequenciesPair.lastObject.channel.unsignedIntValue
                                                        time:time]];
    [pairs addObject:[[Frequencies alloc] initWithFrequency1:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)
                                                  frequency2:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)
                                               stereoChannel:((StereoChannel)frequenciesPair.lastObject.channel.unsignedIntValue == StereoChannelRight) ? StereoChannelLeft : StereoChannelRight
                                                        time:time]];
    
    NSLog(@"Return frequencies (1st): %f\t%f", pairs.firstObject.frequency1.doubleValue, pairs.firstObject.frequency2.doubleValue);
    NSLog(@"Return frequencies (2nd): %f\t%f", pairs.lastObject.frequency1.doubleValue, pairs.lastObject.frequency2.doubleValue);
    NSLog(@"Time: %f", [AVAudioTime secondsForHostTime:[pairs.firstObject.time hostTime]]);
    
    return (NSArray<Frequencies *> *)pairs;
};

AVAudioTime *(^bufferSchedule)(CMTime, NSUInteger) = ^AVAudioTime *(CMTime current_time, NSUInteger count)
{
    CMTime scheduled_time = CMTimeAdd(current_time, CMTimeMakeWithSeconds(count, NSEC_PER_SEC));
    AVAudioTime *time = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(scheduled_time)];
    
    return time;
};

NSArray<NSArray<Frequencies *> *> *(^scoreFrequenciesPairs)(void) = ^NSArray<NSArray<Frequencies *> *> *(void)
{
    __block NSMutableArray *score = [NSMutableArray new];
    CMTime current_time = CMClockGetTime(CMClockGetHostTimeClock());
    __block NSUInteger count = 0;
    static void (^block)(Frequencies *);
    block = ^void(Frequencies *returnFrequencies)
    {
        NSArray<Frequencies *> *frequenciesPair = pairFrequencies(returnFrequencies, bufferSchedule(current_time, count++));
        [score addObject:frequenciesPair];
        if (score.count < 90) block([frequenciesPair lastObject]);
        //        if ([ToneGenerator.sharedGenerator.audioEngine isRunning]) block([frequenciesPair lastObject]); // Can't do this without a completion block that returns every frequenciesPair array
    };
    block(nil);
    
    return score;
};

double Normalize(double a, double b)
{
    return (double)(a / b);
}

#define max_frequency      1500.0
#define min_frequency       100.0
#define max_trill_interval    4.0
#define min_trill_interval    2.0
#define duration_interval     5.0
#define duration_maximum      2.0


// Elements of an effective tone:
// High-pitched
// Modulating amplitude
// Alternating channel output
// Loud
// Non-natural (no spatialization)
//
// Elements of an effective score:
// Random frequencies
// Random duration
// Random tonality

// To-Do: Multiply the frequency by a random number between 1.01 and 1.1)

typedef NS_ENUM(NSUInteger, TonalHarmony) {
    TonalHarmonyConsonance,
    TonalHarmonyDissonance,
    TonalHarmonyRandom
};

typedef NS_ENUM(NSUInteger, TonalInterval) {
    TonalIntervalUnison,
    TonalIntervalOctave,
    TonalIntervalMajorSixth,
    TonalIntervalPerfectFifth,
    TonalIntervalPerfectFourth,
    TonalIntervalMajorThird,
    TonalIntervalMinorThird,
    TonalIntervalRandom
};

typedef NS_ENUM(NSUInteger, TonalEnvelope) {
    TonalEnvelopeAverageSustain,
    TonalEnvelopeLongSustain,
    TonalEnvelopeShortSustain
};

double Tonality(double frequency, TonalInterval interval, TonalHarmony harmony)
{
    double new_frequency = frequency;
    switch (harmony) {
        case TonalHarmonyDissonance:
            new_frequency *= (1.1 + drand48());
            break;
            
        case TonalHarmonyConsonance:
            new_frequency = ToneGenerator.Interval(frequency, interval);
            break;
            
        case TonalHarmonyRandom:
            new_frequency = Tonality(frequency, interval, (TonalHarmony)arc4random_uniform(2));
            break;
            
        default:
            break;
    }
    
    return new_frequency;
}

double Envelope(double x, TonalEnvelope envelope)
{
    double x_envelope = 1.0;
    switch (envelope) {
        case TonalEnvelopeAverageSustain:
            x_envelope = sinf(x * M_PI) * (sinf((2 * x * M_PI) / 2));
            break;
            
        case TonalEnvelopeLongSustain:
            x_envelope = sinf(x * M_PI) * -sinf(
                                                ((Envelope(x, TonalEnvelopeAverageSustain) - (2.0 * Envelope(x, TonalEnvelopeAverageSustain)))) / 2.0)
            * (M_PI / 2.0) * 2.0;
            break;
            
        case TonalEnvelopeShortSustain:
            x_envelope = sinf(x * M_PI) * -sinf(
                                                ((Envelope(x, TonalEnvelopeAverageSustain) - (-2.0 * Envelope(x, TonalEnvelopeAverageSustain)))) / 2.0)
            * (M_PI / 2.0) * 2.0;
            break;
            
        default:
            break;
    }
    
    return x_envelope;
}

typedef NS_ENUM(NSUInteger, Trill) {
    TonalTrillUnsigned,
    TonalTrillInverse
};

+ (double(^)(double, double))Frequency
{
    return ^double(double time, double frequency)
    {
        return pow(sinf(M_PI * time * frequency), 2.0);
    };
}

+ (double(^)(double))TrillInterval
{
    return ^double(double frequency)
    {
        return ((frequency / (max_frequency - min_frequency) * (max_trill_interval - min_trill_interval)) + min_trill_interval);
    };
}

+ (double(^)(double, double))Trill
{
    return ^double(double time, double trill)
    {
        return pow(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5, 4.0);
    };
}

+ (double(^)(double, double))TrillInverse
{
    return ^double(double time, double trill)
    {
        return pow(-(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5) + 1.0, 4.0);
    };
}

+ (double(^)(double))Amplitude
{
    return ^double(double time)
    {
        return pow(sinf(time * M_PI), 3.0) * 0.5;
    };
}

+ (double(^)(double, TonalInterval))Interval
{
    return ^double(double frequency, TonalInterval interval)
    {
        double new_frequency = frequency;
        switch (interval)
        {
            case TonalIntervalUnison:
                new_frequency *= 1.0;
                break;
                
            case TonalIntervalOctave:
                new_frequency *= 2.0;
                break;
                
            case TonalIntervalMajorSixth:
                new_frequency *= 5.0/3.0;
                break;
                
            case TonalIntervalPerfectFifth:
                new_frequency *= 4.0/3.0;
                break;
                
            case TonalIntervalMajorThird:
                new_frequency *= 5.0/4.0;
                break;
                
            case TonalIntervalMinorThird:
                new_frequency *= 6.0/5.0;
                break;
                
            case TonalIntervalRandom:
                new_frequency = ToneGenerator.Interval(frequency, (TonalInterval)arc4random_uniform(7));
                
            default:
                break;
        }
        
        return new_frequency;
    };
};

AVAudioPCMBuffer * (^audioBufferFromFrequencies)(Frequencies *, AVAudioFormat *) = ^AVAudioPCMBuffer *(Frequencies *frequencies, AVAudioFormat *audioFormat)
{
    AVAudioFrameCount frameCount = audioFormat.sampleRate;
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
    pcmBuffer.frameLength = frameCount;
    float *left_channel  = pcmBuffer.floatChannelData[0];
    float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : nil;
    
    
    double harmonized_frequency = Tonality(frequencies.frequency1.doubleValue, TonalIntervalRandom, TonalHarmonyRandom);
    double trill_interval       = ToneGenerator.TrillInterval(frequencies.frequency1.doubleValue);
    for (int index = 0; index < frameCount; index++)
    {
        double normalized_index = Normalize(index, frameCount);
        double trill            = ToneGenerator.Trill(normalized_index, trill_interval);
        double trill_inverse    = ToneGenerator.TrillInverse(normalized_index, trill_interval);
        double amplitude        = ToneGenerator.Amplitude(normalized_index);
        
//    int amplitude_frequency = arc4random_uniform(8) + 4;
        if (left_channel) left_channel[index] = ToneGenerator.Frequency(normalized_index, frequencies.frequency1.doubleValue) * amplitude * trill;
        if (right_channel) right_channel[index] = ToneGenerator.Frequency(normalized_index, harmonized_frequency) * amplitude * trill_inverse;
        
//        if (left_channel)  left_channel[index]  = (NormalizedSineEaseInOut(normalized_index, frequencies.frequency1.doubleValue) * NormalizedSineEaseInOut(normalized_index, amplitude_frequency));
//        if (right_channel) right_channel[index] = (NormalizedSineEaseInOut(normalized_index, frequencies.frequency2.doubleValue) * NormalizedSineEaseInOut(normalized_index, amplitude_frequency)); // fade((leading_fade == FadeOut) ? FadeIn : leading_fade, normalized_index, (SineEaseInOutFrequency(normalized_index, frequencyRight) * NormalizedSineEaseInOutAmplitude((1.0 - normalized_index), 1)));
    }
    
    return pcmBuffer;
};

void (^scheduleBuffers)(AVAudioPlayerNode *, AVAudioPlayerNode *, AVAudioFormat *) = ^void(AVAudioPlayerNode *playerNode1, AVAudioPlayerNode *playerNode2, AVAudioFormat *audioFormat)
{
    // TO-DO:
    // Create a new frequency object
    // Pass it to the audio buffer block
    // Use
    
//    AVAudioTime *time = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
    NSArray<NSArray<Frequencies *> *> *score = (NSArray<NSArray<Frequencies *> *> *)[NSArray arrayWithArray:scoreFrequenciesPairs()];
    for (NSUInteger index = 0; index < score.count; index++)  // (NSArray<Frequencies *> *frequencyPair in score)
    {
        NSArray<Frequencies *> *frequencyPair = (NSArray<Frequencies *> *)[score objectAtIndex:index];
        [playerNode1 scheduleBuffer:audioBufferFromFrequencies([frequencyPair firstObject], audioFormat) atTime:[[frequencyPair firstObject] time] options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
            NSLog(@"%lu Played frequencies (1st): %f\t%f\t%f", index, frequencyPair.firstObject.frequency1.doubleValue, frequencyPair.firstObject.frequency2.doubleValue, [AVAudioTime secondsForHostTime:[frequencyPair.firstObject.time hostTime]]);
        }];
        [playerNode2 scheduleBuffer:audioBufferFromFrequencies([frequencyPair lastObject], audioFormat) atTime:[[frequencyPair lastObject] time] options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
           NSLog(@"%lu Played frequencies (2nd): %f\t%f\t%f", index, frequencyPair.lastObject.frequency1.doubleValue, frequencyPair.lastObject.frequency2.doubleValue, [AVAudioTime secondsForHostTime:[frequencyPair.lastObject.time hostTime]]);
        }];
    }
};

typedef void (^DataPlayedBackCompletionBlock)(void);
typedef void (^DataRenderedCompletionBlock)(NSArray<Frequencies *> * frequencyPair, DataPlayedBackCompletionBlock dataPlayedBackCompletionBlock);

- (BOOL)stop
{
    (![self.audioEngine isRunning]) ?: [self->_audioEngine pause];
    
    return [self.audioEngine isRunning];
}

@end
