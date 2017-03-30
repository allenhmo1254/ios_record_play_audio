//
//  JZJAVPlayerManager.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/30.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "JZJAVPlayerManager.h"
#import <AVFoundation/AVFoundation.h>

static JZJAVPlayerManager *instance = nil;

@interface JZJAVPlayerManager ()
{
    id timeObserve;// 为 当前AVPlayerItem 添加观察者获取各种播放状态
    NSString *_currCategory;
    BOOL _currActive;
}

@property(nonatomic, strong)AVPlayer *player;
@property(nonatomic, strong)AVPlayerItem *currentPlayerItem;

@end

@implementation JZJAVPlayerManager

+(instancetype)shareInstance
{
    @synchronized (instance) {
        if (!instance) {
            instance = [[JZJAVPlayerManager alloc] init];
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
    _player = nil;
}

-(void)loadWithURL:(NSURL *)url
{
    //创建要播放的资源
    //self.currentPlayerItem = [[AVPlayerItem alloc] initWithURL:url];
    self.currentPlayerItem = [AVPlayerItem playerItemWithURL:url];
    //更换item
    [self.player replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
    //添加监听
    [self _addObservers];
}

-(BOOL)play
{
    if (!self.player.currentItem) {
        return NO;
    }
    
    [self.player play];
    
    [self _setupAudioSessionCategory:AVAudioSessionCategoryPlayback isActive:YES];
    
    return YES;
}

-(void)pause
{
    [self.player pause];
}

#pragma mark - private

-(void)_initData
{
    _player = [[AVPlayer alloc] init];
}

-(void)_addObservers
{
    //观察该item 是否能播放
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //观察该item 加载进度
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //AVPlayer 自带方法：返回歌曲 播放进度 信息
    __weak AVPlayer *weakPlayer = self.player;
    timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(weakPlayer.currentItem.duration);
        NSLog(@"current = %f, total = %f",current, total);
    }];
}

-(void)_removeObservers
{
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player removeTimeObserver:timeObserve];
}

-(JZJAVPlayError)_setupAudioSessionCategory:(NSString *)sessionCategory
                                   isActive:(BOOL)isActive
{
    BOOL isNeedActive = NO;
    if (isActive != _currActive) {
        isNeedActive = YES;
        _currActive = isActive;
    }
    
    NSError *error = nil;
    JZJAVPlayError returnError = JZJAVPlayError_None;
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
            returnError = JZJAVPlayError_SetActive;
            return returnError;
        }
    }
    _currCategory = sessionCategory;
    
    return returnError;
}

#pragma mark - kvo

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem * songItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        switch (songItem.status) {
            case AVPlayerStatusUnknown:
                //  BASE_INFO_FUN(@"KVO：未知状态，此时不能播放");
                break;
            case AVPlayerStatusReadyToPlay:
                //  BASE_INFO_FUN(@"KVO：准备完毕，可以播放");
                [self play];
                break;
            case AVPlayerStatusFailed:
                //  BASE_INFO_FUN(@"KVO：加载失败，网络或者服务器出现问题");
                break;
            default:
                break;
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSArray * array = songItem.loadedTimeRanges;
        float total = CMTimeGetSeconds(songItem.duration);
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲的时间范围
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration); //缓冲总长度
        NSLog(@"totalBuffer = %.2f, total = %.2f",totalBuffer,total);
    }
}

@end
