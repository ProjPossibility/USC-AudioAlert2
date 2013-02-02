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

@interface AudioAlertViewController : UIViewController <AVAudioRecorderDelegate> {
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *recButton;
    IBOutlet UILabel *recStateLabel;
    
    BOOL isRecording;
    BOOL isPlaying;
    
    NSURL *temperoryRecFile;
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
}

@property(nonatomic, retain) IBOutlet UIButton *playButton;
@property(nonatomic, retain) IBOutlet UIButton *recButton;

-(IBAction)recording;
-(IBAction)playBack;

@end
