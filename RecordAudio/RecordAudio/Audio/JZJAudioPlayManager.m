//
//  JZJAudioPlayManager.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/16.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "JZJAudioPlayManager.h"
#import <AVFoundation/AVFoundation.h>

static JZJAudioPlayManager *instance = nil;

@interface JZJAudioPlayManager ()<AVAudioPlayerDelegate>
{
    NSString *_currCategory;
    BOOL _currActive;
}

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
    
    [self _setupAudioSessionCategory:AVAudioSessionCategoryPlayback isActive:YES];
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
    
    [self _setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

-(BOOL)isPlaying
{
    return _audioPlayer.isPlaying;
}

#pragma mark - private

-(JZJAudioPlayError)_setupAudioSessionCategory:(NSString *)sessionCategory
                                        isActive:(BOOL)isActive
{
    BOOL isNeedActive = NO;
    if (isActive != _currActive) {
        isNeedActive = YES;
        _currActive = isActive;
    }
    
    NSError *error = nil;
    JZJAudioPlayError returnError = JZJAudioPlayError_None;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 如果当前category等于要设置的，不需要再设置
    if (![_currCategory isEqualToString:sessionCategory]) {
        [audioSession setCategory:sessionCategory error:nil];
    }
    if (isNeedActive) {
        BOOL success = [audioSession setActive:isActive
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:&error];
        if(!success || error){
            returnError = JZJAudioPlayError_SetActive;
            return returnError;
        }
    }
    _currCategory = sessionCategory;
    
    return returnError;
}

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
    [self _setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
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
    [self _setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

@end
