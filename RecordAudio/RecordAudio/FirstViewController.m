//
//  ViewController.m
//  RecordAudio
//
//  Created by 赵铭 on 16/8/29.
//  Copyright © 2016年 zziazm. All rights reserved.
//

#import "FirstViewController.h"
#import "CustomCell.h"
#import <AVFoundation/AVFoundation.h>
#import "CustomCellModel.h"
@interface FirstViewController ()<AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioRecorder * audioRecorder;
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
@property (nonatomic, strong) AVAudioSession * audioSession;
@property (strong, nonatomic)  UITableView *tableview;
@property (nonatomic, strong) NSMutableArray * datasource;
@property (nonatomic, strong) CustomCellModel * previousSelectedModel;
@property (nonatomic, strong) NSTimer * metesTimer;
@property (nonatomic, strong) UIImageView * recoredAnimationView;
@property (nonatomic, strong) UILabel * label;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor  = [UIColor whiteColor];
    _tableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 44) style:UITableViewStylePlain];
    [self.view addSubview:_tableview];
    _tableview.delegate = self;
    _tableview .dataSource = self;
    
    UIToolbar * toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 44, [UIScreen mainScreen].bounds.size.width, 44)];
    [self.view addSubview:toolbar];
    UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 100, 30);
    button.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, 22);
    [button setTitle:@"开始录音" forState:UIControlStateNormal];
    [toolbar addSubview:button];
    [button addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [button addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [button addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    
    _recoredAnimationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    _recoredAnimationView.center = self.view.center;
    [self.view addSubview:_recoredAnimationView];
    _audioSession = [AVAudioSession sharedInstance];
    [self.tableview registerNib:[UINib nibWithNibName:@"CustomCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    _datasource = @[].mutableCopy;
}
- (BOOL)checkMicrophoneAvailability{
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
#pragma mark -- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _datasource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    CustomCellModel * model = _datasource[indexPath.row];
    if (model.isPlaying) {
        [cell.playImageView startAnimating];
    }
    else{
        [cell.playImageView stopAnimating];
    }
    return cell;
}

#pragma mark -- UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    CustomCellModel * model = _datasource[indexPath.row];
    if (self.audioPlayer.isPlaying) {
        if (model == _previousSelectedModel) {//选中的是正在播放的语音
            model.isPlaying = NO;
            [self.audioPlayer stop];
        }
        else{
            _previousSelectedModel.isPlaying = NO;
            model.isPlaying = YES;
            _previousSelectedModel = model;
            [self.audioPlayer stop];
            [self playAudioWithModel:model];
           
        }
    }
    else{
        _previousSelectedModel = model;
        [self playAudioWithModel:model];
    }
}
- (void)playAudioWithModel:(CustomCellModel *)model{
    //静止其他应用的音频回放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    NSError * error;
    //初始化AVAudioPlayer
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:model.audioURL error:&error];
    //设置代理
    self.audioPlayer.delegate = self;
    //开始播放
    BOOL success = [self.audioPlayer play];
    if (success) {
        NSLog(@"播放成功");
        model.isPlaying = YES;
        [self.tableview reloadData];
    }else{
        NSLog(@"播放失败");
    }
}
#pragma mark -- Action
- (IBAction)touchDown:(id)sender {
    NSLog(@"%s", __func__);
    
    if (![self checkMicrophoneAvailability]) {
        NSLog(@"麦克风不可用");
        return;
    }
    NSError * error;
    //设置音频存储位置
    NSString * url = NSTemporaryDirectory();
    url = [url stringByAppendingString:[NSString stringWithFormat:@"%f.aac", [[NSDate date] timeIntervalSince1970]]];
    //设置音频参数
    NSMutableDictionary * settings = @{}.mutableCopy;
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量），8000是电话采样率，对一般的录音已经足够了
    [settings setObject:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];//采样率，8000是电话采样率，对一般的录音已经足够了
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [settings setObject:[NSNumber numberWithInt: kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //录音通道数  1 或 2，设置成一个通道，iPnone只有一个麦克风，一个通道已经足够了
    [settings setObject:@1 forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [settings setObject:@16 forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    //初始化AVAudioRecorder对象
    self.audioRecorder = [[AVAudioRecorder  alloc] initWithURL:[NSURL fileURLWithPath:url] settings:settings error:&error];
    //开始音量检测
    self.audioRecorder.meteringEnabled = YES;
    //设置代理
    self.audioRecorder.delegate = self;
    //设置智能录音的模式
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    //开始录制
    BOOL success = [self.audioRecorder record];
    if (success) {
        _metesTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setVoiceImage) userInfo:nil repeats:YES];
        _label.text = @"手指上划，取消录音";
        NSLog(@"录音开始成功");
    }else{
        NSLog(@"录音开始失败");
    }
}

- (IBAction)touchUpInside:(id)sender {
    NSLog(@"%s", __func__);
    [self.audioRecorder stop];
}

- (IBAction)touchUpOutside:(id)sender {
    NSLog(@"%s", __func__);
    _label.text = @"长按按钮开始录音";
    self.audioRecorder.delegate = nil;
    [self.audioRecorder stop];
    self.audioRecorder = nil;
}

- (IBAction)touchDragEnter:(id)sender {
    _label.text = @"手指上划，取消录音";
    NSLog(@"%s", __func__);

}

- (IBAction)touchDragExit:(id)sender {
    _label.text = @"松开手指，取消录音";
    NSLog(@"%s", __func__);
    
}

- (IBAction)touchDragInside:(id)sender {
    NSLog(@"%s", __func__);
    
}
- (IBAction)touchDragOutside:(id)sender {
    NSLog(@"%s", __func__);
}

- (void)setVoiceImage{
    if (self.audioRecorder.isRecording) {
        [self.audioRecorder updateMeters];
        _recoredAnimationView.hidden = NO;
        float peakPower = [self.audioRecorder peakPowerForChannel:0];
//        NSLog(@"aaaaaa%f", peakPower);
        double voiceSound = pow(10, (0.05 * peakPower));
        if (0 < voiceSound <= 0.05) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback001"]];
        }else if (0.05<voiceSound<=0.10) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback002"]];
        }else if (0.10<voiceSound<=0.15) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback003"]];
        }else if (0.15<voiceSound<=0.20) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback004"]];
        }else if (0.20<voiceSound<=0.25) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback005"]];
        }else if (0.25<voiceSound<=0.30) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback006"]];
        }else if (0.30<voiceSound<=0.35) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback007"]];
        }else if (0.35<voiceSound<=0.40) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback008"]];
        }else if (0.40<voiceSound<=0.45) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback009"]];
        }else if (0.45<voiceSound<=0.50) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback010"]];
        }else if (0.50<voiceSound<=0.55) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback011"]];
        }else if (0.55<voiceSound<=0.60) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback012"]];
        }else if (0.60<voiceSound<=0.65) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback013"]];
        }else if (0.65<voiceSound<=0.70) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback014"]];
        }else if (0.70<voiceSound<=0.75) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback015"]];
        }else if (0.75<voiceSound<=0.80) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback016"]];
        }else if (0.80<voiceSound<=0.85) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback017"]];
        }else if (0.85<voiceSound<=0.90) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback018"]];
        }else if (0.90<voiceSound<=0.95) {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback019"]];
        }else {
            [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback020"]];
        }
    }
}
#pragma mark -- AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"%s", __func__);
    _recoredAnimationView.hidden = YES;
    self.audioRecorder.delegate = nil;
    self.audioRecorder = nil;
    CustomCellModel * model = [[CustomCellModel alloc] init];
    model.audioURL = recorder.url;
    [_datasource addObject:model];
    [_tableview insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_datasource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    NSLog(@"%@", error);
}

#pragma mark -- AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"%s", __func__);
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
    _previousSelectedModel.isPlaying = NO;
    [self.tableview reloadData];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    NSLog(@"%@", error);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
