//
//  AVPlayerViewController.m
//  RecordAudio
//
//  Created by 景中杰 on 17/3/30.
//  Copyright © 2017年 zziazm. All rights reserved.
//

#import "AVPlayerViewController.h"
#import "JZJAVPlayerManager.h"

@interface AVPlayerViewController ()

@property(nonatomic, strong)UILabel *label;

@end

@implementation AVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat width = 100, height = 40;
    
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loadButton.frame = CGRectMake(self.view.frame.size.width / 2 - width / 2, 100, width, height);
    [loadButton setTitle:@"加载" forState:UIControlStateNormal];
    [loadButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadButton];
    
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
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - width / 2, 350, width, height)];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:label];
    self.label = label;
}

-(void)loadButtonClick
{
    [[JZJAVPlayerManager shareInstance] loadWithURL:[NSURL URLWithString:@"https://nj01ct01.baidupcs.com/file/67e08e7b3db5bd550eb2c3077bc9341d?bkt=p3-140067e08e7b3db5bd550eb2c3077bc9341da3ab7671000000286647&fid=2670780510-250528-430066337834612&time=1490876687&sign=FDTAXGERLBHS-DCb740ccc5511e5e8fedcff06b081203-ouFLOl6a8eNSZiRGNRm92wOoPn8%3D&to=63&size=2647623&sta_dx=2647623&sta_cs=0&sta_ft=mp3&sta_ct=0&sta_mt=0&fm2=MH,Yangquan,Netizen-anywhere,,beijingct&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=140067e08e7b3db5bd550eb2c3077bc9341da3ab7671000000286647&sl=70189134&expires=8h&rt=pr&r=324544785&mlogid=2060694999951594697&vuk=2670780510&vbdid=3060741257&fin=test.mp3&fn=test.mp3&rtype=1&iv=0&dp-logid=2060694999951594697&dp-callid=0.1.1&hps=1&csl=240&csign=6sh0mTdY5aOsbum91qLSCZU%2BQRU%3D&by=themis"]];
    [JZJAVPlayerManager shareInstance].block = ^(float p)
    {
        self.label.text = [NSString stringWithFormat:@"加载进度:%.2f",p];
    };
}

-(void)playButtonClick
{
    [[JZJAVPlayerManager shareInstance] play];
}

-(void)pauseButtonClick
{
    [[JZJAVPlayerManager shareInstance] pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
