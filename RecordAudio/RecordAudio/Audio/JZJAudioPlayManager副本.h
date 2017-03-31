//
//  JZJAudioPlayManager.h
//  RecordAudio
//
//  Created by 景中杰 on 17/3/16.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    JZJAudioPlayError_None,                         //无错误
    JZJAudioPlayError_Init,                         //初始化出错
    JZJAudioPlayError_Play,                         //播放出错
    JZJAudioPlayError_PathNotExist,                 //路径不存在
    JZJAudioPlayError_SetActive,                    //设置是否开启AudioSession出错
    
} JZJAudioPlayError;

@interface JZJAudioPlayManager : NSObject

/**
 单利
 
 @return JZJAudioRecordManager单利对象
 */
+(instancetype)shareInstance;

/**
 开始播放音频

 @param path 音频路径
 @param completon 完成回调
 */
-(void)playWithPath:(NSString *)path
         completion:(void(^)(JZJAudioPlayError error))completon;

/**
 停止播放音频
 */
-(void)stopPlay;

/**
 是否正在播放
 */
-(BOOL)isPlaying;

@end
