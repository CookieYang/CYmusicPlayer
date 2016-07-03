//
//  CYMyController.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/3.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYMyController.h"
#import "Masonry.h"
#import "CYVminiPlayer.h"
#import <AudioToolbox/AudioFile.h>

@interface CYMyController () <UITableViewDelegate, UITableViewDataSource>
@property (copy , nonatomic) NSArray *musicList;
@end


static NSString *cellIdentifier = @"listCell";
@implementation CYMyController



- (void) viewDidLoad {
    [self.tableView registerClass: [UITableViewCell class] forCellReuseIdentifier: cellIdentifier];
    self.tableView.delegate = self;
}

#pragma mark - 表格代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.musicList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier: cellIdentifier forIndexPath: indexPath];
    cell.textLabel.text = self.musicList[indexPath.row][@"MusicName"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[CYVminiPlayer sharedSingledefaultPlayer] stop];
    [ [CYVminiPlayer sharedSingledefaultPlayer] startWithMusicName: self.musicList[indexPath.row][@"MusicName"] fileType: self.musicList[indexPath.row][@"Type"] ];
}

#pragma mark - 数据相关
- (NSArray *)musicList {
    if (_musicList == nil) {
        _musicList = @[@{@"MusicName": @"01aijiujianrenxin.mp3", @"Type": @"1"},@{@"MusicName": @"05qingge.mp3", @"Type": @"1"},@{@"MusicName": @"M4ASample.m4a", @"Type": @"2"}];
    }
    return _musicList;
}
@end
