//
//  ViewController.m
//  SampleFireBase
//
//  Created by Ducere on 25/11/16.
//  Copyright © 2016 Ducere. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface ViewController ()<UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,MPMediaPickerControllerDelegate,AVAudioRecorderDelegate, AVAudioPlayerDelegate,AVAudioSessionDelegate>{
    
    MPMediaItem *song;
    NSURL *exportURL;
}
@property (nonatomic, retain) NSData *audioData;
@property(nonatomic , strong)MPMusicPlayerController *musicPlayer;
- (IBAction)btnAction:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Upload Audio";
    self.musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    self.audioData=nil;
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)btnAction:(id)sender {
    
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = YES; // this is the default
    mediaPicker.prompt = @"Select Your Favourite Song!";
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

#pragma mark Media picker delegate methods

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    // We need to dismiss the picker
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([mediaItemCollection count] < 1) {
        return;
    }
    song = [[mediaItemCollection items] objectAtIndex:0];
    [self handleExportTapped];
    
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    
    [self dismissViewControllerAnimated:YES completion:nil ];
}

-(void)handleExportTapped{
    
    // get the special URL
    if (! song) {
        return;
    }
    
    NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    NSLog (@"Core Audio %@ directly open library URL %@",
           coreAudioCanOpenURL (assetURL) ? @"can" : @"cannot",
           assetURL);
    
    NSLog (@"compatible presets for songAsset: %@",
           [AVAssetExportSession exportPresetsCompatibleWithAsset:songAsset]);
    
    
    /* approach 1: export just the song itself
     */
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                      initWithAsset: songAsset
                                      presetName: AVAssetExportPresetAppleM4A];
    NSLog (@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
    exporter.outputFileType = @"com.apple.m4a-audio";
    NSString *exportFile = [myDocumentsDirectory() stringByAppendingPathComponent: @"exported.m4a"];
    // end of approach 1
    
    myDeleteFile(exportFile);
    exportURL = [NSURL fileURLWithPath:exportFile];
    exporter.outputURL = exportURL;
    
    // do the export
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:
            {
                // log error to text view
                NSError *exportError = exporter.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                break;
            }
            case AVAssetExportSessionStatusCompleted:
            {
                NSLog (@"AVAssetExportSessionStatusCompleted");
                NSURL *audioUrl = exportURL;
                NSLog(@"Audio Url=%@",audioUrl);
                self.audioData = [NSData dataWithContentsOfURL:audioUrl];
                
                break;
            }
            case AVAssetExportSessionStatusUnknown:
            {
                NSLog (@"AVAssetExportSessionStatusUnknown");
                break;
            }
            case AVAssetExportSessionStatusExporting:
            {
                NSLog (@"AVAssetExportSessionStatusExporting");
                break;
            }
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog (@"AVAssetExportSessionStatusCancelled");
                break;
            }
            case AVAssetExportSessionStatusWaiting:
            {
                NSLog (@"AVAssetExportSessionStatusWaiting");
                break;
            }
            default:
            {
                NSLog (@"didn't get export status");
                break;
            }
        }
    }];
    
    
    
}


#pragma mark conveniences

NSString* myDocumentsDirectory()
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];;
}

void myDeleteFile (NSString* path)
{
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *deleteErr = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteErr];
        if (deleteErr) {
            NSLog (@"Can't delete %@: %@", path, deleteErr);
        }
    }
    
}

#pragma mark core audio test

BOOL coreAudioCanOpenURL (NSURL* url)
{
    
    OSStatus openErr = noErr;
    AudioFileID audioFile = NULL;
    openErr = AudioFileOpenURL((__bridge CFURLRef) url,
                               kAudioFileReadPermission ,
                               0,
                               &audioFile);
    if (audioFile) {
        AudioFileClose (audioFile);
    }
    return openErr ? NO : YES;
    
}
@end
