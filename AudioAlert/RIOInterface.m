//
//  RIOInterface.m
//  AudioAlert
//
//  Created by J on 2/3/13.
//  Copyright (c) 2013 USC-AudioAlert2. All rights reserved.
//

#import "RIOInterface.h"
#import "AudioAlertViewController.h"

@implementation RIOInterface

@synthesize listener;
@synthesize audioPlayerDelegate;
@synthesize audioSessionDelegate;
@synthesize sampleRate;
@synthesize frequency;

int *binAverage = NULL;
int nextIndex;
float average;
int inRow;


float MagnitudeSquared(float x, float y);
void ConvertInt16ToFloat(RIOInterface* THIS, void *buf, float *outputBuf, size_t capacity);

//Audio Session/Graph Setup
- (void)initializeAudioSession {
    NSError	*err = nil;
	AVAudioSession *session = [AVAudioSession sharedInstance];
	
	[session setPreferredHardwareSampleRate:sampleRate error:&err];
	[session setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
	[session setActive:YES error:&err];
	
	// After activation, update our sample rate. We need to update because there
	// is a possibility the system cannot grant our request.
	sampleRate = [session currentHardwareSampleRate];
    
	[self realFFTSetup];
}

- (void)createAUProcessingGraph {
    OSStatus err;
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription ioUnitDescription;
	ioUnitDescription.componentType = kAudioUnitType_Output;
	ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	ioUnitDescription.componentFlags = 0;
	ioUnitDescription.componentFlagsMask = 0;
	
	// Declare and instantiate an audio processing graph
	NewAUGraph(&processingGraph);
	
	// Add an audio unit node to the graph, then instantiate the audio unit.
	/*
	 An AUNode is an opaque type that represents an audio unit in the context
	 of an audio processing graph. You receive a reference to the new audio unit
	 instance, in the ioUnit parameter, on output of the AUGraphNodeInfo
	 function call.
	 */
	AUNode ioNode;
	AUGraphAddNode(processingGraph, &ioUnitDescription, &ioNode);
	
	AUGraphOpen(processingGraph); // indirectly performs audio unit instantiation
	
	// Obtain a reference to the newly-instantiated I/O unit. Each Audio Unit
	// requires its own configuration.
	AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnit);
	
	// Initialize below.
	AURenderCallbackStruct callbackStruct = {0};
	UInt32 enableInput;
	UInt32 enableOutput;
	
	// Enable input and disable output.
	enableInput = 1; enableOutput = 0;
	callbackStruct.inputProc = RenderFFTCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	
	err = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO,
							   kAudioUnitScope_Input,
							   kInputBus, &enableInput, sizeof(enableInput));
	
	err = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO,
							   kAudioUnitScope_Output,
							   kOutputBus, &enableOutput, sizeof(enableOutput));
	
	err = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_SetInputCallback,
							   kAudioUnitScope_Input,
							   kOutputBus, &callbackStruct, sizeof(callbackStruct));
	
    
	// Set the stream format.
	size_t bytesPerSample = [self ASBDForSoundMode];
	
	err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Output,
							   kInputBus, &streamFormat, sizeof(streamFormat));
	
	err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   kOutputBus, &streamFormat, sizeof(streamFormat));
	
	
	
	
	// Disable system buffer allocation. We'll do it ourselves.
	UInt32 flag = 0;
	err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_ShouldAllocateBuffer,
                               kAudioUnitScope_Output,
                               kInputBus, &flag, sizeof(flag));
    
    
	// Allocate AudioBuffers for use when listening.
	// TODO: Move into initialization...should only be required once.
	bufferList = (AudioBufferList *)malloc(sizeof(AudioBuffer));
	bufferList->mNumberBuffers = 1;
	bufferList->mBuffers[0].mNumberChannels = 1;
	
	bufferList->mBuffers[0].mDataByteSize = kBufferSize*bytesPerSample;
	bufferList->mBuffers[0].mData = calloc(kBufferSize, bytesPerSample);
}
- (size_t)ASBDForSoundMode {
    AudioStreamBasicDescription asbd = {0};
	size_t bytesPerSample;
	bytesPerSample = sizeof(SInt16);
	asbd.mFormatID = kAudioFormatLinearPCM;
	asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	asbd.mBitsPerChannel = 8 * bytesPerSample;
	asbd.mFramesPerPacket = 1;
	asbd.mChannelsPerFrame = 1;
	asbd.mBytesPerPacket = bytesPerSample * asbd.mFramesPerPacket;
	asbd.mBytesPerFrame = bytesPerSample * asbd.mChannelsPerFrame;
	asbd.mSampleRate = sampleRate;
	
	streamFormat = asbd;
	[self printASBD:streamFormat];
	
	return bytesPerSample;
}


