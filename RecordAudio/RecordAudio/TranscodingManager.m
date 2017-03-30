//
//  TranscodingManager.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/30.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "TranscodingManager.h"
#import "lame.h"

@interface TranscodingManager ()

@property(nonatomic, assign)BOOL isTranscoding;

@end

@implementation TranscodingManager

- (void)startConventToMp3:(NSString *)pcmPath mp3:(NSString *)mp3Path
{
    if (!pcmPath || pcmPath.length <= 0) {
        return;
    }
    if (!mp3Path || mp3Path.length <= 0) {
        return;
    }
    self.isTranscoding = YES;
    
    @try {
        
        int read, write;
        
        FILE *pcm = fopen([pcmPath cStringUsingEncoding:NSASCIIStringEncoding], "rb");
        FILE *mp3 = fopen([mp3Path cStringUsingEncoding:NSASCIIStringEncoding], "wb");
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE * 2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 48000);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        long curpos;
        BOOL isSkipPCMHeader = NO;
        
        do {
            
            curpos = ftell(pcm);
            
            long startPos = ftell(pcm);
            
            fseek(pcm, 0, SEEK_END);
            long endPos = ftell(pcm);
            
            long length = endPos - startPos;
            
            fseek(pcm, curpos, SEEK_SET);
            
            if (length > PCM_SIZE * 2 * sizeof(short int)) {
                
                if (!isSkipPCMHeader) {
                    //Uump audio file header, If you do not skip file header
                    //you will heard some noise at the beginning!!!
                    fseek(pcm, 4 * 1024, SEEK_CUR);//删除头，否则在前一秒钟会有杂音
                    //fseek(pcm, 4 * 1024, SEEK_SET);
                    isSkipPCMHeader = YES;
                    NSLog(@"skip pcm file header !!!!!!!!!!");
                }
                
                read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                fwrite(mp3_buffer, write, 1, mp3);
                NSLog(@"read %d bytes", write);
            }
            else
            {
                [NSThread sleepForTimeInterval:0.05];
            }
            
        } while (self.isTranscoding);
        
        read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
        write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
        NSLog(@"read %d bytes and flush to mp3 file", write);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@", [exception description]);
    }
    @finally {
        NSLog(@"convert mp3 finish!!!");
    }
}

-(void)stop
{
    self.isTranscoding = NO;
}

@end
