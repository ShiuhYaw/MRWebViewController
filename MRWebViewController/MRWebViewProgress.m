//
//  MRWebViewProgress.m
//  MRWebViewController
//
//  Created by Yaw on 17/3/17.
//  Copyright © 2017 Yaw. All rights reserved.
//

#import "MRWebViewProgress.h"

static NSString * const MRCompleteRPCURL = @"webviewprogressproxy:///complete";
const CGFloat MRInitialProgressValue = 0.1;
const CGFloat MRInteractiveProgressValue = 0.5;
const CGFloat MRFinalProgressValue = 0.9;

@implementation MRWebViewProgress {
    
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _maxLoadCount = _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

- (void)startProgress {
    
    if (_progress < MRInitialProgressValue) {
        
        [self setProgress:MRInitialProgressValue];
    }
}

- (void)incrementProgress {
    
    CGFloat progress = self.progress;
    CGFloat maxProgress = _interactive ? MRFinalProgressValue : MRInteractiveProgressValue;
    CGFloat remainPercent = (CGFloat)_loadingCount / (CGFloat)_maxLoadCount;
    CGFloat increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress {
    
    [self setProgress:1.0f];
}

- (void)setProgress:(CGFloat)progress {
    
    // progress should be incremental only
    if (progress > progress || progress == 0) {
        
        _progress = progress;
        if ([_progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [_progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (_progressBlock) {
            _progressBlock(progress);
        }
    }
}

- (void)reset {
    
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0];
}

- (NSString *)getNonFragmentStringWithURL:(NSURL *)url {
    
    if (!url) {
        return @"";
    }
    if (url.fragment) {
        return [url.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:url.fragment] withString:@""];
    }
    else {
        return url.absoluteString;
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([request.URL.absoluteString isEqualToString:MRCompleteRPCURL]) {
        [self completeProgress];
        return NO;
    }
    BOOL ret = YES;
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        ret = [_webViewProxyDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [self getNonFragmentStringWithURL:request.URL];
        NSString *mainFragmentURL = [self getNonFragmentStringWithURL:webView.request.URL];
        isFragmentJump = [nonFragmentURL isEqualToString:mainFragmentURL];
    }
    NSString *refererURL = [request valueForHTTPHeaderField:@"Referer"];
    BOOL isTopLevelNavigation = (refererURL.length == 0 || [refererURL isEqualToString:request.URL.absoluteString] || [request.mainDocumentURL isEqual:request.URL]);
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    BOOL shouldReset = ret && !isFragmentJump && isHTTP && isTopLevelNavigation;
    shouldReset |= (navigationType == UIWebViewNavigationTypeReload);
    if (shouldReset) {
        _currentURL = request.URL;
        [self reset];
    }
    return ret;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    if ([_webViewProxyDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_webViewProxyDelegate webViewDidStartLoad:webView];
    }
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);
    [self startProgress];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    if ([_webViewProxyDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_webViewProxyDelegate webViewDidFinishLoad:webView];
    }
    _loadingCount--;
    [self incrementProgress];
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", MRCompleteRPCURL];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    BOOL isNotRedirect = YES; {
        
        NSString *nonFragmentCurrentURL = [self getNonFragmentStringWithURL:_currentURL];
        NSString *nonFragmentMainDocumentURL = [self getNonFragmentStringWithURL:webView.request.mainDocumentURL];
        isNotRedirect = (_currentURL && [nonFragmentCurrentURL isEqualToString:nonFragmentMainDocumentURL]);
    }
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_webViewProxyDelegate webView:webView didFailLoadWithError:error];
    }
    _loadingCount--;
    [self incrementProgress];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", MRCompleteRPCURL];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    BOOL isNotRedirect = YES; {
        
        NSString *nonFragmentCurrentURL = [self getNonFragmentStringWithURL:_currentURL];
        NSString *nonFragmentMainDocumentURL = [self getNonFragmentStringWithURL:webView.request.mainDocumentURL];
        isNotRedirect = (_currentURL && [nonFragmentCurrentURL isEqualToString:nonFragmentMainDocumentURL]);
    }
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

#pragma mark - 
#pragma mark Method Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.webViewProxyDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        if ([_webViewProxyDelegate respondsToSelector:aSelector]) {
            return [(NSObject *)_webViewProxyDelegate methodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    if ([_webViewProxyDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_webViewProxyDelegate];
    }
}

@end
