//
//  ToneBarrierScorePlayer-OLD.m
//  ToneBarrier
//
//  Created by Xcode Developer on 10/16/20.
//

import AVFoundation;
#import "ToneBarrierScorePlayer.h"

@implementation ToneBarrierScorePlayer (NSObject)

- (void)playToneBarrierScore
{
    dispatch_source_set_event_handler(ToneBarrierScorePlayer.sharedPlayer.audio_engine_command_dispatch_source, ^{
        struct AudioEngineCommand * audio_engine_command = dispatch_get_context(ToneBarrierScorePlayer.sharedPlayer.audio_engine_command_dispatch_source);
        if (audio_engine_command->command == AudioEngineCommandStop)
        {
            [self.playerNode pause];
            [self.playerNodeAux pause];
            
            [self.audioEngine pause];
            
            [self.audioEngine detachNode:self.playerNode];
            self.playerNode = nil;
            [self.audioEngine detachNode:self.playerNodeAux];
            self.playerNodeAux = nil;
            
            [self.audioEngine detachNode:self.reverb];
            self.reverb = nil;
            
            [self.audioEngine detachNode:self.mixerNode];
            self.mixerNode = nil;
            
            [self.audioEngine stop];
            
        } else if (audio_engine_command->command == AudioEngineCommandPlay) {
            if ([self setupEngine]) [self.audioEngine prepare];
            
            self.playerNode = [[AVAudioPlayerNode alloc] init];
            [self.playerNode setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmAuto];
            [self.playerNode setSourceMode:AVAudio3DMixingSourceModeAmbienceBed];
            [self.playerNode setPosition:AVAudioMake3DPoint(0.0, 0.0, 0.0)];
            
            self.playerNodeAux = [[AVAudioPlayerNode alloc] init];
            [self.playerNodeAux setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmAuto];
            [self.playerNodeAux setSourceMode:AVAudio3DMixingSourceModeAmbienceBed];
            [self.playerNodeAux setPosition:AVAudioMake3DPoint(0.0, 0.0, 0.0)];
            
            self.mixerNode = [[AVAudioMixerNode alloc] init];
            
            self.reverb = [[AVAudioUnitReverb alloc] init];
            [self.reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeChamber];
            [self.reverb setWetDryMix:50.0];
            
            [self.audioEngine attachNode:self.reverb];
            [self.audioEngine attachNode:self.playerNode];
            [self.audioEngine attachNode:self.playerNodeAux];
            [self.audioEngine attachNode:self.mixerNode];
            
            [self.audioEngine connect:self.playerNode     to:self.mixerNode  format:self.audioFormat];
            [self.audioEngine connect:self.playerNodeAux  to:self.mixerNode  format:self.audioFormat];
            [self.audioEngine connect:self.mixerNode      to:self.reverb     format:self.audioFormat];
            [self.audioEngine connect:self.reverb         to:self.mainNode   format:self.audioFormat];
            
            self.pcmBuffer     = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.audioFormat frameCapacity:self.audioFormat.sampleRate * 2.0 * self.audioFormat.channelCount];
            self.pcmBufferAux  = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.audioFormat frameCapacity:self.audioFormat.sampleRate * 2.0 * self.audioFormat.channelCount];
            
            if ([self startEngine])
            {
                if (![self.playerNode isPlaying]) [self.playerNode play];
                if (![self.playerNodeAux isPlaying]) [self.playerNodeAux play];
                
                //            struct AudioStreamBasicDescription {
                //                mSampleRate       = 44100.0;
                //                mFormatID         = kAudioFormatLinearPCM;
                //                mFormatFlags      = kAudioFormatFlagsAudioUnitCanonical;
                //                mBitsPerChannel   = 8 * sizeof (AudioUnitSampleType);                    // 32 bits
                //                mChannelsPerFrame = 2;
                //                mBytesPerFrame    = mChannelsPerFrame * sizeof (AudioUnitSampleType);    // 8 bytes
                //                mFramesPerPacket  = 1;
                //                mBytesPerPacket   = mFramesPerPacket * mBytesPerFrame;     // 8 bytes
                //                mReserved         = 0;
                //            };
                
                unsigned int seed    = (unsigned int)time(0);
                size_t buffer_size   = 256 * sizeof(char *);
                char * random_buffer = (char *)malloc(buffer_size);
                initstate(seed, random_buffer, buffer_size);
                srandomdev();
                
                chord_frequency_ratios = (struct ChordFrequencyRatio *)malloc(sizeof(struct ChordFrequencyRatio));
                
                typedef void (^PlayTones)(__weak typeof(AVAudioPlayerNode) *,
                                          __weak typeof(AVAudioPCMBuffer) *,
                                          __weak typeof(AVAudioFormat) *);
                
                static PlayTones play_tones;
                play_tones =
                ^ (__weak typeof(AVAudioPlayerNode) * player_node,
                   __weak typeof(AVAudioPCMBuffer) * pcm_buffer,
                   __weak typeof(AVAudioFormat) * audio_format) {
                    
                    struct AudioEngineStatus *audio_engine_status = malloc(sizeof(struct AudioEngineStatus));
                    audio_engine_status->status = AudioEngineStatusPlaying;
                    dispatch_set_context(self.audio_engine_status_dispatch_source, audio_engine_status);
                    dispatch_source_merge_data(self.audio_engine_status_dispatch_source, 1);
                    
                    const double sample_rate = [audio_format sampleRate];
                    
                    const AVAudioChannelCount channel_count = audio_format.channelCount;
                    const AVAudioFrameCount frame_count = sample_rate * 2.0;
                    pcm_buffer.frameLength = frame_count;
                    
                    dispatch_queue_t samplerQueue = dispatch_queue_create("com.blogspot.demonicactivity.samplerQueue", DISPATCH_QUEUE_SERIAL);
                    dispatch_block_t samplerBlock = dispatch_block_create(0, ^{
                        
                        ^ (AVAudioChannelCount channel_count, AVAudioFrameCount frame_count, double sample_rate, float * const _Nonnull * _Nullable float_channel_data) {
                            
                            for (int channel_index = 0; channel_index < 1; channel_index++)
                            {
                                double sin_phase = 0.0;
                                double sin_increment = (440.0 * (2.0 * M_PI)) / sample_rate;
                                double sin_increment_aux = (880.0 * (2.0 * M_PI)) / sample_rate;
                                
                                double divider = ^ long (long random, int n, int m) {
                                    long result = random % abs(MIN(m, n) - MAX(m, n)) + MIN(m, n);
                                    long scaled_result = (scale(0.0, 1.0, result, MIN(m, n), MAX(m, n))) - 0.5);
                                    result = 1.0 / (1.0 + pow(E_NUM, (-10.0 * scaled_result))); // normalize
                                    NSLog(@"mid_point ==  %f", mid_point);
                                    return result;
                                } (random(), 11025, 77175); // specifying duration range using indicies from a buffer of known element count: 11025 is approximately 0.25 seconds and 77175 is (probably) 1.75
                                if (float_channel_data[channel_index])
                                    for (int buffer_index = 0; buffer_index < frame_count; buffer_index++) {
                                        if (float_channel_data) float_channel_data[channel_index][buffer_index] = sinf(sin_phase);
                                        sin_phase += (buffer_index > 11025) ? sin_increment : sin_increment_aux;
                                        //                                            if (sin_phase >= (2.0 * M_PI)) sin_phase -= (2.0 * M_PI);
                                        //                                            if (sin_phase < 0.0) sin_phase += (2.0 * M_PI);
                                        
                                    }
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
                            // TO-DO: Add else block to change play button to stop (to accurately reflect whether a tone barrier is playing)
                            else {
                                struct AudioEngineStatus *audio_engine_status = malloc(sizeof(struct AudioEngineStatus));
                                audio_engine_status->status = AudioEngineStatusStopped;
                                dispatch_set_context(self.audio_engine_status_dispatch_source, audio_engine_status);
                                dispatch_source_merge_data(self.audio_engine_status_dispatch_source, 1);
                            }
                        } (^ {
                            play_tones(player_node, pcm_buffer, audio_format);
                        });
                    });
                    dispatch_block_notify(samplerBlock, dispatch_get_main_queue(), playToneBlock);
                    dispatch_async(samplerQueue, samplerBlock);
                };
                
                __weak typeof(AVAudioPlayerNode) * w_playerNode = self.playerNode;
                __weak typeof(AVAudioPCMBuffer) * w_pcmBuffer = self.pcmBuffer;
                __weak typeof(AVAudioFormat) * w_audioFormat = self.audioFormat;
                
                play_tones(w_playerNode, w_pcmBuffer, w_audioFormat);
            }
        });
        
        dispatch_resume(self.audio_engine_command_dispatch_source);
}

@end
