//
//  FileDownloadView.m
//  Coding_iOS
//
//  Created by Ease on 14/12/16.
//  Copyright (c) 2014年 Coding. All rights reserved.
//

#import "FileDownloadView.h"
#import "ASProgressPopUpView.h"
#import "Coding_FileManager.h"
#import "YLImageView.h"

@interface FileDownloadView ()
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) ASProgressPopUpView *progressView;
@property (strong, nonatomic) UIButton *stateButton;
@property (strong, nonatomic) UIView *toolBarView;

@property (strong, nonatomic) UILabel *nameLabel, *sizeLabel;
@property (strong, nonatomic) NSProgress *progress;
@end

@implementation FileDownloadView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //        CGFloat frameHeight = CGRectGetHeight(frame);
    }
    return self;
}

- (void)setFile:(ProjectFile *)file{
    _file = file;
    if (!_file) {
        return;
    }
    [self loadLayoutWithCurFile];
    
    if (_file.preview && _file.preview.length > 0) {
        [_iconView sd_setImageWithURL:[NSURL URLWithString:_file.owner_preview] placeholderImage:nil options:SDWebImageRetryFailed| SDWebImageLowPriority| SDWebImageHandleCookies progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                [error showError:error];
            }
        }];
        [_progressView hidePopUpViewAnimated:NO];
    }else{
        _iconView.image = [UIImage imageNamed:[_file fileIconName]];
        [_progressView showPopUpViewAnimated:NO];
    }
    Coding_DownloadTask *cDownloadTask = [_file cDownloadTask];
    if (cDownloadTask) {
        self.progress = cDownloadTask.progress;
    }
    [self changeToState:_file.downloadState];
}

- (void)loadLayoutWithCurFile{
    if (!_file) {
        return;
    }
    CGFloat buttonHeight;
    if (_file.preview && _file.preview.length > 0) {
        if (!_iconView) {
            _iconView = [[YLImageView alloc] initWithFrame:self.bounds];
            _iconView.backgroundColor = [UIColor blackColor];
            _iconView.contentMode = UIViewContentModeScaleAspectFit;
            [self addSubview:_iconView];
            [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self);
            }];
        }
        if (!_toolBarView) {
            _toolBarView = [UIView new];
            _toolBarView.backgroundColor = kColorTableSectionBg;
            [self addSubview:_toolBarView];
            [_toolBarView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.bottom.equalTo(self);
                make.height.mas_equalTo(49);
            }];
        }
        if (!_sizeLabel) {
            _sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _sizeLabel.textAlignment = NSTextAlignmentCenter;
            _sizeLabel.textColor = [UIColor colorWithHexString:@"0x666666"];
            _sizeLabel.font = [UIFont systemFontOfSize:14];
            _sizeLabel.text = @"正在下载中...";
            [_toolBarView addSubview:_sizeLabel];
            [_sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.equalTo(_toolBarView);
                make.height.mas_equalTo(30);
            }];
        }
        if (!_progressView) {
            _progressView = [[ASProgressPopUpView alloc] initWithFrame:CGRectZero];
            _progressView.popUpViewCornerRadius = 12.0;
            _progressView.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:12];
            [_progressView setTrackTintColor:[UIColor colorWithHexString:@"0xfafafa"]];
            _progressView.popUpViewAnimatedColors = @[[UIColor colorWithHexString:@"0x3bbd79"]];
            _progressView.hidden = YES;
            [_progressView hidePopUpViewAnimated:NO];
            [_toolBarView addSubview:self.progressView];
            [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {//上下居中基准
                make.height.mas_equalTo(2.0);
                make.bottom.equalTo(_toolBarView).offset(-15);
                make.left.equalTo(_toolBarView).offset(20);
                make.right.equalTo(_toolBarView).offset(-60);
            }];
        }
        if (!_stateButton) {
            _stateButton = [UIButton new];
            [_stateButton setTitleColor:[UIColor colorWithHexString:@"0x3bbd79"] forState:UIControlStateNormal];
            [_stateButton addTarget:self action:@selector(clickedByUser) forControlEvents:UIControlEventTouchUpInside];
            [_toolBarView addSubview:_stateButton];
        }
    }else{
        buttonHeight = 45;
        if (!_iconView) {
            _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
            _iconView.contentMode = UIViewContentModeScaleAspectFill;
            _iconView.layer.masksToBounds = YES;
            _iconView.layer.cornerRadius = 2.0;
            _iconView.layer.borderWidth = 0.5;
            _iconView.layer.borderColor = [UIColor colorWithHexString:@"0xdddddd"].CGColor;
            [self addSubview:_iconView];
        }
        if (!_nameLabel) {
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _nameLabel.textAlignment = NSTextAlignmentCenter;
            _nameLabel.textColor = [UIColor colorWithHexString:@"0x222222"];
            _nameLabel.font = [UIFont systemFontOfSize:16];
            [self addSubview:_nameLabel];
        }
        if (!_sizeLabel) {
            _sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _sizeLabel.textAlignment = NSTextAlignmentCenter;
            _sizeLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
            _sizeLabel.font = [UIFont systemFontOfSize:12];
            [self addSubview:_sizeLabel];
        }
        if (!_progressView) {
            _progressView = [[ASProgressPopUpView alloc] initWithFrame:CGRectZero];
            _progressView.popUpViewCornerRadius = 12.0;
            _progressView.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:12];
            [_progressView setTrackTintColor:[UIColor colorWithHexString:@"0xe6e6e6"]];
            _progressView.popUpViewAnimatedColors = @[[UIColor colorWithHexString:@"0x3bbd79"]];
            _progressView.hidden = YES;
            [_progressView hidePopUpViewAnimated:NO];
            [self addSubview:self.progressView];
        }
        if (!_stateButton) {
            _stateButton = [[UIButton alloc] init];
            _stateButton = [UIButton buttonWithStyle:StrapPrimaryStyle andTitle:@"下载原文件" andFrame:CGRectMake(0, 0, buttonHeight, buttonHeight) target:self action:@selector(clickedByUser)];
            [self addSubview:_stateButton];
        }
        
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(45, 45));
            make.bottom.equalTo(_nameLabel.mas_top).offset(-50);
        }];
        
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(25);
        }];
        
        [_sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(20);
            make.top.equalTo(_nameLabel.mas_bottom).offset(20);
        }];
        
        [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {//上下居中基准
            make.centerY.equalTo(self.mas_centerY);

            make.height.mas_equalTo(2.0);
            make.top.equalTo(_sizeLabel.mas_bottom).offset(20);
        }];
        
        [_stateButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(buttonHeight);
            make.top.equalTo(_progressView.mas_bottom).offset(20);
            
            make.width.equalTo(@[@(kScreen_Width- 2*kPaddingLeftWidth), _nameLabel, _sizeLabel, _progressView]);
            make.centerX.equalTo(@[self, _iconView, _nameLabel, _sizeLabel, _progressView]);
        }];
    }
}




