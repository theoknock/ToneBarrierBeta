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
#import "ClicklessTones.h"

#include "easing.h"


@interface ToneGenerator ()

@property (nonatomic, strong) AVAudioSession    * audioSession;
@property (nonatomic, strong) AVAudioEngine     * audioEngine;
@property (nonatomic, strong) NSSet             * playerNodes;
@property (nonatomic, strong) AVAudioMixerNode  * mixerNode;
@property (nonatomic, strong) AVAudioMixerNode  * mainNode;
@property (nonatomic, strong) AVAudioUnitReverb * reverb;
@property (nonatomic, strong) AVAudioFormat     * audioFormat;

@property (nonatomic, strong) NSURL * mixerOutputFileURL;
@property (nonatomic, strong) AVAudioFile *mixerOutputFile;
@property (nonatomic, strong) AVAudioPCMBuffer * mixerOutputFileBuffer;
@property (nonatomic, strong) AVAudioPlayerNode * mixerOutputFilePlayer;

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

typedef const id * _Nonnull stored_object;
typedef stored_object (^storable_object)(void);
storable_object storable = ^ const id * _Nonnull {
    AVAudioPlayerNode * player = [[AVAudioPlayerNode alloc] init];
    return (stored_object)CFBridgingRetain(player);
};

typedef stored_object (^unstored_object)(void);
stored_object (^(^ _Nonnull store_object)(storable_object))(void) = ^ unstored_object (storable_object storable) {
    stored_object stored = storable();
    return ^ stored_object {
        return stored;
    };
};




//static void (^map)(const unsigned long) = ^ (const unsigned long count) {
//
//    typedef typeof(unstored_object) integrands[count];
//    typeof(integrands) integrands_ptr[count];
//    ^ (const id * _Nonnull integrands_t, const unsigned long index_count) {
//        __block unsigned long (^recursive_block)(unsigned long);
//        return ^ (void(^enumeration)(const id *)) {
//            return (recursive_block = ^ unsigned long (unsigned long index) {
//                --index;
//                const id * object_t = (const id * const)CFBridgingRetain((__bridge id)((__bridge const void * _Nonnull)(*((id * const)integrands_t + count))));
//                enumeration(object_t);
//                return (unsigned long)(index ^ 0UL) && (unsigned long)(recursive_block)(index);
//            })(index_count);
//        };
//    }(^ const id * _Nonnull (const id * _Nonnull integrands_t) {
//        *((id * const)integrands_t + count) = (__bridge id)((__bridge const void * _Nonnull)CFBridgingRelease(store_object(storable)));
//        return (const id *)(integrands_t);
//    }((const id *)&integrands_ptr), count);
//};


//CFTypeRef (^object)(const unsigned long) = ^ CFTypeRef (const unsigned long index) {
//    UIButton * button;
//    [button = [UIButton new] setTag:index];
//    printf("\nobject == %p\n", button);
//    return (CFTypeRef)CFBridgingRetain(button);
//};
//

//
//static void(^persistent_object)(void) = ^{
//
//};
//
//typedef typeof(unsigned long (^)(unsigned long)) iterator;
//typedef typeof(CFTypeRef(^__strong)(const unsigned long)) mapper;
//typedef typeof(void(^)(void(^ _Nonnull __strong)(CFTypeRef))) applier;
//static void (^(^(^iterate_)(const unsigned long))(typeof(mapper)))(void(^)(CFTypeRef)) = ^ (const unsigned long iterations) {
//    CFTypeRef obj_collection[iterations];
//    return ^ (CFTypeRef obj_collection_t) {
//        __block iterator integrand;
//        return ^ (mapper map) {
//            (integrand = ^ unsigned long (unsigned long index) {
//                --index;
//                //                *((id * const)obj_collection_t + index) =
//                map(index);
//                return (unsigned long)(index ^ 0UL) && (unsigned long)(integrand)(index);
//            })(iterations);
//            return ^ (applier apply) {
//                (integrand = ^ unsigned long (unsigned long index) {
//                    --index;
//                    //                    const id * button_t = (const id * const)CFBridgingRetain((__bridge id)((__bridge const void * _Nonnull)(*((id * const)obj_collection_t + index))));
//                    apply(obj_collection_t + index);
//                    //                    apply((const id _Nonnull * _Nonnull const)(*((id * const)obj_collection_t + index)));
//                    return (unsigned long)(index ^ 0UL) && (unsigned long)(integrand)(index);
//                })(iterations);
//            };
//        };
//    }(&obj_collection);
//};

