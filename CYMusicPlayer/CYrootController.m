//
//  CYrootController.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/2.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYrootController.h"
#import "CYheaderView.h"
#import "CYSingController.h"
#import "CYIdentificationController.h"
#import "CYMyController.h"
#import "Masonry.h"
#import "CYVminiPlayer.h"

@interface CYrootController () <CYheaderViewDelegate, UIScrollViewDelegate>
@property (strong, nonatomic) CYheaderView *titleV;
@property (strong , nonatomic) UIScrollView *scrollView;
@property (copy , nonatomic) NSMutableArray<UIViewController*> *subControllers;
@end

@implementation CYrootController

- (void)viewDidLoad {    
    [super viewDidLoad];
    // 应付iOS7的调整，烦！
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.view setBackgroundColor: [UIColor whiteColor]];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"concise_icon_more_normal"] style: UIBarButtonItemStylePlain target: self action: @selector(skipToMorePage)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"allMusic_search_all_h"] style: UIBarButtonItemStylePlain target: self action: @selector(skipToSearchPage)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
// 添加中间的titleView
    NSArray *titles = @[@"我的", @"听歌识曲", @"K歌"];
    self.titleV = [[CYheaderView alloc] initWithFrame: CGRectMake(0, 0, 240, 40) andtitles: titles];
    self.navigationItem.titleView = self.titleV;
    
//    添加一个scrollView
    self.scrollView = [UIScrollView new];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview: self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.right.equalTo(self.view);
        make.bottom.mas_equalTo(self.view).offset(-50);
    }];
    
//    在scrollView中添加三个子控制器的视图
    CYMyController *myc = [CYMyController new];
    CYIdentificationController *identc = [CYIdentificationController new];
    CYSingController *singc = [CYSingController new];
    [self.subControllers addObject: myc];
    [self.subControllers addObject: identc];
    [self.subControllers addObject: singc];

    UIView *mycview = myc.view;
    UIView *identcview = identc.view;
    UIView *singcview = singc.view;
    [self.scrollView addSubview: mycview];
    [self.scrollView addSubview: identcview];
    [self.scrollView addSubview: singcview];
    
//    添加约束
    [mycview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.scrollView);
        make.right.equalTo(identcview.mas_left);
        make.width.height.equalTo(self.scrollView);
    }];
    [identcview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(mycview.mas_right);
        make.right.equalTo(singcview.mas_left);
         make.top.bottom.equalTo(self.scrollView);
        make.width.height.equalTo(self.scrollView);
    }];
    [singcview mas_makeConstraints:^(MASConstraintMaker *make) {
         make.right.top.bottom.equalTo(self.scrollView);
         make.left.equalTo(identcview.mas_right);
        make.width.height.equalTo(self.scrollView);
    }];
    
    self.titleV.delegate = self;
    self.scrollView.delegate = self;
}

#pragma mark - function about navigationbar

// 跳转到“更多”
- (void) skipToMorePage {
    
}

// 跳转到"搜索"
- (void) skipToSearchPage {
    
}

#pragma mark - ScrollView Delegate methods
- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger index = self.scrollView.contentOffset.x / self.scrollView.bounds.size.width + 1;
    self.titleV.selectedPage = index;
}

#pragma mark - CYheaderView Delegate method
- (void) changePage: (NSInteger) selectedPageNum {
    [self.scrollView setContentOffset: CGPointMake((selectedPageNum - 1)* self.scrollView.bounds.size.width, 0) animated: YES];
}

#pragma mark - lazy load
- (NSMutableArray<UIViewController *> *)subControllers {
    if (_subControllers == nil) {
        _subControllers = [NSMutableArray array];
    }
    return _subControllers;
}
@end