//Playback Controls
- (void)startPlayback {
    [self createAUProcessingGraph];
	[self initializeAndStartProcessingGraph];
	//AudioOutputUnitStart(ioUnit);
}
/*- (void)startPlaybackFromEncodedArray:(NSArray *)encodedArray {
  //unimplemented  
} */
- (void)stopPlayback {
    AUGraphStop(processingGraph);
	//AudioOutputUnitStop(ioUnit);

}
- (void)printASBD:(AudioStreamBasicDescription)asbd {
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
	
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lX",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10ld",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10ld",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10ld",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10ld",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10ld",    asbd.mBitsPerChannel);
}


//Listener Controls
- (void)startListening:(AudioAlertViewController*)aListener {
    
    self.listener = aListener;
	[self createAUProcessingGraph];
	[self initializeAndStartProcessingGraph];
}
- (void)stopListening {
    
//    for (int i = 0; i < 5; i++) {
//        binAverage[i] = 0;
//    }
//    nextIndex = 0;
    
    [self stopProcessingGraph];
}


//Generic Audio Controls
- (void)initializeAndStartProcessingGraph {
	OSStatus result = AUGraphInitialize(processingGraph);
	if (result >= 0) {
		AUGraphStart(processingGraph);
	} /*else {
		XThrow(result, "error initializing processing graph");
	}  */
}
- (void)stopProcessingGraph {
    AUGraphStop(processingGraph);
}


//Singleton Methods
static RIOInterface *sharedInstance = nil;
+ (RIOInterface *)sharedInstance {
    if (sharedInstance == nil) {
		sharedInstance = [[RIOInterface alloc] init];
	}
	
	return sharedInstance;
}


