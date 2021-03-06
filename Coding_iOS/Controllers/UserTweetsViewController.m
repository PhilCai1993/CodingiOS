//
//  UserTweetsViewController.m
//  Coding_iOS
//
//  Created by 王 原闯 on 14-9-4.
//  Copyright (c) 2014年 Coding. All rights reserved.
//

#define kCommentIndexNotFound -1

#import "UserTweetsViewController.h"
#import "TweetCell.h"
#import "ODRefreshControl.h"
#import "Coding_NetAPIManager.h"
#import "UserInfoViewController.h"
#import "LikersViewController.h"
#import "TweetDetailViewController.h"
#import "SVPullToRefresh.h"
#import "WebViewController.h"

@interface UserTweetsViewController ()
@property (nonatomic, strong) UITableView *myTableView;
@property (nonatomic, strong) ODRefreshControl *refreshControl;

//评论
@property (nonatomic, strong) UIMessageInputView *myMsgInputView;
@property (nonatomic, strong) Tweet *commentTweet;
@property (nonatomic, assign) NSInteger commentIndex;
@property (nonatomic, strong) UIView *commentSender;
@property (nonatomic, strong) User *commentToUser;

//删冒泡
@property (strong, nonatomic) Tweet *deleteTweet;
@property (nonatomic, assign) NSInteger deleteTweetsIndex;
@end

@implementation UserTweetsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = _curTweets.curUser.name;
    
    //    添加myTableView
    _myTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        Class tweetCellClass = [TweetCell class];
        [tableView registerClass:tweetCellClass forCellReuseIdentifier:kCellIdentifier_Tweet];
        [self.view addSubview:tableView];
        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        tableView;
    });
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.myTableView];
    [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    //评论
    __weak typeof(self) weakSelf = self;
    _myMsgInputView = [UIMessageInputView messageInputViewWithType:UIMessageInputViewContentTypeTweet];
    _myMsgInputView.delegate = self;
    
    [_myTableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf refreshMore];
    }];
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_myMsgInputView) {
        [_myMsgInputView prepareToDismiss];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //    键盘
    if (_myMsgInputView) {
        [_myMsgInputView prepareToShow];
    }
    [self.myTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIMessageInputViewDelegate
- (void)messageInputView:(UIMessageInputView *)inputView sendText:(NSString *)text{
    [self sendCommentMessage:text];
}

- (void)messageInputView:(UIMessageInputView *)inputView heightToBottomChenged:(CGFloat)heightToBottom{
    [UIView animateWithDuration:0.25 delay:0.0f options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        UIEdgeInsets contentInsets= UIEdgeInsetsMake(0.0, 0.0, heightToBottom, 0.0);;
        CGFloat msgInputY = kScreen_Height - heightToBottom - 64;
        
        self.myTableView.contentInset = contentInsets;
        self.myTableView.scrollIndicatorInsets = contentInsets;
        
        if ([_commentSender isKindOfClass:[UIView class]] && !self.myTableView.isDragging && heightToBottom > 60) {
            UIView *senderView = _commentSender;
            CGFloat senderViewBottom = [_myTableView convertPoint:CGPointZero fromView:senderView].y+ CGRectGetMaxY(senderView.bounds);
            CGFloat contentOffsetY = MAX(0, senderViewBottom- msgInputY);
            [self.myTableView setContentOffset:CGPointMake(0, contentOffsetY) animated:YES];
        }
    } completion:nil];
}


#pragma mark M
- (void)deleteTweet:(Tweet *)curTweet outTweetsIndex:(NSInteger)outTweetsIndex{
    ESWeakSelf;
    [[Coding_NetAPIManager sharedManager] request_Tweet_Delete_WithObj:curTweet andBlock:^(id data, NSError *error) {
        ESStrongSelf;
        if (data) {
            [_self.curTweets.list removeObject:curTweet];
            [_self.myTableView reloadData];
            [_self.view configBlankPage:([[Login curLoginUser] isSameToUser:_self.curTweets.curUser]? EaseBlankPageTypeTweet: EaseBlankPageTypeTweetOther)  hasData:(_self.curTweets.list.count > 0) hasError:NO reloadButtonBlock:^(id sender) {
                ESStrongSelf;
                [_self sendRequest];
            }];
        }
    }];
}

- (void)deleteComment:(Comment *)comment ofTweet:(Tweet *)tweet{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_TweetComment_Delete_WithTweet:tweet andComment:comment andBlock:^(id data, NSError *error) {
        if (data) {
            [tweet deleteComment:comment];
            [weakSelf.myTableView reloadData];
            
        }
    }];
}

