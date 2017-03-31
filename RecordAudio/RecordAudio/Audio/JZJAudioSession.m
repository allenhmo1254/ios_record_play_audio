//
//  JZJAudioSession.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/31.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "JZJAudioSession.h"
#import <AVFoundation/AVFoundation.h>

static JZJAudioSession *instance = nil;

@interface JZJAudioSession ()
{
    NSString *_currCategory;
    BOOL _currActive;
}

@end

@implementation JZJAudioSession

+(instancetype)shareInstance
{
    @synchronized (instance) {
        if (!instance) {
            instance = [[JZJAudioSession alloc] init];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(JZJAudioSessionError)setupAudioSessionCategory:(NSString *)sessionCategory
                                       isActive:(BOOL)isActive
{
    BOOL isNeedActive = NO;
    if (isActive != _currActive) {
        isNeedActive = YES;
        _currActive = isActive;
    }
    
    NSError *error = nil;
    JZJAudioSessionError returnError = JZJAudioSessionError_None;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 如果当前category等于要设置的，不需要再设置
    if (![_currCategory isEqualToString:sessionCategory]) {
        [audioSession setCategory:sessionCategory error:nil];
    }
    if (![self _isHeadsetPluggedIn]) {//没有插入耳机时，设置为使用扬声器输出
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
    if (isNeedActive) {
        BOOL success = [audioSession setActive:isActive
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:&error];
        if(!success || error){
            returnError = JZJAudioSessionError_SetActive;
            return returnError;
        }
    }
    _currCategory = sessionCategory;
    
    return returnError;
}

#pragma mark - private

-(void)_initData
{
    
}

- (BOOL)_isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

@end