id (^retainable_object)(id(^)(void)) = ^ id (id(^object)(void)) {
    return ^{
        return object();
    };
};

id (^(^retain_object)(id(^)(void)))(void) = ^ (id(^retainable_object)(void)) {
    id retained_object = retainable_object();
    return ^ id {
        return retained_object;
    };
};

typedef typeof(unsigned long (^)(unsigned long)) recursive_iterator;
static void (^(^iterator)(const unsigned long))(id(^)(void)) = ^ (const unsigned long object_count) {
    typeof(id(^)(void)) retained_objects_ref;
    return ^ (id * retained_objects_t) {
        return ^ (id(^object)(void)) {
            ^ (void (^(^retain_objects)(unsigned long))(void(^)(void))) {
                return ^ (unsigned long index) {
                    return retain_objects(index)(^{
                        printf("retained_object: %p\n", (*((id * const)retained_objects_t + index) = retain_object(retainable_object(object))));
                    });
                }(object_count);
            };
        };
    }((id *)&retained_objects_ref);
};



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _audioEngine = [[AVAudioEngine alloc] init];
        
        _mainNode = [self.audioEngine mainMixerNode];
        
        AVAudioChannelCount channelCount = [_mainNode outputFormatForBus:0].channelCount;
        const double sampleRate = [_mainNode outputFormatForBus:0].sampleRate;
        _audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:channelCount];
        
        [_audioEngine prepare];
        
        _mixerNode = [[AVAudioMixerNode alloc] init];
        _reverb = [[AVAudioUnitReverb alloc] init];
        [_reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeChamber];
        [_reverb setWetDryMix:50.0];
        
        [_audioEngine attachNode:_reverb];
        [_audioEngine attachNode:_mixerNode];
        
        id (^player_node_object)(void) = ^ id {
            AVAudioPlayerNode * player = [[AVAudioPlayerNode alloc] init];
            [player setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmAuto];
            [player setSourceMode:AVAudio3DMixingSourceModeAmbienceBed];
            [player setPosition:AVAudioMake3DPoint(0.0, 0.0, 0.0)];
            
            return player;
        }; iterator(2)(player_node_object);
        
        _playerNodes = [[NSSet alloc] initWithArray:@[retain_object(retainable_object(player_node_object)), retain_object(retainable_object(player_node_object))]];
        [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
            AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();

            [_audioEngine attachNode:player_node];
            [_audioEngine connect:player_node to:_mixerNode format:_audioFormat];
        }];

        [_audioEngine connect:_mixerNode to:_reverb     format:_audioFormat];
        [_audioEngine connect:_reverb    to:_mainNode   format:_audioFormat];
        
        _mixerOutputFilePlayer = [[AVAudioPlayerNode alloc] init];
        [_audioEngine attachNode:_mixerOutputFilePlayer];
        [_audioEngine connect:_mixerOutputFilePlayer to:_mixerNode format:[_mixerNode outputFormatForBus:0]];
    }
    
    return self;
}

