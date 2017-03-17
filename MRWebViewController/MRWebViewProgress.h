//
//  MRWebViewProgress.h
//  MRWebViewController
//
//  Created by Yaw on 17/3/17.
//  Copyright © 2017 Yaw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#undef MRWeak
#if __has_feature(objc_arc_weak)
#define MRWeak weak
#else
#define MRWeak unsafe_unretained
#endif

typedef void (^MRWebViewProgressBlock)(CGFloat progress);

@protocol MRWebViewProgressDelegate;

@interface MRWebViewProgress : NSObject <UIWebViewDelegate>

@property (MRWeak, nonatomic) id<MRWebViewProgressDelegate> progressDelegate;
@property (MRWeak, nonatomic) id<UIWebViewDelegate> webViewProxyDelegate;
@property (copy, nonatomic) MRWebViewProgressBlock progressBlock;
@property (readonly, nonatomic) CGFloat progress;

- (void)reset;

@end

@protocol MRWebViewProgressDelegate <NSObject>

- (void)webViewProgress:(MRWebViewProgress *)webViewProgress updateProgress:(CGFloat)progress;

@end
