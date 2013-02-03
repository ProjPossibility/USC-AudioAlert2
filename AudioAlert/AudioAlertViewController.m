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

#import "RIOInterface.h"

@interface AudioAlertViewController ()

@end

@implementation AudioAlertViewController
@synthesize recButton, playButton, alertButton;


@synthesize currentFrequencyLabel;
@synthesize listenButton;
@synthesize key;
@synthesize prevChar;
@synthesize isListening;
@synthesize	rioRef;
@synthesize currentFrequency;

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
    
    rioRef = [RIOInterface sharedInstance];
    
    redAlertView = [UIView new];
    redAlertView.frame = CGRectMake(0, 0, 320, 480);
    redAlertView.backgroundColor = [UIColor redColor];
    redAlertView.hidden = YES;
    
    [self.view addSubview:redAlertView];
    
    [self toggleListening:nil];
    
}

- (void)didReceiveMemoryWarning
{
    //viewDidUnload
    NSFileManager *fileHandler = [NSFileManager defaultManager];
    [fileHandler removeItemAtPath:temperoryRecFile error:nil];
    recorder = nil;
    temperoryRecFile = nil;
    playButton.hidden = YES;
    
    
	currentFrequencyLabel = nil;
    listenButton = nil;
    
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
    
    //[self stopListener];
//    isListening = NO;
//    [listenButton setTitle:@"Stop Listening" forState:UIControlStateNormal];
//    
//    alertBox = [[UIAlertView alloc] initWithTitle:@"AlertBox" message:@"Alert Clicked" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    
//    [alertBox show];
    
    
    redAlertView.hidden = NO;
    
    [self performSelector:@selector(redAlertTrigger) withObject:nil afterDelay:1];
    
}

- (IBAction)redAlertTrigger {
    redAlertView.hidden = YES;
}

- (IBAction)toggleListening:(id)sender {
    if (isListening) {
		[self stopListener];
		[listenButton setTitle:@"Begin Listening" forState:UIControlStateNormal];
	} else {
		[self startListener];
		[listenButton setTitle:@"Stop Listening" forState:UIControlStateNormal];
	}
	
	isListening = !isListening;
}
- (void)startListener {
    [rioRef startListening:self];
}
- (void)stopListener {
    [rioRef stopListening];
}

- (void)frequencyChangedWithValue:(float)newFrequency {
//    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	self.currentFrequency = newFrequency;
	[self performSelectorInBackground:@selector(updateFrequencyLabel) withObject:nil];
    
//    [pool drain];
//	pool = nil;
}
- (void)updateFrequencyLabel {
//    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%f", self.currentFrequency];
	[self.currentFrequencyLabel setNeedsDisplay];
//	[pool drain];
//	pool = nil;
}


@end