//Audio Rendering
OSStatus RenderFFTCallback (void					*inRefCon,
                            AudioUnitRenderActionFlags 	*ioActionFlags,
                            const AudioTimeStamp			*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList				*ioData)
{
//    if (binAverage == NULL) {
//        binAverage = malloc(sizeof(int) * 5);
//        for (int i = 0; i < 5; i++) {
//            binAverage[i] = 0;
//        }
//        nextIndex = 0;
//        average = 0.0;
//    }
    
	RIOInterface* THIS = (__bridge RIOInterface *)inRefCon;
	COMPLEX_SPLIT A = THIS->A;
	void *dataBuffer = THIS->dataBuffer;
	float *outputBuffer = THIS->outputBuffer;
	FFTSetup fftSetup = THIS->fftSetup;
	
	uint32_t log2n = THIS->log2n;
	uint32_t n = THIS->n;
	uint32_t nOver2 = THIS->nOver2;
	uint32_t stride = 1;
	int bufferCapacity = THIS->bufferCapacity;
	SInt16 index = THIS->index;
	
	AudioUnit rioUnit = THIS->ioUnit;
	OSStatus renderErr;
	UInt32 bus1 = 1;
	
	renderErr = AudioUnitRender(rioUnit, ioActionFlags,
								inTimeStamp, bus1, inNumberFrames, THIS->bufferList);
	if (renderErr < 0) {
		return renderErr;
	}
	
	// Fill the buffer with our sampled data. If we fill our buffer, run the
	// fft.
	int read = bufferCapacity - index;
	if (read > inNumberFrames) {
		memcpy((SInt16 *)dataBuffer + index, THIS->bufferList->mBuffers[0].mData, inNumberFrames*sizeof(SInt16));
		THIS->index += inNumberFrames;
	} else {
		// If we enter this conditional, our buffer will be filled and we should
		// perform the FFT.
		memcpy((SInt16 *)dataBuffer + index, THIS->bufferList->mBuffers[0].mData, read*sizeof(SInt16));
		
		// Reset the index.
		THIS->index = 0;
		
		/*************** FFT ***************/
		// We want to deal with only floating point values here.
		ConvertInt16ToFloat(THIS, dataBuffer, outputBuffer, bufferCapacity);
		
		/**
		 Look at the real signal as an interleaved complex vector by casting it.
		 Then call the transformation function vDSP_ctoz to get a split complex
		 vector, which for a real signal, divides into an even-odd configuration.
		 */
		vDSP_ctoz((COMPLEX*)outputBuffer, 2, &A, 1, nOver2);
		
		// Carry out a Forward FFT transform.
		vDSP_fft_zrip(fftSetup, &A, stride, log2n, FFT_FORWARD);
		
		// The output signal is now in a split real form. Use the vDSP_ztoc to get
		// a split real vector.
		vDSP_ztoc(&A, 1, (COMPLEX *)outputBuffer, 2, nOver2);
		
		// Determine the dominant frequency by taking the magnitude squared and
		// saving the bin which it resides in.
		float dominantFrequency = 0;
		int bin = -1;
		for (int i=0; i<n; i+=2) {
			float curFreq = MagnitudeSquared(outputBuffer[i], outputBuffer[i+1]);
			if (curFreq > dominantFrequency) {
				dominantFrequency = curFreq;
				bin = (i+1)/2;
                
//                binAverage[nextIndex] = bin;
//                nextIndex = (nextIndex + 1) % 5;
                
                
			}
		}
		memset(outputBuffer, 0, n*sizeof(SInt16));
		
		// Update the UI with our newly acquired frequency value.
		[THIS->listener frequencyChangedWithValue:bin*(THIS->sampleRate/bufferCapacity)];
		printf("Dominant frequency: %f   bin: %d \n", bin*(THIS->sampleRate/bufferCapacity), bin);
        
        if (bin > 60) {
            inRow++;
        } else {
            inRow = 0;
        }
        
        //Take Average
        
//        int sum = 0;
//
//        for (int i = 0; i < 5; i++) {
//            sum = binAverage[i] + sum;
//        }
        
//        average = sum/5;
        
        if (inRow == 15) {
            
            NSLog(@"ALERTALERT");
            
            inRow = 0;
            
            [THIS->listener performSelectorOnMainThread:@selector(alert) withObject:nil waitUntilDone:YES];
        }
        
	}
	
	
	return noErr;
}

//Functions defined above begin

float MagnitudeSquared(float x, float y) {
	return ((x*x) + (y*y));
}

void ConvertInt16ToFloat(RIOInterface* THIS, void *buf, float *outputBuf, size_t capacity) {
	AudioConverterRef converter;
	OSStatus err;
	
	size_t bytesPerSample = sizeof(float);
	AudioStreamBasicDescription outFormat = {0};
	outFormat.mFormatID = kAudioFormatLinearPCM;
	outFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
	outFormat.mBitsPerChannel = 8 * bytesPerSample;
	outFormat.mFramesPerPacket = 1;
	outFormat.mChannelsPerFrame = 1;
	outFormat.mBytesPerPacket = bytesPerSample * outFormat.mFramesPerPacket;
	outFormat.mBytesPerFrame = bytesPerSample * outFormat.mChannelsPerFrame;
	outFormat.mSampleRate = THIS->sampleRate;
	
	const AudioStreamBasicDescription inFormat = THIS->streamFormat;
	
	UInt32 inSize = capacity*sizeof(SInt16);
	UInt32 outSize = capacity*sizeof(float);
	err = AudioConverterNew(&inFormat, &outFormat, &converter);
	err = AudioConverterConvertBuffer(converter, inSize, buf, &outSize, outputBuf);
}

//Function defined above end


//Setup FFT
- (void)realFFTSetup {
	UInt32 maxFrames = 2048;
	dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
	outputBuffer = (float*)malloc(maxFrames *sizeof(float));
	log2n = log2f(maxFrames);
	n = 1 << log2n;
	assert(n == maxFrames);
	nOver2 = maxFrames/2;
	bufferCapacity = maxFrames;
	index = 0;
	A.realp = (float *)malloc(nOver2 * sizeof(float));
	A.imagp = (float *)malloc(nOver2 * sizeof(float));
	fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
}

@end