#pragma mark Refresh M

- (void)refresh{
    if (_curTweets.isLoading) {
        return;
    }
    _curTweets.willLoadMore = NO;
    [self sendRequest];
}

- (void)refreshMore{
    if (_curTweets.isLoading || !_curTweets.canLoadMore) {
        return;
    }
    _curTweets.willLoadMore = YES;
    [self sendRequest];
}

- (void)sendRequest{
    if (_curTweets.list.count <= 0) {
        [self.view beginLoading];
    }
    __weak typeof(self) weakSelf = self;
    if (_curTweets.curUser.name.length <= 0) {
        [self refreshCurUser];
        return;
    }
    
    [[Coding_NetAPIManager sharedManager] request_Tweets_WithObj:_curTweets andBlock:^(id data, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        [weakSelf.view endLoading];
        [weakSelf.myTableView.infiniteScrollingView stopAnimating];
        if (data) {
            [weakSelf.curTweets configWithTweets:data];
            [weakSelf.myTableView reloadData];
            weakSelf.myTableView.showsInfiniteScrolling = weakSelf.curTweets.canLoadMore;
        }
        [weakSelf.view configBlankPage:([[Login curLoginUser] isSameToUser:self.curTweets.curUser]? EaseBlankPageTypeTweet: EaseBlankPageTypeTweetOther) hasData:(weakSelf.curTweets.list.count > 0) hasError:(error != nil) reloadButtonBlock:^(id sender) {
            [weakSelf sendRequest];
        }];
    }];
}


- (void)refreshCurUser{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_UserInfo_WithObj:_curTweets.curUser andBlock:^(id data, NSError *error) {
        if (data) {
            weakSelf.curTweets.curUser = data;
            weakSelf.title = weakSelf.curTweets.curUser.name;
            [weakSelf sendRequest];
        }else{
            [weakSelf.view endLoading];
            [weakSelf.view configBlankPage:([[Login curLoginUser] isSameToUser:self.curTweets.curUser]? EaseBlankPageTypeTweet: EaseBlankPageTypeTweetOther) hasData:(weakSelf.curTweets.list.count > 0) hasError:YES reloadButtonBlock:^(id sender) {
                [weakSelf sendRequest];
            }];
        }
    }];
}


