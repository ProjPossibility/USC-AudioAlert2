//
//  RIOInterface.h
//  AudioAlert
//
//  Created by J on 2/3/13.
//  Copyright (c) 2013 USC-AudioAlert2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#include <stdlib.h>

@class AudioAlertViewController;

/**
 *	This is a singleton class that manages all the low level CoreAudio/RemoteIO
 *	elements. A singleton is used since we should never be instantiating more
 *  than one instance of this class per application lifecycle.
 */

#define kInputBus 1
#define kOutputBus 0
#define kBufferSize 1024
#define kBufferCount 1
#define N 10

@interface RIOInterface : NSObject {
	UIViewController *selectedViewController;
	__unsafe_unretained AudioAlertViewController *listener;
	
	AUGraph processingGraph;
	AudioUnit ioUnit;
	AudioBufferList* bufferList;
	AudioStreamBasicDescription streamFormat;
	
	FFTSetup fftSetup;
	COMPLEX_SPLIT A;
	int log2n, n, nOver2;
	
	void *dataBuffer;
	float *outputBuffer;
	size_t bufferCapacity;	// In samples
	size_t index;	// In samples
    
	float sampleRate;
	float frequency;
}

@property(nonatomic, assign) id<AVAudioPlayerDelegate> audioPlayerDelegate;
@property(nonatomic, assign) id<AVAudioSessionDelegate> audioSessionDelegate;
@property(nonatomic, assign) AudioAlertViewController *listener;

@property(assign) float sampleRate;
@property(assign) float frequency;


//Audio Session/Graph Setup
- (void)initializeAudioSession;
- (void)createAUProcessingGraph;
- (size_t)ASBDForSoundMode;

//Playback Controls
- (void)startPlayback;
- (void)startPlaybackFromEncodedArray:(NSArray *)encodedArray;
- (void)stopPlayback;
- (void)printASBD:(AudioStreamBasicDescription)asbd;

//Listener Controls
- (void)startListening:(AudioAlertViewController*)aListener;
- (void)stopListening;

//Generic Audio Controls
- (void)initializeAndStartProcessingGraph;
- (void)stopProcessingGraph;

//Singleton Methods
+ (RIOInterface *)sharedInstance;

@end
