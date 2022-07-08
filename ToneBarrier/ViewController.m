//
//  ViewController.m
//  ToneBarrier
//
//  Created by Xcode Developer on 6/15/22.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet AudioRoutePicker *audioRoutePicker;
@property (strong, nonatomic) MPNowPlayingInfoCenter * nowPlayingInfoCenter;
@property (strong, nonatomic) MPRemoteCommandCenter * remoteCommandCenter;

@end

@implementation ViewController

- (void)handleAudioRouteChange
{
    NSLog(@"AVAudioSessionRouteChangeNotification");
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.playButton setImage:[UIImage systemImageNamed:@"stop"] forState:UIControlStateSelected];
    [self.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage systemImageNamed:@"pause"] forState:UIControlStateDisabled];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioRouteChange) name:AVAudioSessionRouteChangeNotification object:nil];
    
    NSMutableDictionary<NSString *, id> * nowPlayingInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    [nowPlayingInfo setObject:@"ToneBarrier" forKey:MPMediaItemPropertyTitle];
    [nowPlayingInfo setObject:(NSString *)@"James Alan Bush" forKey:MPMediaItemPropertyArtist];
    [nowPlayingInfo setObject:(NSString *)@"The Life of a Demoniac" forKey:MPMediaItemPropertyAlbumTitle];
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(180.0, 180.0) requestHandler:^ UIImage * _Nonnull (CGSize size) {
        
        UIImage * image;
        [(image = [UIImage systemImageNamed:@"waveform.path"
                           withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:size.width weight:UIImageSymbolWeightLight] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor systemBlueColor]]]]) imageByPreparingForDisplay];
        return image;
    }];
   
    [nowPlayingInfo setObject:(MPMediaItemArtwork *)artwork forKey:MPMediaItemPropertyArtwork];
    
    [_nowPlayingInfoCenter = [MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:(NSDictionary<NSString *,id> * _Nullable)nowPlayingInfo];
    
    MPRemoteCommandHandlerStatus (^remote_command_handler)(MPRemoteCommandEvent * _Nonnull) = ^ MPRemoteCommandHandlerStatus (MPRemoteCommandEvent * _Nonnull event) {
        [self playButtonAction:self->_playButton];
        return MPRemoteCommandHandlerStatusSuccess;
    };
    
    [[_remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter] playCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter stopCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter pauseCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter togglePlayPauseCommand] addTargetWithHandler:remote_command_handler];
    
    [[UIApplication sharedApplication]  beginReceivingRemoteControlEvents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (IBAction)playButtonAction:(UIButton *)sender {
    [ToneGenerator.sharedGenerator togglePlayWithAudioEngineRunningStatusCallback:^ {
        return ^ (BOOL audioEngineRunning) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sender setSelected:audioEngineRunning];
                    [_nowPlayingInfoCenter setPlaybackState:(audioEngineRunning) ? MPNowPlayingPlaybackStatePlaying : MPNowPlayingPlaybackStatePaused];
                });
            };
    }];
}

@end