- (void)setProgress:(NSProgress *)progress{
    _progress = progress;
    __weak typeof(self) weakSelf = self;
    if (_progress) {
        [RACObserve(self, progress.fractionCompleted) subscribeNext:^(NSNumber *fractionCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updatePregress:fractionCompleted.doubleValue];
            });
        }];
    }else{
        _progressView.hidden = YES;
    }
}

- (void)updatePregress:(double)fractionCompleted{
    //更新进度
    self.progressView.progress = fractionCompleted;
    if (ABS(fractionCompleted - 1.0) < 0.0001) {
        //已完成
        [self.progressView hidePopUpViewAnimated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressView.hidden = YES;
            [self changeToState:DownloadStateDownloaded];
        });
    }else{
        self.progressView.hidden = NO;
    }
}

- (void)clickedByUser{
    Coding_FileManager *manager = [Coding_FileManager sharedManager];
    NSURL *fileUrl = [manager diskDownloadUrlForFile:_file.diskFileName];
    if (fileUrl) {//已经下载到本地了
        if (_goToFileBlock) {
            _goToFileBlock(self.file);
        }
    }else{//要下载
        NSURLSessionDownloadTask *downloadTask;
        if (_file.cDownloadTask) {//暂停或者重新开始
            downloadTask = _file.cDownloadTask.task;
            switch (downloadTask.state) {
                case NSURLSessionTaskStateRunning:
                    [downloadTask suspend];
                    [self changeToState:DownloadStatePausing];
                    
                    break;
                case NSURLSessionTaskStateSuspended:
                    [downloadTask resume];
                    [self changeToState:DownloadStateDownloading];
                    break;
                default:
                    break;
            }
        }else{//新建下载
            
            __weak typeof(self) weakSelf = self;
            Coding_DownloadTask *cDownloadTask = [manager addDownloadTaskForFile:self.file completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                if (error) {
                    [weakSelf changeToState:DownloadStateDefault];
                    [weakSelf showError:error];
                    DebugLog(@"ERROR:%@", error.description);
                }else{
                    [weakSelf changeToState:DownloadStateDownloaded];
                    DebugLog(@"File downloaded to: %@", filePath);
                }
            }];
            
            self.progress = cDownloadTask.progress;
            _progressView.progress = 0.0;
            _progressView.hidden = NO;
            [self changeToState:DownloadStateDownloading];
        }
    }
}

- (void)changeToState:(DownloadState)state{
    NSString *stateTitle;
    switch (state) {
        case DownloadStateDefault:
            stateTitle = @"下载原文件";
            break;
        case DownloadStateDownloading:
            stateTitle = @"暂停下载";
            break;
        case DownloadStatePausing:
            stateTitle = @"恢复下载";
            break;
        case DownloadStateDownloaded:
            stateTitle = @"用其他应用打开";
            break;
        default:
            break;
    }
    
    
    if (_file.preview && _file.preview.length > 0) {
        if (state == DownloadStateDownloading) {
            _sizeLabel.hidden = NO;
            _progressView.hidden = NO;
            [_stateButton setTitle:nil forState:UIControlStateNormal];
            [_stateButton setImage:[UIImage imageNamed:@"button_download_cancel"] forState:UIControlStateNormal];
            [_stateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.width.mas_equalTo(44);
                make.centerY.mas_equalTo(_toolBarView);
                make.right.mas_equalTo(_toolBarView).offset(-9);
            }];
        }else{
            _sizeLabel.hidden = YES;
            _progressView.hidden = YES;
            [_stateButton setTitle:stateTitle forState:UIControlStateNormal];
            [_stateButton setImage:nil forState:UIControlStateNormal];
            [_stateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(_toolBarView);
            }];
        }
    }else{
        _nameLabel.text = _file.name;
        _sizeLabel.text = [NSString sizeDisplayWithByte:_file.size.floatValue];

        [self.progressView setHidden:!(state == DownloadStateDownloading || state == DownloadStatePausing)];
        [_stateButton setTitle:stateTitle forState:UIControlStateNormal];
        if (state == DownloadStateDownloaded) {
            [_stateButton defaultStyle];
        }else{
            [_stateButton primaryStyle];
        }
    }
    
    if (state == DownloadStateDownloaded && self.completionBlock && !self.hidden) {
        self.completionBlock();
    }
}

@end
