//
//  JZJAudioPlayManager.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/16.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "JZJAudioPlayManager.h"
#import <AVFoundation/AVFoundation.h>
#import "JZJAudioSession.h"

static JZJAudioPlayManager *instance = nil;

@interface JZJAudioPlayManager ()<AVAudioPlayerDelegate>

@property(nonatomic, strong)AVAudioPlayer *audioPlayer;
@property(nonatomic, copy)void(^playFinish)(JZJAudioPlayError error);

@end

@implementation JZJAudioPlayManager

+(instancetype)shareInstance
{
    @synchronized (instance) {
        if (!instance) {
            instance = [[JZJAudioPlayManager alloc] init];
        }
        return instance;
    }
}

-(void)playWithPath:(NSString *)path
         completion:(void(^)(JZJAudioPlayError error))completon
{
    if (_audioPlayer.isPlaying) {
        [self stopPlay];
    }
    
    NSFileManager * fm = [NSFileManager defaultManager];
    _playFinish = completon;
    NSError *error = nil;
    if (![fm fileExistsAtPath:path]) {
        error = [NSError errorWithDomain:@"file path not exist" code:0 userInfo:nil];
        if (_playFinish) {
            _playFinish(JZJAudioPlayError_PathNotExist);
            _playFinish = nil;
        }
        return;
    }
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error || !_audioPlayer) {
        error = [NSError errorWithDomain:NSLocalizedString(@"error.initPlayerFail", @"Failed to initialize AVAudioPlayer")
                                    code:0
                                userInfo:nil];
        if (_playFinish) {
            _playFinish(JZJAudioPlayError_Init);
            _playFinish = nil;
        }
        return;
    }
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryPlayback isActive:YES];
}

-(void)stopPlay
{
    if(_audioPlayer){
        _audioPlayer.delegate = nil;
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    if (_playFinish) {
        _playFinish = nil;
    }
    
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

-(BOOL)isPlaying
{
    return _audioPlayer.isPlaying;
}

#pragma mark - private

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag
{
    if (_playFinish) {
        _playFinish(JZJAudioPlayError_None);
    }
    if (_audioPlayer) {
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
    }
    _playFinish = nil;
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
                                 error:(NSError *)error
{
    if (_playFinish) {
        _playFinish(JZJAudioPlayError_Play);
    }
    if (_audioPlayer) {
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
    }
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

@end
