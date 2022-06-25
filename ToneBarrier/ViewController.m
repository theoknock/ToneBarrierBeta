//
//  ViewController.m
//  ToneBarrier
//
//  Created by Xcode Developer on 6/15/22.
//

#import "ViewController.h"
#import "ToneGenerator.h"
#import "AppDelegate.h"

@import QuartzCore;
@import CoreGraphics;

@interface ViewController ()
{
    CAShapeLayer *pathLayerChannelR;
    CAShapeLayer *pathLayerChannelL;
    BOOL _wasPlaying;
}

@property (weak, nonatomic) IBOutlet UIImageView *activationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reachabilityImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thermometerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryLevelImageView;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet AudioRoutePicker *audioRoutePicker;

@property (weak, nonatomic) IBOutlet UIImageView *heartRateImage;

@property (assign) id toneBarrierPlayingObserver;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceBatteryLevelDidChangeNotification object:self];
    [self addStatusObservers];
    
}

typedef NS_ENUM(NSUInteger, HeartRateMonitorStatus) {
    HeartRateMonitorPermissionDenied,
    HeartRateMonitorPermissionGranted,
    HeartRateMonitorDataUnavailable,
    HeartRateMonitorDataAvailable
    
};

- (void)updateHeartRateMonitorStatus:(HeartRateMonitorStatus)heartRateMonitorStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (heartRateMonitorStatus) {
            case HeartRateMonitorPermissionDenied:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.fill"]];
                [self.heartRateImage setTintColor:[UIColor darkGrayColor]];
                break;
            }
                
            case HeartRateMonitorPermissionGranted:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.fill"]];
                [self.heartRateImage setTintColor:[UIColor redColor]];
                break;
            }
                
            case HeartRateMonitorDataUnavailable:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.slash"]];
                [self.heartRateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            case HeartRateMonitorDataAvailable:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.fill"]];
                [self.heartRateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
                break;
        }
    });
}

//float scaleBetween(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
//    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
//}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)setupDeviceMonitoring
{
    self->_device = [UIDevice currentDevice];
    [self->_device setBatteryMonitoringEnabled:TRUE];
    [self->_device setProximityMonitoringEnabled:TRUE];
}

- (void)addStatusObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(togglePlayButton) name:@"ToneBarrierPlayingNotification" object:nil];
    
}


static NSProcessInfoThermalState(^thermalState)(void) = ^NSProcessInfoThermalState(void)
{
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    return thermalState;
};

static UIDeviceBatteryState(^batteryState)(UIDevice *) = ^UIDeviceBatteryState(UIDevice * device)
{
    UIDeviceBatteryState batteryState = [device batteryState];
    return batteryState;
};

static float(^batteryLevel)(UIDevice *) = ^float(UIDevice * device)
{
    float batteryLevel = [device batteryLevel];
    return batteryLevel;
};

static bool(^powerState)(void) = ^bool(void)
{
    return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
};

static bool(^audioRoute)(void) = ^bool(void)
{
    // NOT DONE
    return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
};

static NSDictionary<NSString *, id> * (^deviceStatus)(UIDevice *) = ^NSDictionary<NSString *, id> * (UIDevice * device)
{
    NSDictionary<NSString *, id> * status =
    @{@"NSProcessInfoThermalStateDidChangeNotification" : @(thermalState()),
      @"UIDeviceBatteryLevelDidChangeNotification"      : @(batteryLevel(device)),
      @"UIDeviceBatteryStateDidChangeNotification"      : @(batteryState(device)),
      @"NSProcessInfoPowerStateDidChangeNotification"   : @(powerState()),
      @"AVAudioSessionRouteChangeNotification"          : @(audioRoute()),
      @"ToneBarrierPlayingNotification"                 : @([ToneGenerator.sharedGenerator.audioEngine isRunning])};
    
    return status;
};

- (void)updateDeviceStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (thermalState()) {
            case NSProcessInfoThermalStateNominal:
            {
                [self.thermometerImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            case NSProcessInfoThermalStateFair:
            {
                [self.thermometerImageView setTintColor:[UIColor yellowColor]];
                break;
            }
                
            case NSProcessInfoThermalStateSerious:
            {
                [self.thermometerImageView setTintColor:[UIColor redColor]];
                break;
            }
                
            case NSProcessInfoThermalStateCritical:
            {
                [self.thermometerImageView setTintColor:[UIColor whiteColor]];
                break;
            }
                
            default:
            {
                [self.thermometerImageView setTintColor:[UIColor grayColor]];
            }
                break;
        }
        
        switch (batteryState(self->_device)) {
            case UIDeviceBatteryStateUnknown:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                [self.batteryImageView setTintColor:[UIColor grayColor]];
                break;
            }
                
            case UIDeviceBatteryStateUnplugged:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.slash.fill"]];
                [self.batteryImageView setTintColor:[UIColor redColor]];
                break;
            }
                
            case UIDeviceBatteryStateCharging:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt"]];
                [self.batteryImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            case UIDeviceBatteryStateFull:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.fill"]];
                [self.batteryImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                [self.batteryImageView setTintColor:[UIColor grayColor]];
                break;
            }
        }
        
        float level = batteryLevel(self->_device);
        if (level <= 1.0 || level > .66)
        {
            [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.100"]];
            [self.batteryLevelImageView setTintColor:[UIColor greenColor]];
        } else
            if (level <= .66 || level > .33)
            {
                [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.25"]];
                [self.batteryLevelImageView setTintColor:[UIColor yellowColor]];
            } else
                if (level <= .33)
                {
                    [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.0"]];
                    [self.batteryLevelImageView setTintColor:[UIColor redColor]];
                } else
                    if (level <= .125)
                    {
                        [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.0"]];
                        [self.batteryLevelImageView setTintColor:[UIColor redColor]];
                        //                        [ToneGenerator.sharedGenerator alarm];
                    }
    });
}

- (IBAction)toggleToneGenerator:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [ToneGenerator.sharedGenerator start];
        } else if ([ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [ToneGenerator.sharedGenerator stop];
        }
    });
    [self updateDeviceStatus];
}

- (void)togglePlayButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [self.playButton setImage:[UIImage systemImageNamed:@"stop"] forState:UIControlStateNormal];
        } else if (![ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [self.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
        }
    });
}

- (void)handleInterruption:(NSNotification *)notification
{
    _wasPlaying = ([ToneGenerator.sharedGenerator.audioEngine isRunning]) ? TRUE : FALSE;
    
    NSDictionary *userInfo = [notification userInfo];
    
    if ([ToneGenerator.sharedGenerator.audioEngine isRunning])
    {
        NSInteger typeValue = [[userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)typeValue;
        if (type)
        {
            if (type == AVAudioSessionInterruptionTypeBegan)
            {
                if (_wasPlaying)
                {
                    [ToneGenerator.sharedGenerator stop];
                    [self.playButton setImage:[UIImage systemImageNamed:@"pause"] forState:UIControlStateNormal];
                }
            } else if (type == AVAudioSessionInterruptionTypeEnded)
            {
//                NSInteger optionsValue = [[userInfo objectForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
//                AVAudioSessionInterruptionOptions options = (AVAudioSessionInterruptionOptions)optionsValue;
//                if (options == AVAudioSessionInterruptionOptionShouldResume)
//                {
                if (_wasPlaying)
                {
                    [ToneGenerator.sharedGenerator start];
                    [self.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
                }
//                }
            }
        }
    }
    
   
    [self updateDeviceStatus];
}

@end











