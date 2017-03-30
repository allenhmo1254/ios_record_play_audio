//
//  JZJAudioRecordManager.h
//  RecordAudio
//
//  Created by 景中杰 on 17/3/16.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    JZJAudioRecordError_None,                       //无错误
    JZJAudioRecordError_Init,                       //初始化出错
    JZJAudioRecordError_StartRecord,                //开始录音出错
    JZJAudioRecordError_Recording,                  //在开始录音时，检测正在录音
    JZJAudioRecordError_NoRecord,                   //结束录音时，检测没有录音
    JZJAudioRecordError_FileNotExist,               //文件名不存在
    JZJAudioRecordError_RecordTimeTooShort,         //录制时间太短
    JZJAudioRecordError_SetActive,                  //设置是否开启AudioSession出错
    JZJAudioRecordError_NoMicrophoneAuthority,      //没有麦克风权限
    
} JZJAudioRecordError;

typedef void (^JZJAudioRecordRefreshVoiceBlock)(double voice);

@interface JZJAudioRecordManager : NSObject

/**
 录音音量刷新的block
 */
@property(nonatomic, copy)JZJAudioRecordRefreshVoiceBlock refreshVoiceBlock;

/**
 单利

 @return JZJAudioRecordManager单利对象
 */
+(instancetype)shareInstance;

/**
 开始录音

 @param fileName 音频存储文件名
 */
-(void)startRecordWithPath:(NSString *)fileName;

/**
 开始录音

 @param path 音频存储文件名
 @param completion 完成回调
 */
-(void)startRecordWithPath:(NSString *)fileName
                completion:(void(^)(JZJAudioRecordError error))completion;

/**
 结束录音
 */
-(void)stopRecord;

/**
 结束录音

 @param completion 完成回调
 */
-(void)stopRecordWithCompletion:(void(^)(NSString *recoredPath, JZJAudioRecordError error))completion;

/**
 取消录音
 */
-(void)cancelRecord;

@end
