//
//  AppDelegate.h
//  ToneBarrier
//
//  Created by Xcode Developer on 6/15/22.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol DeviceStatusInterfaceDelegate <NSObject>

- (void)updateDeviceStatus;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) id<DeviceStatusInterfaceDelegate> deviceStatusInterfaceDelegate;

@end

