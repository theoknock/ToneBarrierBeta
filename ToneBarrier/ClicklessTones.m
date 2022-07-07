//
//  ClicklessTones.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ClicklessTones.h"
#include "easing.h"


static const float  high_frequency = 3000.0;
static const float  low_frequency  = 440.0;
static const float  min_duration   = 0.25;
static const float  max_duration   = 2.0;
static const double PI_SQUARED     = 2.0 * M_PI;

//static const float high_frequency = 6000.0;
//static const float low_frequency  = 1000.0;

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
    TonalIntervalOffkey,
    TonalIntervalDefault
};

typedef NS_ENUM(NSUInteger, TonalEnvelope) {
    TonalEnvelopeAverageSustain,
    TonalEnvelopeLongSustain,
    TonalEnvelopeShortSustain
};

static double (^tonal_interval)(TonalInterval) = ^ double (TonalInterval interval) {
    double consonant_harmonic_interval_ratios[8] = {1.0, 2.0, 5.0/3.0, 4.0/3.0, 5.0/4.0, 6.0/5.0, (1.1 + drand48()), tonal_interval(TonalIntervalUnison)};
    
    return consonant_harmonic_interval_ratios[interval % 8];
};

static TonalHarmony (^tonal_harmony)(void) = ^ TonalHarmony {
    return ^ TonalHarmony {
        double random = drand48();
        double weighted_random = pow(random, 0.75);
        TonalHarmony rounded_random = (TonalHarmony)round(weighted_random);
        return rounded_random;
    }();
};

static double (^tonal)(double root_frequency) = ^ double (double root_frequency) {
    static TonalInterval interval = TonalIntervalOffkey;
    static TonalHarmony  harmony  = TonalHarmonyDissonance;
    
    interval = (harmony != TonalHarmonyDissonance) ?: TonalIntervalOffkey;
    double harmonic_frequency = root_frequency * tonal_interval(interval);
    harmony  = (harmony != TonalHarmonyDissonance) ? tonal_harmony() : TonalHarmonyConsonance;
    interval = (interval != TonalIntervalOffkey) ?: (TonalInterval)arc4random_uniform(TonalIntervalMinorThird - TonalIntervalOctave) + TonalIntervalOctave;
    
    return harmonic_frequency;
};

static double (^Percentage)(double, double, double) = ^double(double min, double max, double value) {
    double result = (value - min) / (max - min);

    return result;
};

typedef double (^Scale)(double, double, double, double, double);
Scale scale = ^double(double min_new, double max_new, double val_old, double min_old, double max_old) {
    double val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
    
    return val_new;
};

typedef double (^Linearize)(double, double, double);
Linearize linearize = ^double(double range_min, double range_max, double value)
{
    double result = (value * (range_max - range_min)) + range_min;

    return result;
};


typedef double (^RandomSource)(double, double);
static RandomSource random_source_drand48 = ^double(double lower_bound, double higher_bound) {
    double random = drand48();
    double result = (random * (higher_bound - lower_bound)) + lower_bound;
    
    return result;

};

typedef double (^RandomDistributor)(RandomSource random_source, double, double, double, double);
RandomDistributor random_distributor_gaussian_mean_variance = ^double(RandomSource random_source, double lower_bound, double upper_bound, double mean, double variance) {
    double result        = exp(-(pow((random_source(lower_bound, upper_bound) - mean), 2.0) / variance));
    double scaled_result = scale(0.0, 1.0, result, lower_bound, upper_bound);

    return scaled_result;
};



RandomDistributor random_distributor_gaussian_mean_standard_deviation = ^double(RandomSource random_source, double lower_bound, double upper_bound, double mean, double standard_deviation) {
    double result        = sqrt(1 / (2 * M_PI * standard_deviation)) * exp(-(1 / (2 * standard_deviation)) * (random_source(lower_bound, upper_bound) - mean) * 2);
    double scaled_result = scale(0.0, 1.0, result, lower_bound, upper_bound);

    return scaled_result;
};

typedef double (^FrequencySampler)(double, double);
FrequencySampler sample_frequency = ^(double time, double frequency)
{
    double result = sinf(M_PI * 2.0 * time * frequency);
    
    return result;
};

typedef double (^AmplitudeSampler)(double, double);
AmplitudeSampler sample_amplitude = ^(double time, double gain)
{
    double result = pow(sin(time * M_PI), gain);
    
    return result;
};


