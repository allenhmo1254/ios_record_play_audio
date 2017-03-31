//
//  JZJAudioSession.h
//  RecordAudio
//
//  Created by 景中杰 on 17/3/31.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    JZJAudioSessionError_None,                       //无错误
    JZJAudioSessionError_SetActive,                  //设置是否开启AudioSession出错
    
} JZJAudioSessionError;

@interface JZJAudioSession : NSObject

/**
 单利
 
 @return JZJAudioRecordManager单利对象
 */
+(instancetype)shareInstance;

-(JZJAudioSessionError)setupAudioSessionCategory:(NSString *)sessionCategory
                                        isActive:(BOOL)isActive;

@end
