//
//  ViewController.m
//  ToneBarrier
//
//  Created by Xcode Developer on 6/15/22.
//

#import "ViewController.h"

@interface ViewController ()
{
    BOOL _wasPlaying;
}

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet AudioRoutePicker *audioRoutePicker;

@end

@implementation ViewController

- (void)handleAudioRouteChange
{
    NSLog(@"AVAudioSessionRouteChangeNotification");
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.playButton setImage:[UIImage systemImageNamed:@"stop"] forState:UIControlStateHighlighted];
    [self.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage systemImageNamed:@"pause"] forState:UIControlStateDisabled];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioRouteChange) name:AVAudioSessionRouteChangeNotification object:nil];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [sender setHighlighted:[ToneGenerator.sharedGenerator togglePlay]];
    });
};

@end











