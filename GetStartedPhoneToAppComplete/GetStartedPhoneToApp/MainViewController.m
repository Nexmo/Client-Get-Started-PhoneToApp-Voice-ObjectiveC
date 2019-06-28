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


@interface MainViewController () <NXMClientDelegate, NXMCallDelegate>
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
    NSLog(@"💬 ongoingCall: %@", self.ongoingCall);
    if(!self.ongoingCall) {
        [self updateInterface];
    }
    [self.ongoingCall.myCallMember hangup];
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
    self.nexmoClient = [[NXMClient alloc] initWithToken:kInAppVoiceJaneToken];
    [self.nexmoClient setDelegate:self];
    [self.nexmoClient login];
}


#pragma mark NXMClientDelegate
- (void)connectionStatusChanged:(NXMConnectionStatus)status reason:(NXMConnectionStatusReason)reason {
    // handle change in status
    NSLog(@"💬 connectionStatusChanged - status: %ld | reason: %ld", (long)status, (long)reason);
    self.connectionStatus = status;
    [self updateInterface];
}

- (void)incomingCall:(nonnull NXMCall *)call {
    // handle an incoming call
    NSLog(@"💬 Incoming Call: %@", call);
    self.ongoingCall = call;
    [self displayIncomingCallAlert];
}


#pragma mark IncomingCall
- (void)displayIncomingCallAlert {
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayIncomingCallAlert];
        });
        return;
    }
    
    NSString *from = self.ongoingCall.otherCallMembers.firstObject.channel.from.data;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Incoming Call from %@", from ? from : @"Unknown"] message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
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
    __weak MainViewController *weakSelf = self;
    [weakSelf.ongoingCall answer:self completionHandler:^(NSError * _Nullable error) {
        if(error) {
            NSLog(@"💬 error answering call: %@", error.localizedDescription);
            [weakSelf displayAlertWithTitle:@"Answer Call" andMessage:@"Error answering call"];
            weakSelf.ongoingCall = nil;
            weakSelf.isInCall = NO;
            [self updateCallStatusLabelWithText:@""];
            [weakSelf updateInterface];
            return;
        }
        NSLog(@"💬 call answered");
        self.isInCall = YES;
        [weakSelf updateInterface];
    }];
}

- (void)didPressRejectIncomingCall {
    __weak MainViewController *weakSelf = self;
    [weakSelf.ongoingCall reject:^(NSError * _Nullable error) {
        if(error) {
            NSLog(@"💬 error rejecting call: %@", error.localizedDescription);
            [weakSelf displayAlertWithTitle:@"Reject Call" andMessage:@"Error rejecting call"];
            return;
        }
        NSLog(@"💬 call rejected");
        weakSelf.ongoingCall = nil;
        weakSelf.isInCall = NO;
        [self updateCallStatusLabelWithText:@""];
        [weakSelf updateInterface];
    }];
}


#pragma mark NXMCallDelegate
- (void)statusChanged:(NXMCallMember *)callMember {
    NSLog(@"💬 Call Status changed | participant: %@ | status: %ld", callMember.user.name, (long)callMember.status);
    [self updateCallStatusLabelWithStatus:callMember.status];
    
    //Handle Hangup
    if(callMember.status == NXMCallMemberStatusCancelled || callMember.status == NXMCallMemberStatusCompleted) {
        self.ongoingCall = nil;
        self.isInCall = NO;
        [self updateCallStatusLabelWithText:@"Call ended"];
        [self updateInterface];
    }
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