- (NSError *)configureAudioSession {
    __autoreleasing NSError *error = nil;
    
    _audioSession = [AVAudioSession sharedInstance];
    [_audioSession setSupportsMultichannelContent:TRUE error:&error];
    [_audioSession setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault routeSharingPolicy:AVAudioSessionRouteSharingPolicyLongFormAudio
                       options:AVAudioSessionCategoryOptionAllowAirPlay error:&error];
    [_audioSession setPreferredOutputNumberOfChannels:2 error:&error];
    [_audioSession setPreferredInputNumberOfChannels:2 error:&error];
    [_audioSession setActive:YES error:&error];
    
    return error;
}

- (float)generateRandomNumberBetweenMin:(int)min Max:(int)max
{
    return ( (arc4random() % (max-min+1)) + min );
}

- (void)togglePlayWithAudioEngineRunningStatusCallback:(BOOL (^(^)(typeof(^{}) _Nullable))(BOOL, BOOL))audioEngineRunningStatus
{
    if (![self->_audioEngine isRunning])
    {
        __autoreleasing NSError *error = nil;
        audioEngineRunningStatus(nil)([_audioEngine startAndReturnError:&error] && [_audioEngine isRunning], [_mixerOutputFilePlayer isPlaying]);
        (!error) ? [self configureAudioSession] : NSLog(@"\nstartAndReturnError error:\n\n%@\n\n", error.debugDescription);
        
        const AVAudioChannelCount channel_count = _audioFormat.channelCount;
        const AVAudioFrameCount frame_count     = _audioFormat.sampleRate * channel_count;
        
        _mixerOutputFileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"mixerOutput.caf"]];
        _mixerOutputFile = [[AVAudioFile alloc] initForWriting:_mixerOutputFileURL settings:[[_mixerNode outputFormatForBus:0]  settings] error:&error];
        NSAssert(_mixerOutputFile != nil, @"mixerOutputFile is nil, %@", [error localizedDescription]);
        
        [_mixerNode installTapOnBus:0 bufferSize:frame_count format:[_mixerNode outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
            NSError *error;
            NSLog(@"RECORDING: %@\n", when);
            NSAssert([_mixerOutputFile writeFromBuffer:buffer error:&error], @"error writing buffer data to file, %@", [error localizedDescription]);
        }];
        
        [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
            AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();
            ((*stop = [player_node isPlaying])) ?: ^{ [player_node prepareWithFrameCount:frame_count]; [player_node play]; }();
        }];
        
        static unsigned int buffer_bit = 1;
        [[ClicklessTones sharedClicklessTones] createAudioBufferWithFormat:_audioFormat completionBlock:^(AVAudioPCMBuffer * _Nonnull buffer1, AVAudioPCMBuffer * _Nonnull buffer2, PlayToneCompletionBlock playToneCompletionBlock) {
            [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
                AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();
                (!player_node) ?: [player_node scheduleBuffer:(buffer_bit) ? buffer1 : buffer2 completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
                    buffer_bit ^= 1;
                    (buffer_bit) ?: playToneCompletionBlock();
                }];
            }];
        }];
        
    } else {
        audioEngineRunningStatus(^{
            printf("Pausing audio engine...\n");
            [self->_audioEngine pause];
            [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
                AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();
                ((*stop = ![player_node isPlaying])) ?: ^{ [player_node pause]; [player_node reset]; }();
            }];
            [_mixerNode removeTapOnBus:0]; })([self.audioEngine isRunning], [_mixerOutputFilePlayer isPlaying]);
    }
}

