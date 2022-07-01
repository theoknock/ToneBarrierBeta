//
//  ClicklessTones.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ClicklessTones.h"
#include "easing.h"


static const float high_frequency = 3000.0;
static const float low_frequency  = 500.0;
static const float min_duration   = 0.25;
static const float max_duration   = 2.0;
static const double PI_SQUARED = 2.0 * M_PI;


static unsigned int fade_bit = 1;

@interface ClicklessTones ()
{
//    double frequency[2];
//    NSInteger alternate_channel_flag;
//    double duration_bifurcate;
}

@property (nonatomic, readonly) GKMersenneTwisterRandomSource * _Nullable randomizer;
@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor;

// Randomizes duration
@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor_duration;

@end


@implementation ClicklessTones

static ClicklessTones *sharedClicklessTones = NULL;
+ (nonnull ClicklessTones *)sharedClicklessTones
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
        if (!sharedClicklessTones)
        {
            sharedClicklessTones = [[self alloc] init];
        }
    });
    
    return sharedClicklessTones;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _randomizer  = [[GKMersenneTwisterRandomSource alloc] initWithSeed:time(NULL)];
        _distributor = [[GKGaussianDistribution alloc] initWithRandomSource:_randomizer mean:(high_frequency / .75) deviation:low_frequency];
        _distributor_duration = [[GKGaussianDistribution alloc] initWithRandomSource:_randomizer mean:max_duration deviation:min_duration];
    }
    
    return self;
}

typedef NS_ENUM(NSUInteger, Fade) {
    FadeOut,
    FadeIn
};

float normalize(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

double (^fade)(Fade, double, double) = ^double(unsigned long fadeType, double x, double freq_amp)
{
    double fade_effect = freq_amp * ((fade_bit) ? (1.0 - x) : x);
//    printf("fade %s\n", (fade_bit && 1UL) ? "out" : "in");
    
    return fade_effect;
};

- (float)generateRandomNumberBetweenMin:(int)min Max:(int)max
{
    return ( (arc4random() % (max-min+1)) + min );
}

const double (^phase_validator)(double) = ^ double (double phase) {
    if (phase >= PI_SQUARED) phase -= PI_SQUARED;
    if (phase < 0.0)     phase += PI_SQUARED;
    return phase;
};

static double(^randomize)(double, double, double) = ^ double (double min, double max, double weight) {
    double random = drand48();
    double weighted_random = pow(random, weight);
    double frequency = (weighted_random * (max - min)) + min;
    
    return frequency;
};


const AVAudioPCMBuffer * (^tone_audio_buffer)(AVAudioFormat *) = ^ AVAudioPCMBuffer * (AVAudioFormat * audio_format) {
    const double sample_rate = [audio_format sampleRate];
    const AVAudioChannelCount channel_count = audio_format.channelCount;
    const AVAudioFrameCount frame_count = sample_rate * channel_count;
    AVAudioPCMBuffer * audio_pcm_buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audio_format frameCapacity:frame_count];
    
    for (int channel_index = 0; channel_index < channel_count; channel_index++)
    {
        double signal_frequency = randomize(low_frequency, high_frequency, 30.0/180.0);
        double amplitude_frequency = ^ double (int n, int m) {
            double result = (random() % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n)) * .01;
            return result;
        }(25, 175);
    }
    return audio_pcm_buffer;
};
        printf("divider == %f\n", divider);

        const double phase_increment = PI_SQUARED / frame_count;
        double signal_phase = 0.0;
        double signal_increment = signal_frequency * phase_increment;
        double signal_increment_aux = (signal_frequency * (5.0/4.0)) * phase_increment;

        double amplitude_frequency = 1.0;
        double amplitude_phase = 0.0;
        double amplitude_increment = (amplitude_frequency) * phase_increment;


        if (float_channel_data[channel_index])
            for (int buffer_index = 0; buffer_index < frame_count; buffer_index++) {
                //                                                sinf(tremolo_phase) *
                float_channel_data[channel_index][buffer_index] =                           sinf(amplitude_phase) * sinf(signal_phase);
                signal_phase += ^ double (double time) { return (time < divider) ? signal_increment : signal_increment_aux; } (scale(0.0, 1.0, buffer_index, 0, frame_count));

                phase_validator(signal_phase);
                amplitude_phase += amplitude_increment;
                phase_validator(amplitude_phase);
                tremolo_phase += ^ double (double time) { return time * tremolo_increment; } (scale(MIN(tremolo_min, tremolo_frequency), MIN(tremolo_max, tremolo_frequency), buffer_index, 0, frame_count));
                phase_validator(tremolo_phase);
            }
        chord_frequency_ratios->indices.ratio++;
    }


    return audio_pcm_buffer;
};

