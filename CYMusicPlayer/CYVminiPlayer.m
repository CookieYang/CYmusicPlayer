//
//  CYVminiPlayer.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/9.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYVminiPlayer.h"
#import "Masonry.h"
#import "UIView+ViewAnimation.h"
#import "NSTimer+BlockSupport.h"
#import "CYMusicPlayer.h"

@interface CYVminiPlayer ()
@property (strong , nonatomic) CYMusicPlayer *player;
@property (strong , nonatomic) NSTimer *timer;
@end

@implementation CYVminiPlayer
CYSingle_m(defaultPlayer)

#pragma mark - 初始化
- (void) startWithMusicName: (NSString *) MusicName fileType: (NSString *) fileType {
    self.userInteractionEnabled = YES;
    self.listButton.enabled = YES;
    self.iconButton.enabled  = YES;
    self.authName.hidden = YES;
    self.animationLabel.hidden = NO;
    
    AudioFileTypeID type = 0;
    if ([fileType isEqualToString: @"1"]) {
        type = kAudioFileMP3Type	;
    } else if ([fileType isEqualToString: @"2"]) {
        type =  kAudioFileM4AType ;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource: MusicName ofType: nil];
    self.player = [[CYMusicPlayer alloc] initWithFilePath:path fileType: type];
    [self.player addObserver: self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player play];
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame: frame]) {
        self.backgroundColor = [UIColor lightTextColor];
        self.userInteractionEnabled = NO;
        
        //增加分割线
        UIView *speView = [UIView new];
        speView.backgroundColor = [UIColor blackColor];
        [self addSubview: speView];
        [speView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.height.mas_equalTo(@1);
       }];
        
        //增加菜单按钮
        self.listButton = [UIButton new];
        self.listButton.enabled = NO;
        [self.listButton setImage: [UIImage imageNamed:@"miniplayer_btn_playlist_disable" ] forState: UIControlStateDisabled];
        [self.listButton setImage: [UIImage imageNamed:@"miniplayer_btn_playlist_normal" ] forState: UIControlStateNormal];
        [self.listButton setImage: [UIImage imageNamed:@"miniplayer_btn_playlist_highlight" ] forState: UIControlStateHighlighted];
        [self addSubview: self.listButton];
        [self.listButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-8);
            make.height.width.mas_equalTo(@40);
            make.centerY.equalTo(self);
        }];
 
        //增加播放按钮
        self.playButton = [[CYPlayButton alloc] initWithFrame: CGRectMake(0, 0, 30, 30)];
        [self addSubview: self.playButton];
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.listButton.mas_left).offset(-8);
            make.centerY.equalTo(self);
            make.height.width.mas_equalTo(@28);
        }];
        [self.playButton addTarget: self action: @selector(PlayButtonClicked) forControlEvents: UIControlEventTouchUpInside];
        
        // 增加专辑封面按钮
        self.iconButton = [UIButton new];
        self.iconButton.layer .cornerRadius = 20;
        self.iconButton.layer.masksToBounds = YES;
        [self addSubview: self.iconButton];
        self.iconButton.adjustsImageWhenHighlighted = NO;
        [self.iconButton setImage: [UIImage imageNamed: @"miniplayer_icon_albumcover_default" ] forState: UIControlStateNormal];
        [self.iconButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(8);
            make.centerY.equalTo(self);
            make.height.width.mas_equalTo(@40);
        }];
                
        // 添加歌曲名标签
        self.musicName = [UILabel new];
        self.musicName.text = @"Start to enjoy music";
        [self.musicName sizeToFit];
        [self.musicName setFont: [UIFont systemFontOfSize: 13 weight: 2]];
        [self addSubview: self.musicName];
        [self.musicName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.iconButton.mas_right).offset(5);
            make.top.equalTo(self.iconButton).offset(5);
        }];
        
        // 添加动态标签
        self.animationLabel = [UILabel new];
        self.animationLabel.textColor = [UIColor greenColor];
        self.animationLabel.text = @"左右滑动切换歌曲";
        [self.animationLabel setFont: [UIFont systemFontOfSize: 10]];
        [self.animationLabel sizeToFit];
        [self addSubview: self.animationLabel];
        UIView *v = [UIView new];
        [self addSubview: v];
        [v addFlashAnimationToLabel: self.animationLabel];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.musicName.mas_bottom).offset(5);
            make.left.equalTo(self.iconButton.mas_right).offset(5);
        }];
        self.animationLabel.hidden = YES;
       
       // 添加作者标签
        self.authName = [UILabel new];
        self.authName.textColor = [UIColor colorWithWhite: 0 alpha: 0.7];
        self.authName.text = @"左右滑动切换歌曲";
        [self.authName setFont: [UIFont systemFontOfSize: 10]];
        [self addSubview: self.authName];
        [self.authName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.musicName.mas_bottom).offset(5);
            make.left.equalTo(self.iconButton.mas_right).offset(5);
        }];
    }
    return self;
}

#pragma mark - 播放按钮点击事件
- (void) PlayButtonClicked {
    if (self.player.isPlayingOrWaiting) {
        [self.player pause];
    } else {
        [self.player play];
    }
}

- (void) stop {
    [self.player stop];
}

#pragma mark - 状态控制
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.player) {
        if ([keyPath isEqualToString:@"status"])
        {
            [self performSelectorOnMainThread:@selector(handleStatusChanged) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void) handleStatusChanged {
    if (self.player.isPlayingOrWaiting) {
        self.playButton.isPause = NO;
        [self startTimer];
    } else {
        self.playButton.isPause = YES;
        [self stopTimer];
        [self progressMove];
    }
}


- (void) startTimer {
    if (!_timer) {
        __weak typeof(self) weakSelf = self;
        _timer = [NSTimer CY_scheduledTimerWithTimeInterval: 1 block:^{
            __strong  typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf progressMove];
        } repeats: YES ];
    }
}

- (void) stopTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) progressMove {
    
    if (self.player.duration != 0) {
        [self.playButton setProgress: self.player.progress / self.player.duration];
    } else {
        [self.playButton setProgress: 0];
    }
}
@end
