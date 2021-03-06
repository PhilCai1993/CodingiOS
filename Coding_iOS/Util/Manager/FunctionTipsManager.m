//
//  FunctionTipsManager.m
//  Coding_iOS
//
//  Created by Ease on 15/6/23.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

static NSString *kFunctionTipStr_Version = @"version";

#import "FunctionTipsManager.h"

@interface FunctionTipsManager ()
@property (strong, nonatomic) NSMutableDictionary *tipsDict;
@end

@implementation FunctionTipsManager
+ (instancetype)shareManager{
    static FunctionTipsManager *shared_manager = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        shared_manager = [[self alloc] init];
    });
    return shared_manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        _tipsDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self p_cacheFilePath]];
//        if (![[_tipsDict valueForKey:@"version"] isEqualToString:kVersion_Coding]) {
//            _tipsDict = [@{kFunctionTipStr_Version: kVersion_Coding,
//                           kFunctionTipStr_MR: @(YES),
//                           kFunctionTipStr_PR: @(YES),
//                           kFunctionTipStr_ReadMe: @(YES),
//                           kFunctionTipStr_CommitList: @(YES),
//                           } mutableCopy];
//            [_tipsDict writeToFile:[self p_cacheFilePath] atomically:YES];
//        }
    }
    return self;
}

- (NSString *)p_cacheFilePath{
    NSString *fileName = @"FunctionNeedTips.plist";
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths firstObject];
    return [cachePath stringByAppendingPathComponent:fileName];
}

- (BOOL)needToTip:(NSString *)functionStr{
    NSNumber *needToTip = [_tipsDict valueForKey:functionStr];
    return needToTip.boolValue;
}

- (BOOL)markTiped:(NSString *)functionStr{
    NSNumber *needToTip = [_tipsDict valueForKey:functionStr];
    if (!needToTip.boolValue) {
        return NO;
    }
    [_tipsDict setValue:@(NO) forKey:functionStr];
    return [_tipsDict writeToFile:[self p_cacheFilePath] atomically:YES];
}

@end