/*
 
 Updated AVAudioPCMBuffer renderer
 
 play_tones =
 ^ (__weak typeof(AVAudioPlayerNode) * player_node,
 __weak typeof(AVAudioPCMBuffer) * pcm_buffer,
 __weak typeof(AVAudioFormat) * audio_format) {
 
 const double sample_rate = [audio_format sampleRate];
 
 const AVAudioChannelCount channel_count = audio_format.channelCount;
 const AVAudioFrameCount frame_count = sample_rate * 2.0;
 pcm_buffer.frameLength = frame_count;
 
 const double PI_2 = 2.0 * M_PI;
 const double phase_increment = PI_2 / frame_count;
 
 
 dispatch_queue_t samplerQueue = dispatch_queue_create("com.blogspot.demonicactivity.samplerQueue", DISPATCH_QUEUE_SERIAL);
 dispatch_block_t samplerBlock = dispatch_block_create(0, ^{

     ^ (AVAudioChannelCount channel_count, AVAudioFrameCount frame_count, double sample_rate, float * const _Nonnull * _Nullable float_channel_data) {
         for (int channel_index = 0; channel_index < channel_count; channel_index++)
         {
             double signal_frequency = (^ double (double fundamental_frequency, double frequency_ratio) {
                 return (fundamental_frequency * frequency_ratio);
             } ((chord_frequency_ratios->indices.ratio == 0 || chord_frequency_ratios->indices.ratio == 2)
                ? ^ double (double * root_frequency, long random) {
                 *root_frequency = pow(1.059463094f, random) * 440.0;
                 return *root_frequency;
             } (&chord_frequency_ratios->root, ^ long (long random, int n, int m) {
                 long result = random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n);
                 return result;
             } (random(), -8, 24))
                : chord_frequency_ratios->root,
                ratio[1][chord_frequency_ratios->indices.ratio]));
//                            if (chord_frequency_ratios->indices.ratio == 0) chord_frequency_ratios->indices.chord++;

             double divider = ^ double (long random, int n, int m) {
                 double result = (random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n)) * .01;
                 return result;
             } (random(), 25, 175);

             printf("divider == %f\n", divider);

             double signal_phase = 0.0;
             double signal_increment = signal_frequency * phase_increment;
             double signal_increment_aux = signal_frequency * (5.0/4.0)                                                      * phase_increment;
 //                                                                     ratio[1][chord_frequency_ratios->indices.ratio])

             double amplitude_frequency = 1.0;
             double amplitude_phase = 0.0;
             double amplitude_increment = (amplitude_frequency) * phase_increment;

             double tremolo_min, tremolo_max;
             tremolo_min = (chord_frequency_ratios->indices.ratio == 0 || chord_frequency_ratios->indices.ratio == 2) ? 4.0 : 6.0;
             tremolo_max = (chord_frequency_ratios->indices.ratio == 0 || chord_frequency_ratios->indices.ratio == 2) ? 6.0 : 4.0;
             double tremolo_frequency   = scale(tremolo_min, tremolo_max, chord_frequency_ratios->root, 277.1826317, 1396.912916);

             double tremolo_phase = 0.0;
             double tremolo_increment = (tremolo_frequency) * phase_increment;

             if (float_channel_data[channel_index])
                 for (int buffer_index = 0; buffer_index < frame_count; buffer_index++) {
                     //                                                sinf(tremolo_phase) *
                     float_channel_data[channel_index][buffer_index] =                           sinf(amplitude_phase) * sinf(signal_phase);
                     signal_phase += ^ double (double time) { return (time < divider) ? signal_increment : signal_increment_aux; } (scale(0.0, 1.0, buffer_index, 0, frame_count));

                     phase_validator(signal_phase);
                     amplitude_phase += amplitude_increment;
                     phase_validator(amplitude_phase);
                     tremolo_phase += ^ double (double time) { return time * tremolo_increment; } (scale(MIN(tremolo_min, tremolo_frequency), MIN(tremolo_max, tremolo_frequency), buffer_index, 0, frame_count));
                     phase_validator(tremolo_phase);
                 }
             chord_frequency_ratios->indices.ratio++;
         }

     } (channel_count, frame_count, sample_rate, pcm_buffer.floatChannelData);
 });
 dispatch_block_t playToneBlock = dispatch_block_create(0, ^{
     ^ (PlayedToneCompletionBlock played_tone) {
         if ([player_node isPlaying])
         {
//                            report_memory();

             [player_node prepareWithFrameCount:frame_count];
             [player_node scheduleBuffer:pcm_buffer
                                  atTime:nil
                                 options:AVAudioPlayerNodeBufferInterruptsAtLoop
                  completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack
                       completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
                 if (callbackType == AVAudioPlayerNodeCompletionDataPlayedBack)
                     played_tone();
             }];
         }
     } (^ {
         play_tones(player_node, pcm_buffer, audio_format);
     });
 });
 dispatch_block_notify(samplerBlock, dispatch_get_main_queue(), playToneBlock);
 dispatch_async(samplerQueue, samplerBlock);
};
 
 */

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    
//    self->frequency[0] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//    self->frequency[1] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
    static AVAudioPCMBuffer * (^createAudioBuffer)(Fade, double, double);
    
    createAudioBuffer = ^AVAudioPCMBuffer *(Fade leading_fade, double frequencyLeft, double frequencyRight)
    {
        AVAudioFrameCount frameCount = audioFormat.sampleRate * (2.0 / [self generateRandomNumberBetweenMin:2 Max:4]);
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
        pcmBuffer.frameLength = frameCount;
        float *left_channel  = pcmBuffer.floatChannelData[0];
        float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : nil;
        
        int amplitude_frequency = arc4random_uniform(4) + 2;
        for (int index = 0; index < frameCount; index++)
        {
            double normalized_index = LinearInterpolation(index, frameCount);
            if (left_channel)  left_channel[index]  = NormalizedSineEaseInOut(normalized_index, frequencyLeft, 2);
            if (right_channel)  right_channel[index]  = NormalizedSineEaseInOut(normalized_index, frequencyRight, 2);
        }
        
        //        self->frequency[0] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency); //self->frequency[1];
        //        self->frequency[1] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
        
        return pcmBuffer;
    };
    
    static void (^block)(void);
    block = ^void(void)
    {
        // To combine both buffers, multiple the sum of the amplitude by the sum of the frequency/signal)
        
        dispatch_async(dispatch_get_main_queue(), ^{
            fade_bit ^= 1;
            createAudioBufferCompletionBlock(createAudioBuffer(fade_bit, [self->_distributor nextInt]/*(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)*/, [self->_distributor nextInt] /*(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)*/),
                                             createAudioBuffer(fade_bit, [self->_distributor nextInt] /*(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)*/, [self->_distributor nextInt] /*(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)*/), ^{
                //            NSLog(@"alternate_channel_flag == %ld", (long)self->alternate_channel_flag);
                //            self->alternate_channel_flag = (self->alternate_channel_flag == 1) ? 0 : 1; // replace with bitwise XOR to toggle between 0 and 1 (self->alternate_channel_flag should be an unsigned primitive)
                //            self->duration_bifurcate = [self->_distributor_duration nextInt]; //(((double)arc4random() / 0x100000000) * (max_duration - min_duration) + min_duration);
                // THIS IS WRONG (BELOW)
                //            self->frequency[0] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency); //self->frequency[1];
                //            self->frequency[1] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
                block();
            });
        });
    };
    block();
    
    
}

@end