#pragma mark TableM
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (_curTweets && _curTweets.list) {
        return [_curTweets.list count];
    }else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_Tweet forIndexPath:indexPath];
    cell.tweet = [_curTweets.list objectAtIndex:indexPath.row];
    
    __weak typeof(self) weakSelf = self;
    cell.commentClickedBlock = ^(Tweet *tweet, NSInteger index, id sender){
        if ([self.myMsgInputView isAndResignFirstResponder]) {
            return ;
        }
        weakSelf.commentTweet = tweet;
        weakSelf.commentIndex = index;
        weakSelf.commentSender = sender;
        
        weakSelf.myMsgInputView.commentOfId = tweet.id;
        
        if (weakSelf.commentIndex >= 0) {
            weakSelf.commentToUser = ((Comment*)[weakSelf.commentTweet.comment_list objectAtIndex:weakSelf.commentIndex]).owner;
            
            weakSelf.myMsgInputView.toUser = ((Comment*)[weakSelf.commentTweet.comment_list objectAtIndex:weakSelf.commentIndex]).owner;
            
            if ([Login isLoginUserGlobalKey:weakSelf.commentToUser.global_key]) {
                
                UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetCustomWithTitle:@"删除此评论" buttonTitles:nil destructiveTitle:@"确认删除" cancelTitle:@"取消" andDidDismissBlock:^(UIActionSheet *sheet, NSInteger index) {
                    if (index == 0 && weakSelf.commentIndex >= 0) {
                        Comment *comment  = [weakSelf.commentTweet.comment_list objectAtIndex:weakSelf.commentIndex];
                        [weakSelf deleteComment:comment ofTweet:weakSelf.commentTweet];
                    }
                }];
                [actionSheet showInView:self.view];
                return;
            }
        }else{
            weakSelf.myMsgInputView.toUser = nil;
        }
        [_myMsgInputView notAndBecomeFirstResponder];
    };
    cell.likeBtnClickedBlock = ^(Tweet *tweet){
        [weakSelf.myTableView reloadData];
    };
    cell.userBtnClickedBlock = ^(User *curUser){
        UserInfoViewController *vc = [[UserInfoViewController alloc] init];
        vc.curUser = curUser;
        [self.navigationController pushViewController:vc animated:YES];
    };
    cell.moreLikersBtnClickedBlock = ^(Tweet *curTweet){
        LikersViewController *vc = [[LikersViewController alloc] init];
        vc.curTweet = curTweet;
        [self.navigationController pushViewController:vc animated:YES];
    };
    cell.deleteClickedBlock = ^(Tweet *curTweet, NSInteger outTweetsIndex){
        if ([self.myMsgInputView isAndResignFirstResponder]) {
            return ;
        }
        self.deleteTweet = curTweet;
        self.deleteTweetsIndex = outTweetsIndex;
        UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetCustomWithTitle:@"删除此冒泡" buttonTitles:nil destructiveTitle:@"确认删除" cancelTitle:@"取消" andDidDismissBlock:^(UIActionSheet *sheet, NSInteger index) {
            if (index == 0) {
                [weakSelf deleteTweet:weakSelf.deleteTweet outTweetsIndex:weakSelf.deleteTweetsIndex];
            }
        }];
        [actionSheet showInView:self.view];
    };

    cell.goToDetailTweetBlock = ^(Tweet *curTweet){
        [self goToDetailWithTweet:curTweet];
    };
    cell.refreshSingleCCellBlock = ^(){
        [weakSelf.myTableView reloadData];
    };
    cell.mediaItemClickedBlock = ^(HtmlMediaItem *curItem){
        [weakSelf analyseLinkStr:curItem.href];
    };
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:0];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [TweetCell cellHeightWithObj:[_curTweets.list objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Tweet *toTweet = [_curTweets.list objectAtIndex:indexPath.row];
    [self goToDetailWithTweet:toTweet];
}

- (void)goToDetailWithTweet:(Tweet *)curTweet{
    TweetDetailViewController *vc = [[TweetDetailViewController alloc] init];
    vc.curTweet = curTweet;
    __weak typeof(self) weakSelf = self;
    vc.deleteTweetBlock = ^(Tweet *toDeleteTweet){
        [weakSelf.curTweets.list removeObject:toDeleteTweet];
        [weakSelf.myTableView reloadData];
        [weakSelf.view configBlankPage:([[Login curLoginUser] isSameToUser:self.curTweets.curUser]? EaseBlankPageTypeTweet: EaseBlankPageTypeTweetOther) hasData:(weakSelf.curTweets.list.count > 0) hasError:NO reloadButtonBlock:^(id sender) {
            [weakSelf sendRequest];
        }];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)analyseLinkStr:(NSString *)linkStr{
    if (linkStr.length <= 0) {
        return;
    }
    UIViewController *vc = [BaseViewController analyseVCFromLinkStr:linkStr];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        //网页
        WebViewController *webVc = [WebViewController webVCWithUrlStr:linkStr];
        [self.navigationController pushViewController:webVc animated:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView == _myTableView) {
        [self.myMsgInputView isAndResignFirstResponder];
    }
}

#pragma mark Comment To Tweet
- (void)sendCommentMessage:(id)obj{
    if (_commentIndex >= 0) {
        _commentTweet.nextCommentStr = [NSString stringWithFormat:@"@%@ %@", _commentToUser.name, obj];
    }else{
        _commentTweet.nextCommentStr = obj;
    }
    [self sendCurComment:_commentTweet];
    {
        _commentTweet = nil;
        _commentIndex = kCommentIndexNotFound;
        _commentSender = nil;
        _commentToUser = nil;
    }
    self.myMsgInputView.toUser = nil;
    [self.myMsgInputView isAndResignFirstResponder];
}


- (void)sendCurComment:(Tweet *)commentObj{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_Tweet_DoComment_WithObj:commentObj andBlock:^(id data, NSError *error) {
        if (data) {
            Comment *resultCommnet = (Comment *)data;
            resultCommnet.owner = [Login curLoginUser];
            [commentObj addNewComment:resultCommnet];
            [weakSelf.myTableView reloadData];
        }
    }];
}

- (void)dealloc
{
    _myTableView.delegate = nil;
    _myTableView.dataSource = nil;
}

@end
