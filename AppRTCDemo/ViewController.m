//
//  ViewController.m
//  AppRTCDemo
//
//  Created by Phuong Le on 1/28/15.
//  Copyright (c) 2015 Phuong Le. All rights reserved.
//

#import "ViewController.h"
#import "UIViewAdditional.h"
#import "ARDAppClient.h"
#import "UIImage+ARDUtilities.h"
#import "RTCEAGLVideoView.h"
#import "ARDVideoCallView.h"

@interface ViewController () <UITextFieldDelegate, ARDAppClientDelegate, ARDVideoCallViewDelegate>
{
    ARDAppClient *_webRTCClient;
    
    ARDVideoCallView *_videoCallView;
    RTCVideoTrack *_remoteVideoTrack;
    RTCVideoTrack *_localVideoTrack;
}

@property (weak, nonatomic) IBOutlet UITextField *roomTextField;

@property (weak, nonatomic) IBOutlet UIView *webRTCContainerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    _videoCallView = [[ARDVideoCallView alloc] initWithFrame:RECT(0, _roomTextField.bottom, self.view.width, self.view.height-_roomTextField.height)];
    _videoCallView.delegate = self;
    _videoCallView.statusLabel.text = [self statusTextForState:RTCICEConnectionClosed];
    [_webRTCContainerView addSubview:_videoCallView];
    _videoCallView.frame = _webRTCContainerView.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self connectWebRTC:textField.text];
    
    [textField resignFirstResponder];
    
    return YES;
}

- (void)connectWebRTC:(NSString *)room {
    if (room.length == 0) {
        return;
    }
    
    NSLog(@"Join to webrtc room: %@", room);
    
    _videoCallView.statusLabel.text = [self statusTextForState:RTCICEConnectionNew];
    
    _webRTCClient = [[ARDAppClient alloc] initWithDelegate:self];
    [_webRTCClient connectToRoomWithId:room options:nil];
}

- (void)hangup {
    if (_remoteVideoTrack) {
        [_remoteVideoTrack removeRenderer:_videoCallView.remoteVideoView];
        _remoteVideoTrack = nil;
        
        [_videoCallView.remoteVideoView renderFrame:nil];
    }
    
    if (_localVideoTrack) {
        [_localVideoTrack removeRenderer:_videoCallView.localVideoView];
        _localVideoTrack = nil;
        
        [_videoCallView.localVideoView renderFrame:nil];
    }
    
    [_webRTCClient disconnect];
}

- (NSString *)statusTextForState:(RTCICEConnectionState)state {
    switch (state) {
        case RTCICEConnectionNew:
        case RTCICEConnectionChecking:
            return @"Connecting...";
        case RTCICEConnectionConnected:
        case RTCICEConnectionCompleted:
        case RTCICEConnectionFailed:
        case RTCICEConnectionDisconnected:
        case RTCICEConnectionClosed:
            return nil;
    }
}

#pragma mark - ARDVideoCallViewDelegate

- (void)videoCallViewDidHangup:(ARDVideoCallView *)view {
    [self hangup];
}

#pragma mark - ARDAppClientDelegate
- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
            
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
            
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self hangup];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didChangeConnectionState:(RTCICEConnectionState)state {
    NSLog(@"ICE state changed: %d", state);
    
    //    __weak ARDVideoCallViewController *weakSelf = self;
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        ARDVideoCallViewController *strongSelf = weakSelf;
    //        strongSelf.videoCallView.statusLabel.text =
    //        [strongSelf statusTextForState:state];
    //    });
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    if (!_localVideoTrack) {
        _localVideoTrack = localVideoTrack;
        
        [_localVideoTrack addRenderer:_videoCallView.localVideoView];
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    if (!_remoteVideoTrack) {
        _remoteVideoTrack = remoteVideoTrack;
        
        [_remoteVideoTrack addRenderer:_videoCallView.remoteVideoView];
        _videoCallView.statusLabel.hidden = YES;
    }
}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
    
    [self hangup];
}
@end
