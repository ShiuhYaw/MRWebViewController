//
//  MRWebView.h
//  MRWebViewController
//
//  Created by Yaw on 17/3/17.
//  Copyright © 2017 Yaw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WKScriptMessageHandler;
@class MRWebView, JSContext;

@protocol MRWebViewDelegate <NSObject>
@optional

- (void)webViewDidStartLoad:(MRWebView *)webView;
- (void)webViewDidFinishLoad:(MRWebView *)webView;
- (void)webView:(MRWebView *)webView didFailLoadWithError:(nonnull NSError *)error;
- (BOOL)webView:(MRWebView *)webView shouldStartLoadWithRequest:(nonnull NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)webView:(MRWebView *)webView updateProgress:(CGFloat)progress;
@end

@interface MRWebView : UIView

- (instancetype)initWithFrame:(CGRect)frame usingUIWebView:(BOOL)usingUIWebView;

@property (weak, nonatomic) id<MRWebViewDelegate> delegate;
@property (readonly, nonatomic) id realWebView;
@property (readonly, nonatomic) BOOL usingUIWebView;
@property (readonly, nonatomic) double estimateProgress;
@property (readonly, nonatomic) NSURLRequest *originRequest;
@property (readonly, nonatomic) JSContext *jsContext;

- (void)addScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;
- (NSInteger)countOfHistory;
- (void)goBackWithStep:(NSInteger)step;

@property (readonly, nonatomic) UIScrollView *scrollView;

- (id)loadRequest:(NSURLRequest *)request;
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

@property (readonly, copy, nonatomic)NSString *title;
@property (readonly, nonatomic) NSURLRequest *currentRequest;
@property (readonly, nonatomic) NSURL *URL;
@property (readonly, nonatomic, getter=isLoading) BOOL loading;
@property (readonly, nonatomic) BOOL canGoBack;
@property (readonly, nonatomic) BOOL canGoForward;

- (id)goBack;
- (id)goForward;
- (id)reload;
- (id)reloadFromOrigin;
- (void)stopLoading;
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler;
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString __deprecated_msg("Method deprecate. Use [evaluateJavaScript:completionHandler:]");

@property (nonatomic) BOOL scalesPageToFit;
@property (nonatomic) BOOL allowsInlineMediaPlayback;

@end

NS_ASSUME_NONNULL_END
