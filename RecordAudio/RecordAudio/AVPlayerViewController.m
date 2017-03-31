//
//  AVPlayerViewController.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/30.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "AVPlayerViewController.h"
#import "JZJAudioPlayManager.h"
#import "JZJAudioSession.h"
#import <AVFoundation/AVFoundation.h>

@interface AVPlayerViewController ()

@property(nonatomic, strong)UILabel *label;

@end

@implementation AVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat width = 100, height = 40;
    
    UIButton *localButton = [UIButton buttonWithType:UIButtonTypeCustom];
    localButton.frame = CGRectMake(self.view.frame.size.width / 2 - width - 50, 100, width, height);
    [localButton setTitle:@"本地" forState:UIControlStateNormal];
    [localButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [localButton addTarget:self action:@selector(localButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:localButton];
    
    UIButton *httpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    httpButton.frame = CGRectMake(self.view.frame.size.width / 2 + 50, 100, width, height);
    [httpButton setTitle:@"网络" forState:UIControlStateNormal];
    [httpButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [httpButton addTarget:self action:@selector(httpButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:httpButton];
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(self.view.frame.size.width / 2 - width / 2, 170, width, height);
    [playButton setTitle:@"play" forState:UIControlStateNormal];
    [playButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    pauseButton.frame = CGRectMake(self.view.frame.size.width / 2 - width / 2, 250, width, height);
    [pauseButton setTitle:@"pause" forState:UIControlStateNormal];
    [pauseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pauseButton];
    
    UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    stopButton.frame = CGRectMake(self.view.frame.size.width / 2 - width / 2, 320, width, height);
    [stopButton setTitle:@"stop" forState:UIControlStateNormal];
    [stopButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [stopButton addTarget:self action:@selector(stopButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopButton];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - width / 2, 350, width, height)];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:label];
    self.label = label;
}

-(void)localButtonClick
{
    NSString *file = [[NSBundle mainBundle] pathForResource:@"test.mp3" ofType:nil];
    [[JZJAudioPlayManager shareInstance] playWithPath:file completion:nil];
    [[JZJAudioSession shareInstance] setupAudioSessionCategory:AVAudioSessionCategoryPlayback isActive:YES];
}

-(void)httpButtonClick
{
    NSString *urlString = @"https://nj01ct01.baidupcs.com/file/67e08e7b3db5bd550eb2c3077bc9341d?bkt=p3-140067e08e7b3db5bd550eb2c3077bc9341da3ab7671000000286647&fid=2670780510-250528-430066337834612&time=1490925577&sign=FDTAXGERLBHS-DCb740ccc5511e5e8fedcff06b081203-ynnDfmURQoHm1ksi04t87Q6BnmE%3D&to=63&size=2647623&sta_dx=2647623&sta_cs=3&sta_ft=mp3&sta_ct=0&sta_mt=0&fm2=MH,Yangquan,Netizen-anywhere,,beijingct&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=140067e08e7b3db5bd550eb2c3077bc9341da3ab7671000000286647&sl=75563087&expires=8h&rt=pr&r=208841595&mlogid=2073818771479878195&vuk=2670780510&vbdid=3060741257&fin=test.mp3&fn=test.mp3&rtype=1&iv=0&dp-logid=2073818771479878195&dp-callid=0.1.1&hps=1&csl=350&csign=KyHZ%2FVszqDUGhAcfQwZG0kv%2BHio%3D&by=themis";
    [[JZJAudioPlayManager shareInstance] playWithPath:urlString completion:^(JZJAudioPlayError error) {
        NSLog(@"error = %d",error);
    }];
}

-(void)playButtonClick
{
    [[JZJAudioPlayManager shareInstance] resume];
}

-(void)pauseButtonClick
{
    [[JZJAudioPlayManager shareInstance] pause];
}

-(void)stopButtonClick
{
    [[JZJAudioPlayManager shareInstance] stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