- (void)togglePlayFileWithAudioPlayerNodePlayingStatusCallback:(BOOL (^(^)(void))(BOOL, BOOL))audioPlayerNodePlayingStatus
{
    NSLog(@"%s\n", __PRETTY_FUNCTION__);
    if (![_mixerOutputFilePlayer isPlaying]) {
        if (_mixerOutputFileURL) {
            NSError *error;
            AVAudioFile *recordedFile = [[AVAudioFile alloc] initForReading:_mixerOutputFileURL error:&error];
            NSAssert(recordedFile != nil, @"recordedFile is nil, %@", [error localizedDescription]);
            [_mixerOutputFilePlayer scheduleFile:recordedFile atTime:nil completionHandler:^ (AVAudioPlayerNode * file_player) {
                return ^{
                    AVAudioTime *playerTime = [file_player playerTimeForNodeTime:file_player.lastRenderTime];
                    NSLog(@"PLAYING: %@\n", playerTime);
                    double delayInSecs = (recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [file_player stop];
                    });
                };
            }(_mixerOutputFilePlayer)];
            if ([_audioEngine startAndReturnError:&error]) [_mixerOutputFilePlayer play];
        } else {
            NSLog(@"\n\n%s\n\nERROR PLAYING RECORDING FILE\n\n", __PRETTY_FUNCTION__);
        }
    } else {
        [self->_audioEngine pause];
        [_mixerOutputFilePlayer pause];
    }
    
    //        typedef BOOL  (^block)(void);
    //        typedef block (^blk)(void);
//        typedef blk   (^b)(void);
//        typedef b     (^_)(b);
    //
    //
    //
//
//    ^ BOOL {
//        ^ (BOOL(^startOutputFilePlayer)(typeof(^{}))) {
//            ((startOutputFilePlayer (^{ ([_mixerOutputFilePlayer isPlaying]) ?: [_mixerOutputFilePlayer play]; }))
//             (^ BOOL { return [_mixerOutputFilePlayer isPlaying]; }));
//            return TRUE;
//        };
//
//    };
}

- (void)stopPlayingRecordedFile
{
    [_mixerOutputFilePlayer stop];
}

@end

/*
 - (AVAudioPCMBuffer *)createAudioBufferWithLoopableSineWaveFrequency:(NSUInteger)frequency
 {
 AVAudioFormat *mixerFormat = [_mixerNode outputFormatForBus:0];
 NSUInteger randomNum = [self generateRandomNumberBetweenMin:1 Max:4];
 double frameLength = mixerFormat.sampleRate / randomNum;
 AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerFormat frameCapacity:frameLength];
 pcmBuffer.frameLength = frameLength;

     float *leftChannel = pcmBuffer.floatChannelData[0];
     float *rightChannel = mixerFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;

     NSUInteger r = arc4random_uniform(2);
     double amplitude_step  = (1.0 / frameLength > 0.000100) ? (((double)arc4random() / 0x100000000) * (0.000100 - 0.000021) + 0.000021) : 1.0 / frameLength;
     double amplitude_value = 0.0;
     for (int i_sample = 0; i_sample < pcmBuffer.frameCapacity; i_sample++)
     {
         amplitude_value += amplitude_step;
         double amplitude = pow(((r == 1) ? ((amplitude_value < 1.0) ? (amplitude_value) : 1.0) : ((1.0 - amplitude_value > 0.0) ? 1.0 - (amplitude_value) : 0.0)), ((r == 1) ? randomNum : 1.0/randomNum));
         amplitude = ((amplitude < 0.000001) ? 0.000001 : amplitude);
         double value = sinf((frequency*i_sample*2*M_PI) / mixerFormat.sampleRate);
         if (leftChannel)  leftChannel[i_sample]  = value * amplitude;
         if (rightChannel) rightChannel[i_sample] = value * (1.0 - amplitude);
     }

     return pcmBuffer;
 }
*/

