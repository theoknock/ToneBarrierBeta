//
//  AudioRoutePicker.m
//  ToneBarrier
//
//  Created by Xcode Developer on 6/25/22.
//

#import "AudioRoutePicker.h"
@import Accelerate;

@interface AudioRoutePicker ()

@property (strong, nonatomic) AVAudioEngine     * audio_engine;
@property (strong, nonatomic) AVAudioFormat     * input_audio_format;
@property (strong, nonatomic) AVAudioSourceNode * audio_source_node;
@property (strong, nonatomic) AVAudioFormat     * output_audio_format;
@property (strong, nonatomic) AVAudioOutputNode * main_output_node;
@property (strong, nonatomic) AVAudioMixerNode  * main_mixer_node;
@property (strong, nonatomic) AVAudioSession    * audio_session;
@property (strong, nonatomic) AVAudioPlayerNode * audio_player_node;

@end

@implementation AudioRoutePicker

//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    
//    _audio_engine        = [[AVAudioEngine alloc] init];
//    _main_mixer_node     = _audio_engine.mainMixerNode;
//    _main_output_node    = _audio_engine.outputNode;
//    _output_audio_format = [_main_output_node inputFormatForBus:0];
//    _input_audio_format  = [[AVAudioFormat alloc] initWithCommonFormat:_output_audio_format.commonFormat
//                                                            sampleRate:_output_audio_format.sampleRate
//                                                              channels:_output_audio_format.channelCount
//                                                           interleaved:_output_audio_format.isInterleaved];
//    // audio source node
//    __block Float32 phase_increment = 1.f / _output_audio_format.sampleRate;
//    _audio_source_node   = [[AVAudioSourceNode alloc] initWithFormat:_input_audio_format renderBlock:
//                            ^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp,
//                                      AVAudioFrameCount frameCount,
//                                      AudioBufferList * _Nonnull outputData) {
//        
//        // signal sample array(s) stride and length
//        vDSP_Stride stride = (vDSP_Stride)1;
//        vDSP_Length length = (vDSP_Length)frameCount;
//        
//        // phase increment array
//        Float32 accumulative_phase = -phase_increment, phase_steps[length];
//        Float32 * phase_steps_t    = &phase_steps[0];
//        vDSP_vfill(^ Float32 * (Float32 phase_step) {
//            Float32 * phase_step_t = &phase_step;
//            return phase_step_t;
//        }((accumulative_phase += phase_increment)), phase_steps_t, stride, length);
//        
//        // amplitude array
//        Float32   angular_unit    = sinf(2 * M_PI), angular_units[length];
//        Float32 * angular_unit_t  = &angular_unit;
//        Float32 * angular_units_t = &angular_units[0];
//        vDSP_vfill(angular_unit_t, angular_units_t, stride, length);
//        
//        // frame indicies/frame_count/time arrays [0 through frameCount, frameCount[frameCount and 0 through 1]
//        Float32   frame_counter   = -1, frame_count[length], frame_indices[length], time[length];
//        Float32 * frame_count_t   = &frame_count[0];
//        Float32 * frame_indices_t = &frame_indices[0];
//        Float32 * time_t          = &time[0];
//        vDSP_vfill(^ Float32 * (Float32 frame_index) {
//            Float32 * frame_index_t = &frame_index;
//            return frame_index_t;
//        }(frame_counter++), frame_indices_t, stride, length);
//        vDSP_vfill(frame_count_t, (Float32 *)(&frameCount), stride, length);
//        vDSP_vdiv(frame_count_t, stride, frame_indices_t, stride, time, stride, length);
//        
//        // Calculate amplitude
//        Float32 amplitude_signal_sample[length];
//        Float32 * amplitude_signal_sample_t = &amplitude_signal_sample[0];
//        vDSP_vmul(angular_units_t, stride, time_t, stride, amplitude_signal_sample_t, stride, length);
//        
//        Float32 * output_data_t = (Float32 *)outputData->mBuffers[0].mData;
//        vDSP_vmul(frame_indices_t, stride, angular_units_t, stride, output_data_t, stride, length);
//        
//        printf("\n_audio_source_node\n");
//        
//        return (OSStatus)noErr;
//    }];
//    
//    _audio_player_node = [[AVAudioPlayerNode alloc] init];
//    
//    //    AVAudioFrameCount samplesWritten = 0, samplesToWrite
//    //    NSDictionary<NSString *, id> * audio_source_node_output_format_settings = [[_audio_source_node outputFormatForBus:0] settings];
//    //    [audio_source_node_output_format_settings setValue:@(false) forKey:AVLinearPCMIsNonInterleaved];
//    //
//    //
//    //        let samplesToWrite = AVAudioFrameCount(duration * sampleRate)
//    //        srcNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
//    //            // Check whether to adjust the buffer frame length to match
//    //            // the requested number of samples.
//    //            if samplesWritten + buffer.frameLength > samplesToWrite {
//    //                buffer.frameLength = samplesToWrite - samplesWritten
//    //            }
//    //            do {
//    //                try outFile?.write(from: buffer)
//    //            } catch {
//    //                print("Error writing file \(error)")
//    //            }
//    //            samplesWritten += buffer.frameLength
//    //
//    //            // Exit the app after writing the requested number of samples.
//    //            if samplesWritten >= samplesToWrite {
//    //                CFRunLoopStop(CFRunLoopGetMain())
//    //            }
//    //        }
//    //    }
//    
//    [_audio_engine attachNode:_audio_source_node];
//    [_audio_engine attachNode:_audio_player_node];
//    
//    [_audio_engine connect:_audio_source_node to:_main_mixer_node format:_input_audio_format];
//    [_audio_engine connect:_audio_player_node to:_main_mixer_node format:_output_audio_format];
//    [_audio_engine connect:_main_mixer_node to:_main_output_node format:_output_audio_format];
//    
//    
//    const AVAudioChannelCount channel_count = _output_audio_format.channelCount;
//    const AVAudioFrameCount frame_count     = _output_audio_format.sampleRate * channel_count;
//    
//    [_main_mixer_node installTapOnBus:0 bufferSize:frame_count format:[_main_mixer_node outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
//        __autoreleasing NSError * error = nil;
//        NSLog(@"%@\n", when);
//    }];
//}
//
//-(void)togglePlayWithAudioEngineRunningStatusCallback:(BOOL (^ _Nonnull (^)(typeof (^{ }) _Nullable))(BOOL, BOOL))audioEngineRunningStatus {
//    __autoreleasing NSError *error = nil;
//    audioEngineRunningStatus(nil)([_audio_engine startAndReturnError:&error] && [_audio_engine isRunning], [_audio_player_node isPlaying]);
//    (!error) ? [self configureAudioSession] : NSLog(@"\nstartAndReturnError error:\n\n%@\n\n", error.debugDescription);
//}
//
//- (NSError *)configureAudioSession {
//    __autoreleasing NSError *error = nil;
//    
//    _audio_session = [AVAudioSession sharedInstance];
//    [_audio_session setSupportsMultichannelContent:TRUE error:&error];
//    [_audio_session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault routeSharingPolicy:AVAudioSessionRouteSharingPolicyLongFormAudio
//                        options:AVAudioSessionCategoryOptionAllowAirPlay error:&error];
//    [_audio_session setPreferredOutputNumberOfChannels:2 error:&error];
//    [_audio_session setPreferredInputNumberOfChannels:2 error:&error];
//    [_audio_session setActive:YES error:&error];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioRouteChange:) name:AVAudioSessionRouteChangeNotification object:_audio_session];
//}
//
//- (void)handleRouteChange:(NSNotification *)notification
//{
//    UInt8 reasonValue = [[notification.userInfo valueForKey: AVAudioSessionRouteChangeNotification] intValue];
//    
//    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reasonValue || AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reasonValue) {
//        AVAudioSessionPortDescription * output = [(([_audio_session.currentRoute.outputs count]) ? _audio_session.currentRoute.outputs : nil) firstObjectCommonWithArray:_audio_session.currentRoute.inputs];
//        // To-Do: set output nodes' format per audio route
//        // AVAudioSessionPortHeadphones
//        // AVAudioSessionPortAirPlay
//        // AVAudioSessionPortBuiltInSpeaker
//        // AVAudioSessionPortHDMI
//    }
//}
//
//- (void)togglePlayFileWithAudioPlayerNodePlayingStatusCallback:(BOOL (^(^)(void))(BOOL, BOOL))audioPlayerNodePlayingStatus
//{
//    if (![self->_audioEngine isRunning])
//    {
//        __autoreleasing NSError *error = nil;
//        audioEngineRunningStatus(nil)([_audioEngine startAndReturnError:&error] && [_audioEngine isRunning], [_mixerOutputFilePlayer isPlaying]);
//        (!error) ? [self configureAudioSession] : NSLog(@"\nstartAndReturnError error:\n\n%@\n\n", error.debugDescription);
//        
//        const AVAudioChannelCount channel_count = _audioFormat.channelCount;
//        const AVAudioFrameCount frame_count     = _audioFormat.sampleRate * channel_count;
//        
//        _mixerOutputFileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"mixerOutput.caf"]];
//        _mixerOutputFile = [[AVAudioFile alloc] initForWriting:_mixerOutputFileURL settings:[[_mixerNode outputFormatForBus:0]  settings] error:&error];
//        NSAssert(_mixerOutputFile != nil, @"mixerOutputFile is nil, %@", [error localizedDescription]);
//        
//        [_mixerNode installTapOnBus:0 bufferSize:frame_count format:[_mixerNode outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
//            NSError *error;
//            NSLog(@"RECORDING: %@\n", when);
//            NSAssert([_mixerOutputFile writeFromBuffer:buffer error:&error], @"error writing buffer data to file, %@", [error localizedDescription]);
//        }];
//        
//        [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
//            AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();
//            ((*stop = [player_node isPlaying])) ?: ^{ [player_node prepareWithFrameCount:frame_count]; [player_node play]; }();
//        }];
//        
//        static unsigned int buffer_bit = 1;
//        [[ClicklessTones sharedClicklessTones] createAudioBufferWithFormat:_audioFormat completionBlock:^(AVAudioPCMBuffer * _Nonnull buffer1, AVAudioPCMBuffer * _Nonnull buffer2, PlayToneCompletionBlock playToneCompletionBlock) {
//            [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
//                AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();
//                (!player_node) ?: [player_node scheduleBuffer:(buffer_bit) ? buffer1 : buffer2 completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
//                    buffer_bit ^= 1;
//                    (buffer_bit) ?: playToneCompletionBlock();
//                }];
//            }];
//        }];
//        
//    } else {
//        audioEngineRunningStatus(^{
//            printf("Pausing audio engine...\n");
//            [self->_audioEngine pause];
//            [_playerNodes enumerateObjectsUsingBlock:^(id(^retained_object)(void), BOOL * _Nonnull stop) {
//                AVAudioPlayerNode * player_node = (AVAudioPlayerNode *)retained_object();
//                ((*stop = ![player_node isPlaying])) ?: ^{ [player_node pause]; [player_node reset]; }();
//            }];
//            [_mixerNode removeTapOnBus:0]; })([self.audioEngine isRunning], [_mixerOutputFilePlayer isPlaying]);
//    }
//}
//
//- (void)togglePlayFileWithAudioPlayerNodePlayingStatusCallback:(BOOL (^(^)(void))(BOOL, BOOL))audioPlayerNodePlayingStatus
//{
//    NSLog(@"%s\n", __PRETTY_FUNCTION__);
//    if (![_mixerOutputFilePlayer isPlaying]) {
//        if (_mixerOutputFileURL) {
//            NSError *error;
//            AVAudioFile *recordedFile = [[AVAudioFile alloc] initForReading:_mixerOutputFileURL error:&error];
//            NSAssert(recordedFile != nil, @"recordedFile is nil, %@", [error localizedDescription]);
//            [_mixerOutputFilePlayer scheduleFile:recordedFile atTime:nil completionHandler:^ (AVAudioPlayerNode * file_player) {
//                return ^{
//                    AVAudioTime *playerTime = [file_player playerTimeForNodeTime:file_player.lastRenderTime];
//                    NSLog(@"PLAYING: %@\n", playerTime);
//                    double delayInSecs = (recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate;
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [file_player stop];
//                    });
//                };
//            }(_mixerOutputFilePlayer)];
//            if ([_audioEngine startAndReturnError:&error]) [_mixerOutputFilePlayer play];
//        } else {
//            NSLog(@"\n\n%s\n\nERROR PLAYING RECORDING FILE\n\n", __PRETTY_FUNCTION__);
//        }
//    } else {
//        [self->_audioEngine pause];
//        [_mixerOutputFilePlayer pause];
//    }
//    
//    //        typedef BOOL  (^block)(void);
//    //        typedef block (^blk)(void);
//    //        typedef blk   (^b)(void);
//    //        typedef b     (^_)(b);
//    //
//    //
//    //
//    //
//    //    ^ BOOL {
//    //        ^ (BOOL(^startOutputFilePlayer)(typeof(^{}))) {
//    //            ((startOutputFilePlayer (^{ ([_mixerOutputFilePlayer isPlaying]) ?: [_mixerOutputFilePlayer play]; }))
//    //             (^ BOOL { return [_mixerOutputFilePlayer isPlaying]; }));
//    //            return TRUE;
//    //        };
//    //
//    //    };
//}
//
//- (void)stopPlayingRecordedFile
//{
//    [_mixerOutputFilePlayer stop];
//}


@end
