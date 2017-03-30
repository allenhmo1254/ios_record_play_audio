//
//  TranscodingManager.h
//  RecordAudio
//
//  Created by 景中杰 on 17/3/30.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TranscodingManager : NSObject

@property(nonatomic, assign, readonly)BOOL isTranscoding;

-(void)startConventToMp3:(NSString *)pcmPath mp3:(NSString *)mp3Path;

-(void)stop;

@end
