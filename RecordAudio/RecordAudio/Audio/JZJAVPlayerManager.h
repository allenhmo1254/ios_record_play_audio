//
//  JZJAVPlayerManager.h
//  RecordAudio
//
//  Created by 景中杰 on 17/3/30.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JZJAVPlayerManagerBlock)(float p);

typedef enum {
    
    JZJAVPlayError_None,                         //无错误
    JZJAVPlayError_Init,                         //初始化出错
    JZJAVPlayError_Play,                         //播放出错
    JZJAVPlayError_PathNotExist,                 //路径不存在
    JZJAVPlayError_SetActive,                    //设置是否开启AudioSession出错
    
} JZJAVPlayError;

@interface JZJAVPlayerManager : NSObject

@property(nonatomic, copy)JZJAVPlayerManagerBlock block;

/**
 单利
 
 @return JZJAudioRecordManager单利对象
 */
+(instancetype)shareInstance;

-(void)loadWithURL:(NSURL *)url;

-(BOOL)play;

-(void)pause;

@end