@interface ClicklessTones ()

@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor;
@property (nonatomic, readonly) GKMersenneTwisterRandomSource * _Nullable randomizer;

@end


@implementation ClicklessTones

static ClicklessTones * sharedClicklessTones = NULL;
+ (nonnull ClicklessTones *)sharedClicklessTones
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        if (!sharedClicklessTones)
        {
            sharedClicklessTones = [[self alloc] init];
        }
    });
    
    return sharedClicklessTones;
}

- (instancetype)init
{
    if (self = [super init]) {
        _randomizer  = [[GKMersenneTwisterRandomSource alloc] initWithSeed:time(NULL)];
        _distributor = [[GKGaussianDistribution alloc] initWithRandomSource:_randomizer mean:(high_frequency / .75) deviation:low_frequency];
    };
    
    return self;
}

//float normalize(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
//    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
//}
//
//static int (^arc4_randomize)(int, int) = ^ int (int min, int max) {
//    return arc4random() % (max - min + 1) + min;
//};
//
//static double(^randomize)(double, double, double) = ^ double (double min, double max, double weight) {
//    double random = drand48();
//    double weighted_random = pow(random, weight);
//    double frequency = (max - min) * (weighted_random - min) / (max - min) + min; // min + (weighted_random * (max - min));
//
//    return frequency;
//};

