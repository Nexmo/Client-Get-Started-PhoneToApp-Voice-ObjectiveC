//
//  MainViewController.m
//  GetStartedPhoneToApp
//
//  Created by Paul Ardeleanu on 12/02/2019.
//  Copyright © 2019 Nexmo. All rights reserved.
//

#import "MainViewController.h"
#import <NexmoClient/NexmoClient.h>
#import "IAVAppDefine.h"


@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;

@property NXMConnectionStatus connectionStatus;
@property BOOL isInCall;

@property NXMClient *nexmoClient;
@property NXMCall *ongoingCall;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.connectionStatus = NXMConnectionStatusDisconnected;
    self.isInCall = NO;
    self.callStatusLabel.text = [@"Hello " stringByAppendingString: kInAppVoiceJaneName];
    [self.loadingIndicator startAnimating];
    [self updateInterface];
    [self setupNexmoClient];
}

- (void)updateInterface {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateInterface];
        });
        return;
    }
    switch (self.connectionStatus) {
        case NXMConnectionStatusDisconnected:
            self.endCallButton.alpha = 0;
            self.connectionStatusLabel.text = @"Connection Status: not connected";
            self.callStatusLabel.alpha = 0;
            [self.loadingIndicator stopAnimating];
            break;
        case NXMConnectionStatusConnecting:
            self.endCallButton.alpha = 0;
            self.connectionStatusLabel.text = @"Connection Status: connecting";
            self.callStatusLabel.alpha = 0;
            [self.loadingIndicator startAnimating];
            break;
        case NXMConnectionStatusConnected:
            self.endCallButton.alpha = 0;
            self.connectionStatusLabel.text = @"Connection Status: connected";
            self.callStatusLabel.alpha = 1;
            [self.loadingIndicator stopAnimating];
            break;
        default:
            break;
    }
    self.endCallButton.alpha = self.isInCall ? 1 : 0;
}

- (IBAction)endCall:(id)sender {
    
}


#pragma mark - Alerts
- (void)displayAlertWithTitle:(nonnull NSString *)title andMessage:(nonnull NSString *)message {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayAlertWithTitle:title andMessage:message];
        });
        return;
    }
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Tutorial Methods
#pragma mark Setup
- (void)setupNexmoClient {
    
}


#pragma mark NXMClientDelegate




#pragma mark IncomingCall
- (void)displayIncomingCallAlert {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayIncomingCallAlert];
        });
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Incoming Call" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    __weak MainViewController *weakSelf = self;
    UIAlertAction* answerAction = [UIAlertAction actionWithTitle:@"Answer" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didPressAnswerIncomingCall];
    }];
    
    UIAlertAction* rejectAction = [UIAlertAction actionWithTitle:@"Reject" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf didPressRejectIncomingCall];
    }];
    
    [alertController addAction:answerAction];
    [alertController addAction:rejectAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didPressAnswerIncomingCall {
    
}

- (void)didPressRejectIncomingCall {
    
}


#pragma mark NXMCallDelegate
- (void)statusChanged:(NXMCallMember *)callMember {
    
}

- (void)updateCallStatusLabelWithText:(NSString *)text {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateCallStatusLabelWithText:text];
        });
        return;
    }
    self.callStatusLabel.text = text;
}

- (void)updateCallStatusLabelWithStatus:(NXMCallMemberStatus)status {
    
    NSString *callStatusText = @"";
    switch (status) {
        case NXMCallMemberStatusCancelled:
            callStatusText = @"Call Cancelled";
            break;
        case NXMCallMemberStatusCompleted:
            callStatusText = @"Call Completed";
            break;
        case NXMCallMemberStatusDialling:
            callStatusText = @"Dialing";
            break;
        case NXMCallMemberStatusCalling:
            callStatusText = @"Calling";
            break;
        case NXMCallMemberStatusStarted:
            callStatusText = @"Call Started";
            break;
        case NXMCallMemberStatusAnswered:
            callStatusText = @"Answered";
            break;
        default:
            break;
    }
    
    [self updateCallStatusLabelWithText:callStatusText];
}


@end
