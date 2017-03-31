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
#import "AudioPlayer.h"

static JZJAudioPlayManager *instance = nil;

@interface JZJAudioPlayManager ()<AudioPlayerDelegate>

@property(nonatomic, strong)AudioPlayer *audioPlayer;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _initData];
    }
    return self;
}

- (void)dealloc
{
    _audioPlayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)playWithPath:(NSString *)path
         completion:(void(^)(JZJAudioPlayError error))completon
{
    if (_audioPlayer.state == AudioPlayerStatePlaying) {
        [self stop];
    }
    
    _playFinish = completon;
    
    NSURL *url = [NSURL URLWithString:path];
    [self.audioPlayer play:url];
    
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryPlayback isActive:YES];
}

-(void)stop
{
    if(_audioPlayer)
        [_audioPlayer stop];
    
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

-(BOOL)isPlaying
{
    return _audioPlayer.state == AudioPlayerStatePlaying;
}

-(void)pause
{
    if (_audioPlayer.state != AudioPlayerStatePlaying) {
        return;
    }
    
    [_audioPlayer pause];
}

-(void)resume
{
    if (_audioPlayer.state != AudioPlayerStatePaused) {
        return;
    }
    
    [_audioPlayer resume];
}

#pragma mark - private

-(void)_initData
{
    _audioPlayer = [[AudioPlayer alloc] init];
    _audioPlayer.delegate = self;
    [self _addObservers];
}

-(void)_addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

#pragma mark - NSNotification

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable://一种新设备可用（如耳机已插上）
        {
            
        }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://旧设备变得不可用（例如耳机已拔出）
        {
            [self resume];
        }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange://音频类型发生了变化（如avaudiosessioncategoryplayback已改为avaudiosessioncategoryplayandrecord）
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
        case AVAudioSessionRouteChangeReasonOverride://这条路线已被重写（例如类是avaudiosessioncategoryplayandrecord和输出已经改变了从接收器，这是默认的扬声器）。
        {
            
        }
            break;
    }
}

#pragma mark - AudioPlayerDelegate

-(void)audioPlayer:(AudioPlayer*)audioPlayer stateChanged:(AudioPlayerState)state
{
    NSLog(@"状态变化 = %d",state);
}

-(void)audioPlayer:(AudioPlayer*)audioPlayer didEncounterError:(AudioPlayerErrorCode)errorCode
{
    NSLog(@"播放出错 = %d",errorCode);
    if (_playFinish) {
        _playFinish(JZJAudioPlayError_Play);
        _playFinish = nil;
    }
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

-(void)audioPlayer:(AudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"开始播放音频 = %@",queueItemId);
}

-(void)audioPlayer:(AudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"缓冲完成 = %@",queueItemId);
}

-(void)audioPlayer:(AudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(AudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    NSLog(@"停止播放音频 = %@",queueItemId);
    if (_playFinish) {
        _playFinish(JZJAudioPlayError_None);
        _playFinish = nil;
    }
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

//-(void)audioPlayer:(AudioPlayer*)audioPlayer logInfo:(NSString*)line
//{
//    NSLog(@"音频信息 = %@",line);
//}
//
//-(void)audioPlayer:(AudioPlayer*)audioPlayer internalStateChanged:(AudioPlayerInternalState)state
//{
//    NSLog(@"内部状态变化 = %d",state);
//}
//
//-(void)audioPlayer:(AudioPlayer*)audioPlayer didCancelQueuedItems:(NSArray*)queuedItems
//{
//    NSLog(@"清空队列 = %@",queuedItems);
//}

@end