- (float)generateRandomNumberBetweenMin:(int)min Max:(int)max
{
    return ( (arc4random() % (max-min+1)) + min );
}

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    static AVAudioPCMBuffer * (^createAudioBuffer)(double, double);

    createAudioBuffer = ^AVAudioPCMBuffer *(double frequencyLeft, double frequencyRight)
    {
        AVAudioFrameCount frameCount = audioFormat.sampleRate * (2.0 / [self generateRandomNumberBetweenMin:2 Max:4]);
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
        pcmBuffer.frameLength = frameCount;
        float *left_channel  = pcmBuffer.floatChannelData[0];
        float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : nil;

        for (int index = 0; index < frameCount; index++)
        {
            double normalized_index = LinearInterpolation(index, frameCount);
            double left_signal_sample  = sample_signal(&normalized_index)(frequencyLeft,  2)();
            double right_signal_sample = sample_signal(&normalized_index)(frequencyRight, 2)();
            if (left_channel)  left_channel[index]  = left_signal_sample;  //NormalizedSineEaseInOut(normalized_index, frequencyLeft, 2);
            if (right_channel) right_channel[index] = right_signal_sample; //NormalizedSineEaseInOut(normalized_index, frequencyLeft, 2);; //NormalizedSineEaseInOut(normalized_index, frequencyRight, 2);
        }

        return pcmBuffer;
    };

    static void (^block)(void);
    block = ^void(void)
    {
        // To combine both buffers, multiple the sum of the amplitude by the sum of the frequency/signal)

        dispatch_async(dispatch_get_main_queue(), ^{
            createAudioBufferCompletionBlock(createAudioBuffer((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency), (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)),
                                             createAudioBuffer((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency), (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)), ^{
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


//double signal_frequency = ^ double (double fundamental_frequency, double frequency_ratio) {
//    return (fundamental_frequency * frequency_ratio);
//} ((chord_frequency_ratios->indices.ratio == 0 || chord_frequency_ratios->indices.ratio == 2)
//   ? ^ double (double * root_frequency, long random) {
//    *root_frequency = pow(1.059463094f, random) * 440.0;
//    return *root_frequency;
//} (&chord_frequency_ratios->root, ^ long (long random, int n, int m) {
//    long result = random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n);
//    return result;
//} (random(), -8, 24))
//   : chord_frequency_ratios->root,
//   ratio[1][chord_frequency_ratios->indices.ratio]);

//- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
//{
//    AVAudioPCMBuffer * (^createAudioBuffer)(double, double, double, double) = ^ AVAudioPCMBuffer * (double tone_frequency_left_a, double tone_frequency_left_b, double tone_frequency_right_a, double tone_frequency_right_b) {
//        AVAudioChannelCount channel_count = audioFormat.channelCount;
//        AVAudioFrameCount frame_count = audioFormat.sampleRate * channel_count;
//        AVAudioPCMBuffer * pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frame_count];
//        pcmBuffer.frameLength = frame_count;
//        float * left_channel  = pcmBuffer.floatChannelData[0];
//        float * right_channel = (channel_count == 2) ? pcmBuffer.floatChannelData[1] : nil;
//        
//        AVAudioFramePosition split_frame_position_left = frame_count * drand48();
//        AVAudioFramePosition split_frame_position_right = frame_count * drand48();
//        int amplitude_left_a = (arc4random_uniform(12)) + 6;
//        int amplitude_left_b = (arc4random_uniform(12)) + 6;
//        int amplitude_right_a = (arc4random_uniform(12)) + 6;
//        int amplitude_right_b = (arc4random_uniform(12)) + 6;
//        
//        AVAudioFramePosition index = 0;
//        double (^normalized_time)(void) = signal_time(&index, frame_count);
//        double normalized_index = 0;
//        double root_frequency = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//        double (^signal_sample[2])(void);
//        sample[0] = (sample_signal(&normalized_index))(root_frequency, (arc4random_uniform(12)) + 6);
//        sample[1] = (sample_signal(&normalized_index))(tonal(root_frequency), (arc4random_uniform(12)) + 6);
//        
//        for (index = 0; index < frame_count; index++)
//        {
//            normalized_index = normalized_time();
//            
//            //            if (left_channel)  left_channel[index]  = tonal(signal); //+ (0.5 * (NormalizedSineEaseInOut(normalized_index, tonal(tone_frequency_left_1), amplitude) - NormalizedSineEaseInOut(normalized_index, tone_frequency_left_1, amplitude)));
//            
//            //            if (left_channel)  left_channel[index]  = NormalizedSineEaseInOut(normalized_index, tone_frequency_left_a, amplitude_left_a) + (((index > split_frame_position_left) ? 1.0 : 0.0) * (NormalizedSineEaseInOut(normalized_index, tone_frequency_left_b, amplitude_left_b) - NormalizedSineEaseInOut(normalized_index, tone_frequency_left_a, amplitude_left_a)));
//            //            if (right_channel) right_channel[index] = NormalizedSineEaseInOut(normalized_index, tone_frequency_right_a, amplitude_right_a) + (((index > split_frame_position_right) ? 1.0 : 0.0) * (NormalizedSineEaseInOut(normalized_index, tone_frequency_right_b, amplitude_right_b) - NormalizedSineEaseInOut(normalized_index, tone_frequency_right_a, amplitude_right_a)));
//            if (left_channel)  left_channel[index]  = left_signal[0]; //signal_sample(normalized_index, tone_frequency_left_a, amplitude_left_a) + (((index > split_frame_position_left) ? 1.0 : 0.0) * (signal_sample(normalized_index, tone_frequency_left_b, amplitude_left_b) - signal_sample(normalized_index, tone_frequency_left_a, amplitude_left_a)));
//            if (right_channel) right_channel[index] = right_signal[0]; //signal_sample(normalized_index, tone_frequency_right_a, amplitude_right_a) + (((index > split_frame_position_right) ? 1.0 : 0.0) * (signal_sample(normalized_index, tone_frequency_right_b, amplitude_right_b) - signal_sample(normalized_index, tone_frequency_right_a, amplitude_right_a)));
//        }
//        
//        return pcmBuffer;
//    };
//    
//    static void (^play_tones_loop)(void);
//    play_tones_loop = ^ void (void)
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // creates two pairs of clickless tones, one for each player node to play
//            createAudioBufferCompletionBlock(createAudioBuffer((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency),
//                                                               (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency),
//                                                               (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency),
//                                                               (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)),
//                                             createAudioBuffer((((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency),
//                                                               (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency),
//                                                               (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency),
//                                                               (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)),
//                                             ^{ play_tones_loop(); }); // executed by the caller after the tones are played
//        });
//    };
//    play_tones_loop(); // starts the loop
//}



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
 const double (^phase_validator)(double) = ^ double (double phase) {
 if (phase >= PI_2) phase -= PI_2;
 if (phase < 0.0)   phase += PI_2;
 
 return phase;
 };
 
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

const double (^phase_validator)(double) = ^ double (double phase) {
    if (phase >= PI_SQUARED) phase -= PI_SQUARED;
    if (phase < 0.0)     phase += PI_SQUARED;
    return phase;
};



/*
 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 ------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */

@end

//const AVAudioPCMBuffer * (^tone_audio_buffer)(AVAudioFormat *) = ^ AVAudioPCMBuffer * (AVAudioFormat * audio_format) {
//    const AVAudioChannelCount channel_count = audio_format.channelCount;
//    const AVAudioFrameCount frame_count     = audio_format.sampleRate * channel_count;
//    AVAudioPCMBuffer * sample_buffer        = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audio_format frameCapacity:frame_count];
//    float * left_channel  = sample_buffer.floatChannelData[0];
//    float * right_channel = channel_count == 2 ? sample_buffer.floatChannelData[1] : nil;
//
//    for (int channel_index = 0; channel_index < channel_count; channel_index++)
//    {
//        double signal_frequency = randomize(low_frequency, high_frequency, 30.0/180.0);
//
//        const double phase_increment = PI_SQUARED / frame_count;
//        double signal_phase = 0.0;
//        double signal_increment = signal_frequency * phase_increment;
//        double signal_increment_aux = (signal_frequency * (5.0/4.0)) * phase_increment;
//
//        double amplitude_frequency = 1.0;
//        double amplitude_phase = 0.0;
//        double amplitude_increment = (amplitude_frequency) * phase_increment;
//
//        double divider = ^ double (long random, int n, int m) {
//            double result = (random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n)) * .01;
//            return result;
//        } (random(), 25, 175);
//
//        if (sample_buffer.floatChannelData[channel_index])
//            for (int buffer_index = 0; buffer_index < frame_count; buffer_index++) {
//                //                                                sinf(tremolo_phase) *
//                sample_buffer.floatChannelData[channel_index][buffer_index] = sinf(amplitude_phase) * sinf(signal_phase);
//                signal_phase += ^ double (double time) { return (time < divider) ? signal_increment : signal_increment_aux; } (scale(0.0, 1.0, buffer_index, 0, frame_count));
//
//                phase_validator(signal_phase);
//                amplitude_phase += amplitude_increment;
//                phase_validator(amplitude_phase);
////                tremolo_phase += ^ double (double time) { return time * tremolo_increment; } (scale(MIN(tremolo_min, tremolo_frequency), MIN(tremolo_max, tremolo_frequency), buffer_index, 0, frame_count));
////                phase_validator(tremolo_phase);
//            }
//    }
//    return sample_buffer;
//};


/*

#import "ClicklessTones.h"
#include "easing.h"


static const float high_frequency = 3000.0;
static const float low_frequency  = 500.0;
static const float min_duration   = 25;//0.25;
static const float max_duration   = 180;//2.0;
static const double PI_SQUARED = 2.0 * M_PI;

#define randomdouble()    (arc4random() / ((unsigned)RAND_MAX))
#define E_NUM 0.5772156649015328606065120900824024310421593359399235988057672348848677267776646709369470632917467495

static unsigned int fade_bit = 1;
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
        
    }
    
    return self;
}

float normalize(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

double (^fade)(double, double) = ^double(double x, double freq_amp)
{
    double fade_effect = freq_amp * ((fade_bit) ? (1.0 - x) : x);
//    printf("fade %s\n", (fade_bit && 1UL) ? "out" : "in");
    
    return 0effect;
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



//const AVAudioPCMBuffer * (^tone_audio_buffer)(AVAudioFormat *) = ^ AVAudioPCMBuffer * (AVAudioFormat * audio_format) {
//    const double sample_rate = [audio_format sampleRate];
//    const AVAudioChannelCount channel_count = audio_format.channelCount;
//    const AVAudioFrameCount frame_count = sample_rate * channel_count;
//    AVAudioPCMBuffer * audio_pcm_buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audio_format frameCapacity:frame_count];
//
//    for (int channel_index = 0; channel_index < channel_count; channel_index++)
//    {
//        double signal_frequency = randomize(low_frequency, high_frequency, 30.0/180.0);
//        double amplitude_frequency = ^ double (int n, int m) {
//            double result = (random() % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n)) * .01;
//            return result;
//        }(25, 175);
//    }
//    return audio_pcm_buffer;
//};
//        printf("divider == %f\n", divider);
//
//        const double phase_increment = PI_SQUARED / frame_count;
//        double signal_phase = 0.0;
//        double signal_increment = signal_frequency * phase_increment;
//        double signal_increment_aux = (signal_frequency * (5.0/4.0)) * phase_increment;
//
//        double amplitude_frequency = 1.0;
//        double amplitude_phase = 0.0;
//        double amplitude_increment = (amplitude_frequency) * phase_increment;
//
//
//        if (float_channel_data[channel_index])
//            for (int buffer_index = 0; buffer_index < frame_count; buffer_index++) {
//                //                                                sinf(tremolo_phase) *
//                float_channel_data[channel_index][buffer_index] =                           sinf(amplitude_phase) * sinf(signal_phase);
//                signal_phase += ^ double (double time) { return (time < divider) ? signal_increment : signal_increment_aux; } (scale(0.0, 1.0, buffer_index, 0, frame_count));
//
//                phase_validator(signal_phase);
//                amplitude_phase += amplitude_increment;
//                phase_validator(amplitude_phase);
//                tremolo_phase += ^ double (double time) { return time * tremolo_increment; } (scale(MIN(tremolo_min, tremolo_frequency), MIN(tremolo_max, tremolo_frequency), buffer_index, 0, frame_count));
//                phase_validator(tremolo_phase);
//            }
//        chord_frequency_ratios->indices.ratio++;
//    }
//
//
//    return audio_pcm_buffer;
//};

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
 


static double (^time_divider)(long, int, int) = ^ double (long random, int n, int m) {
    double result = (random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n)) * .01;
    printf("time_divider.result == %d\n\n", result);
    return result;
};

static AVAudioPCMBuffer * (^createAudioBuffer)(const void *, AVAudioFrameCount, uint32_t, double, double) = ^ AVAudioPCMBuffer * (const void * pcm_buffer_ref, AVAudioFrameCount frame_count, uint32_t channel_count, double frequency_left, double frequency_right)
{
    AVAudioPCMBuffer * pcm_buffer = CFBridgingRelease(pcm_buffer_ref);
    pcm_buffer.frameLength = frame_count;
    float *left_channel  = pcm_buffer.floatChannelData[0];
    float *right_channel = (channel_count == 2) ? pcm_buffer.floatChannelData[1] : nil;
    
    for (int index = 0; index < frame_count; index++)
    {
        double normalized_index = LinearInterpolation(index, frame_count);
        if (left_channel)  left_channel[index]  = NormalizedSineEaseInOut(normalized_index, frequency_left, 2);
        if (right_channel) right_channel[index] = NormalizedSineEaseInOut(normalized_index, frequency_right, 2);
    }
    
    return pcm_buffer;
};


- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    AVAudioFrameCount frameCount = audioFormat.sampleRate * (2.0 / time_divider(random(), min_duration, max_duration));
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
    
    static void (^block)(void);
    block = ^void(void)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            fade_bit ^= 1;
            double left_freq  = random_distributor_gaussian_mean_standard_deviation(low_frequency, high_frequency, 1.8333333333, 0.1666666667);
            printf("\n\nleft_freq == %f\n", left_freq);
            double left_harmonic_freq  = left_freq * (5.0/4.0);
            printf("left_harmonic_freq == %f\n", left_harmonic_freq);
            double right_freq = random_distributor_gaussian_mean_standard_deviation(low_frequency, high_frequency, 1.8333333333, 0.1666666667);
            printf("right_freq == %f\n", right_freq);
            double right_harmonic_freq = right_freq * (5.0/4.0);
            printf("right_harmonic_freq == %f\n\n", right_harmonic_freq);
            createAudioBufferCompletionBlock(createAudioBuffer((const id *)CFBridgingRetain(pcmBuffer), frameCount, 2, left_freq, left_harmonic_freq),
                                             createAudioBuffer((const id *)CFBridgingRetain(pcmBuffer), frameCount, 2, right_freq, right_harmonic_freq),
                                                                               ^{
                double divider = ^ long (long random, int n, int m) {
                    long result = random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n);
                    NSLog(@"result ==  %f", result);
                    long scaled_result = (scale(0.0, 1.0, result, MIN(m, n), MAX(m, n)) - 0.5);
                    result = 1.0 / (1.0 + pow(E_NUM, (-10.0 * scaled_result))); // normalize
                    
                    return result;
                } (random(), 11025, 77175);
                block();
            });
        });
    };
    block();
    
    
}

@end

*/