//double Envelope(double x, TonalEnvelope envelope)
//{
//    double x_envelope = 1.0;
//    switch (envelope) {
//        case TonalEnvelopeAverageSustain:
//            x_envelope = sinf(x * M_PI) * (sinf((2 * x * M_PI) / 2));
//            break;
//
//        case TonalEnvelopeLongSustain:
//            x_envelope = sinf(x * M_PI) * -sinf(
//                                                ((Envelope(x, TonalEnvelopeAverageSustain) - (2.0 * Envelope(x, TonalEnvelopeAverageSustain)))) / 2.0)
//            * (M_PI / 2.0) * 2.0;
//            break;
//
//        case TonalEnvelopeShortSustain:
//            x_envelope = sinf(x * M_PI) * -sinf(
//                                                ((Envelope(x, TonalEnvelopeAverageSustain) - (-2.0 * Envelope(x, TonalEnvelopeAverageSustain)))) / 2.0)
//            * (M_PI / 2.0) * 2.0;
//            break;
//
//        default:
//            break;
//    }
//
//    return x_envelope;
//}
//
//typedef NS_ENUM(NSUInteger, Trill) {
//    TonalTrillUnsigned,
//    TonalTrillInverse
//};
//
//+ (double(^)(double))TrillInterval
//{
//    return ^double(double frequency)
//    {
//        return ((frequency / (max_frequency - min_frequency) * (max_trill_interval - min_trill_interval)) + min_trill_interval);
//    };
//}
//
//+ (double(^)(double, double))Trill
//{
//    return ^double(double time, double trill)
//    {
//        return pow(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5, 4.0);
//    };
//}
//
//+ (double(^)(double, double))TrillInverse
//{
//    return ^double(double time, double trill)
//    {
//        return pow(-(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5) + 1.0, 4.0);
//    };
//}
//
//+ (double(^)(double))Amplitude
//{
//    return ^double(double time)
//    {
//        return pow(sinf(time * M_PI), 3.0) * 0.5;
//    };
//}
//
//
//
//AVAudioPCMBuffer * (^audioBufferFromFrequencies)(Frequencies *, AVAudioFormat *) = ^AVAudioPCMBuffer *(Frequencies *frequencies, AVAudioFormat *audioFormat)
//{
//    AVAudioFrameCount frameCount = audioFormat.sampleRate;
//    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
//    pcmBuffer.frameLength = frameCount;
//    float *left_channel  = pcmBuffer.floatChannelData[0];
//    float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : nil;
//
//
//    double harmonized_frequency = Tonality(frequencies.frequency1.doubleValue, TonalIntervalRandom, TonalHarmonyRandom);
//    double trill_interval       = ToneGenerator.TrillInterval(frequencies.frequency1.doubleValue);
//    for (int index = 0; index < frameCount; index++)
//    {
//        double normalized_index = Normalize(index, frameCount);
//        double trill            = ToneGenerator.Trill(normalized_index, trill_interval);
//        double trill_inverse    = ToneGenerator.TrillInverse(normalized_index, trill_interval);
//        double amplitude        = ToneGenerator.Amplitude(normalized_index);
//
////    int amplitude_frequency = arc4random_uniform(8) + 4;
//        if (left_channel) left_channel[index] = ToneGenerator.Frequency(normalized_index, frequencies.frequency1.doubleValue) * amplitude * trill;
//        if (right_channel) right_channel[index] = ToneGenerator.Frequency(normalized_index, harmonized_frequency) * amplitude * trill_inverse;
//
////        if (left_channel)  left_channel[index]  = (NormalizedSineEaseInOut(normalized_index, frequencies.frequency1.doubleValue) * NormalizedSineEaseInOut(normalized_index, amplitude_frequency));
////        if (right_channel) right_channel[index] = (NormalizedSineEaseInOut(normalized_index, frequencies.frequency2.doubleValue) * NormalizedSineEaseInOut(normalized_index, amplitude_frequency)); // fade((leading_fade == FadeOut) ? FadeIn : leading_fade, normalized_index, (SineEaseInOutFrequency(normalized_index, frequencyRight) * NormalizedSineEaseInOutAmplitude((1.0 - normalized_index), 1)));
//    }
//
//    return pcmBuffer;
//};
//
//@end
//
////
////typedef void (^DataPlayedBackCompletionBlock)(void);
////typedef void (^DataRenderedCompletionBlock)(NSArray<Frequencies *> * frequencyPair, DataPlayedBackCompletionBlock dataPlayedBackCompletionBlock);
////
////@end
