//
//  AudioAlertViewController.h
//  AudioAlert
//
//  Created by J on 2/2/13.
//  Copyright (c) 2013 USC-AudioAlert2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioAlertViewController : UIViewController <AVAudioRecorderDelegate> {
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *recButton;
    IBOutlet UILabel *recStateLabel;
    
    BOOL isRecording;
    
    NSURL *temperoryRecFile;
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    
    
    IBOutlet UIButton *alertButton;
    
    UIAlertView *alertBox;
}

@property(nonatomic, retain) IBOutlet UIButton *playButton;
@property(nonatomic, retain) IBOutlet UIButton *recButton;

@property(nonatomic, retain) IBOutlet UIButton *alertButton;

-(IBAction)recording;
-(IBAction)playBack;

-(IBAction)alert;

@end
