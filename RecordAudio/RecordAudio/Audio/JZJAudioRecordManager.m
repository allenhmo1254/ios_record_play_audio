//
//  JZJAudioRecordManager.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/16.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "JZJAudioRecordManager.h"
#import <AVFoundation/AVFoundation.h>
#import "JZJTranscodingManager.h"
#import "JZJAudioSession.h"

#define RECORD_MIN_DURATION     1.0

static JZJAudioRecordManager *instance = nil;

@interface JZJAudioRecordManager ()<AVAudioRecorderDelegate>
{
    NSDate *_recorderStartDate;
    NSDate *_recorderEndDate;
    NSString *_recordPath;
}

@property(nonatomic, strong)AVAudioRecorder *audioRecorder;
@property(nonatomic, copy)NSDictionary *recoredSettings;
@property(nonatomic, copy)void(^recoredFinish)(NSString * recoredPath, JZJAudioRecordError error);
@property(nonatomic, strong)NSTimer *metesTimer;
@property(nonatomic, strong)JZJTranscodingManager *transcodingManager;

@end

@implementation JZJAudioRecordManager

+(instancetype)shareInstance
{
    @synchronized (instance) {
        if (!instance) {
            instance = [[JZJAudioRecordManager alloc] init];
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
    _transcodingManager = nil;
}

-(void)startRecordWithPath:(NSString *)path
{
    [self startRecordWithPath:path completion:nil];
}

-(void)startRecordWithPath:(NSString *)fileName
                completion:(void(^)(JZJAudioRecordError error))completion
{
    if (![self _checkMicrophoneAvailability]) {
        if (completion) {
            completion(JZJAudioRecordError_NoMicrophoneAuthority);
        }
        return;
    }
    
    //设置音频存储路径
    NSString *recordPath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),fileName];
    NSString *transcodingPath = [NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"],fileName];
    [self _checkDirectory:[recordPath stringByDeletingLastPathComponent]];
    [self _checkDirectory:[transcodingPath stringByDeletingLastPathComponent]];
    
    _recordPath = [[transcodingPath stringByDeletingPathExtension]
                         stringByAppendingPathExtension:@"mp3"];
    NSString *aacFilePath = [[recordPath stringByDeletingPathExtension]
                             stringByAppendingPathExtension:@"caf"];
    NSURL *aacUrl = [[NSURL alloc] initFileURLWithPath:aacFilePath];
    //设置智能录音的模式
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryRecord isActive:YES];
    //设置开始录音的时间戳
    _recorderStartDate = [NSDate date];
    //初始化AVAudioRecorder
    NSError *error = nil;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:aacUrl
                                                 settings:self.recoredSettings
                                                    error:&error];
    //开始音量检测
    _audioRecorder.meteringEnabled = YES;
    //设置代理
    _audioRecorder.delegate = self;
    
    if (!_audioRecorder || error) {
        _audioRecorder = nil;
        if (completion) {
            completion(JZJAudioRecordError_Init);
        }
        return;
    }
    BOOL success = [_audioRecorder record];
    if (success) {
        _metesTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_setVoiceImage) userInfo:nil repeats:YES];
        [_transcodingManager startConventToMp3:aacFilePath mp3:_recordPath];
        
        NSLog(@"录音开始成功");
        if (completion) {
            completion(JZJAudioRecordError_None);
        }
    } else {
        if (completion) {
            completion(JZJAudioRecordError_StartRecord);
        }
        NSLog(@"录音开始失败");
    }
}

-(void)stopRecord
{
    [self stopRecordWithCompletion:nil];
}

-(void)stopRecordWithCompletion:(void(^)(NSString *recoredPath, JZJAudioRecordError error))completion
{
    self.recoredFinish = completion;
    //如果audioRecorder对象为空或者没有在录音中
    if (!self.audioRecorder || !self.audioRecorder.isRecording)
    {
        if (self.recoredFinish) {
            self.recoredFinish(nil, JZJAudioRecordError_NoRecord);
        }
        return;
    }
    //设置结束录音的时间戳
    _recorderEndDate = [NSDate date];
    //停止刷新
    [_metesTimer invalidate];
    _metesTimer = nil;
    //检测录音时间，如果太短，不记录
    if ([_recorderEndDate timeIntervalSinceDate:_recorderStartDate] < RECORD_MIN_DURATION) {
        if (self.recoredFinish) {
            self.recoredFinish(nil, JZJAudioRecordError_RecordTimeTooShort);
            self.recoredFinish = nil;
        }
        
        // 如果录音时间较短，延迟1秒停止录音（iOS中，如果快速开始，停止录音，UI上会出现红条,为了防止用户又迅速按下，UI上需要也加一个延迟，长度大于此处的延迟时间，不允许用户循序重新录音。
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RECORD_MIN_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_audioRecorder stop];
        });
        return;
    } else {
        [_audioRecorder stop];
    }
}

-(void)cancelRecord
{
    [_metesTimer invalidate];
    _metesTimer = nil;
    _audioRecorder.delegate = nil;
    if (_audioRecorder.recording) {
        [_audioRecorder stop];
    }
    _audioRecorder = nil;
    _recoredFinish = nil;
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

- (NSDictionary *)recoredSettings
{
    if (!_recoredSettings) {
        _recoredSettings = @{AVFormatIDKey:@(kAudioFormatLinearPCM),
                             AVSampleRateKey:@(48000),
                             AVNumberOfChannelsKey:@(2),
                             AVEncoderBitDepthHintKey:@16,
                             AVEncoderAudioQualityKey:@(AVAudioQualityMedium)};
    }
    return _recoredSettings;
}

#pragma mark - private

-(void)_initData
{
    _transcodingManager = [[JZJTranscodingManager alloc] init];
}

-(void)_checkDirectory:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:path]){
        [fm createDirectoryAtPath:path
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
    }
}

-(void)_setVoiceImage
{
    if (_audioRecorder.isRecording) {
        [_audioRecorder updateMeters];
        double lowPassResults = pow(10, (0.05 * [_audioRecorder peakPowerForChannel:0]));
        if (_refreshVoiceBlock) {
            _refreshVoiceBlock(lowPassResults);
        }
    }
}

-(BOOL)_checkMicrophoneAvailability
{
    __block BOOL ret = NO;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if ([session respondsToSelector:@selector(requestRecordPermission:)]) {
        [session performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            ret = granted;
        }];
    } else {
        ret = YES;
    }
    
    return ret;
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                           successfully:(BOOL)flag
{
    NSString *recordPath = [[recorder url] path];
    recordPath = _recordPath;
    [_transcodingManager stop];
    if (self.recoredFinish) {
        if (!flag) {
            recordPath = nil;
        }
        self.recoredFinish(recordPath, JZJAudioRecordError_None);
    }
    self.audioRecorder = nil;
    self.recoredFinish = nil;
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryAmbient isActive:NO];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder
                                   error:(NSError *)error{
    NSLog(@"%@",error);
}

@end
