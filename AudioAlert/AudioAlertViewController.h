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

@class RIOInterface;

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
    
    
    IBOutlet UILabel *currentFrequencyLabel;
    IBOutlet UIButton *listenButton;
    
    BOOL isListening;
    __unsafe_unretained RIOInterface *rioRef;
	
	NSMutableString *key;
	float currentFrequency;
	NSString *prevChar;
    
    UIView *redAlertView;
}

@property(nonatomic, retain) IBOutlet UIButton *playButton;
@property(nonatomic, retain) IBOutlet UIButton *recButton;

@property(nonatomic, retain) IBOutlet UIButton *alertButton;


@property(nonatomic, retain) UILabel *currentFrequencyLabel;
@property(nonatomic, retain) UIButton *listenButton;
@property(nonatomic, retain) NSMutableString *key;
@property(nonatomic, retain) NSString *prevChar;
@property(nonatomic, assign) RIOInterface *rioRef;
@property(nonatomic, assign) float currentFrequency;
@property(assign) BOOL isListening;


-(IBAction)recording;
-(IBAction)playBack;

-(IBAction)alert;


- (IBAction)toggleListening:(id)sender;
- (void)startListener;
- (void)stopListener;

- (void)frequencyChangedWithValue:(float)newFrequency;
- (void)updateFrequencyLabel;

@end
