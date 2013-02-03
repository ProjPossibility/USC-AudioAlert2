//
//  AudioAlertViewController.m
//  AudioAlert
//
//  Created by J on 2/2/13.
//  Copyright (c) 2013 USC-AudioAlert2. All rights reserved.
//

#import "AudioAlertViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioAlertViewController ()

@end

@implementation AudioAlertViewController
@synthesize recButton, playButton;

- (void)viewDidLoad
{
    isRecording = NO;
    playButton.hidden = YES;
    recStateLabel.text = @"Not Recording";
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    //viewDidUnload
    NSFileManager *fileHandler = [NSFileManager defaultManager];
    [fileHandler removeItemAtPath:temperoryRecFile error:nil];
    recorder = nil;
    temperoryRecFile = nil;
    playButton.hidden = YES;
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recording {
    if (isRecording == NO) {
        isRecording = YES;
        [recButton setTitle:@"Stop" forState:UIControlStateNormal];
        playButton.hidden = YES;
        recStateLabel.text = @"Recording...";
        
        temperoryRecFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"soundFile"]];
        
        recorder = [[AVAudioRecorder alloc] initWithURL:temperoryRecFile settings:nil error:nil];
        
        [recorder setDelegate:self];
        [recorder prepareToRecord];
        [recorder record];
        
    } else {
        isRecording = NO;
        [recButton setTitle:@"REC" forState:UIControlStateNormal];
        playButton.hidden = NO;
        recStateLabel.text = @"Not Recording";
        
        [recorder stop];
        
    }
}
- (IBAction)playBack {
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:temperoryRecFile error:nil];
    
    player.volume = 1;
    
    [player play];
    
    while (player.playing == YES) {
        recStateLabel.text = @"Playing...";
        playButton.enabled = NO;
    }
    
    recStateLabel.text = @"Not Recording";
    playButton.enabled = YES;
}

-(IBAction)alert {
    
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    
    alertBox = [[UIAlertView alloc] initWithTitle:@"AlertBox" message:@"Alert Clicked" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [alertBox show];
}

@end
