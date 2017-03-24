//
//  MRWebView.m
//  MRWebViewController
//
//  Created by Yaw on 17/3/17.
//  Copyright © 2017 Yaw. All rights reserved.
//

#import "MRWebView.h"
#import "MRWebViewProgress.h"
#import <TargetConditionals.h>
#import <WebKit/WebKit.h>
#import <dlfcn.h>

@interface MRWebView () <UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate, MRWebViewProgressDelegate>

@property (assign, nonatomic) double estimatedProgress;
@property (strong, nonatomic) NSURLRequest *originRequest;
@property (strong, nonatomic) NSURLRequest *currentRequest;
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) MRWebViewProgress *webViewProgress;

@end

@implementation MRWebView

@synthesize usingUIWebView = _usingUIWebView;
@synthesize realWebView = _realWebView;
@synthesize scalesPageToFit = _scalesPageToFit;
@synthesize allowsInlineMediaPlayback = _allowsInlineMediaPlayback;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initMyself];
    }
    return self;
}

- (instancetype)init {
    
    return [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    return [self initWithFrame:frame usingUIWebView:NO];
}

- (instancetype)initWithFrame:(CGRect)frame usingUIWebView:(BOOL)usingUIWebView {
    
    self = [super initWithFrame:frame];
    if (self) {
        _usingUIWebView = usingUIWebView;
        [self initMyself];
    }
    return self;
}

- (void)initMyself {
    
    Class wkWebView = NSClassFromString(@"WKWebView");
    if (wkWebView && self.usingUIWebView == NO) {
        [self initWKWebView];
        _usingUIWebView = NO;
    }
    else {
        [self initUIWebView];
        _usingUIWebView = YES;
    }
    [self.realWebView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    self.scalesPageToFit = YES;
    [self.realWebView setFrame:self.bounds];
    [self.realWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self addSubview:self.realWebView];
}

- (void)setDelegate:(id<MRWebViewDelegate>)delegate {
    
    _delegate = delegate;
    if (_usingUIWebView) {
        UIWebView* webView = self.realWebView;
        webView.delegate = nil;
        webView.delegate = self;
    }
    else {
        WKWebView* webView = self.realWebView;
        webView.UIDelegate = nil;
        webView.navigationDelegate = nil;
        webView.UIDelegate = self;
        webView.navigationDelegate = self;
    }
}

- (void)initWKWebView {
    
    WKWebViewConfiguration* configuration = [[NSClassFromString(@"WKWebViewConfiguration") alloc] init];
    configuration.userContentController = [NSClassFromString(@"WKUserContentController") new];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = NO;
    WKPreferences* preferences = [NSClassFromString(@"WKPreferences") new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    
    WKWebView* webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.bounds configuration:configuration];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    _realWebView = webView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.estimatedProgress = [change[NSKeyValueChangeNewKey] doubleValue];
        [self callbackWebViewUpdateProgress:[change[NSKeyValueChangeNewKey] doubleValue]];
    }
    else if ([keyPath isEqualToString:@"title"]) {
        self.title = change[NSKeyValueChangeNewKey];
    }
    else {
        [self willChangeValueForKey:keyPath];
        [self didChangeValueForKey:keyPath];
    }
}


- (void)initUIWebView {
    
    UIWebView *webView = [[UIWebView alloc]initWithFrame:self.bounds];
    webView.backgroundColor = [UIColor clearColor];
    webView.allowsInlineMediaPlayback = YES;
    webView.mediaPlaybackRequiresUserAction = NO;
    webView.opaque = NO;
    for (UIView *subView in [webView.scrollView subviews]) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)subView).image = nil;
            subView.backgroundColor = [UIColor clearColor];
        }
    }
    self.webViewProgress = [[MRWebViewProgress alloc] init];
    webView.delegate = _webViewProgress;
    _webViewProgress.webViewProxyDelegate = self;
    _webViewProgress.progressDelegate = self;
    _realWebView = webView;
}

- (void)addScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name {
    
    if (!_usingUIWebView) {
        WKWebViewConfiguration* configuration = [(WKWebView*)self.realWebView configuration];
        [configuration.userContentController addScriptMessageHandler:scriptMessageHandler name:name];
    }
}

- (JSContext *)jsContext {
    
    if (_usingUIWebView) {
        return [(UIWebView*)self.realWebView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    }
    else {
        return nil;
    }
}

#pragma mark - 
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (self.originRequest == nil) {
        self.originRequest = webView.request;
    }
    [self callbackWebViewDidFinishLoad];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    [self callbackWebViewDidStartLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [self callbackWebViewDidFailLoadWithError:error];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    BOOL resultBOOL = [self callbackWebViewShouldStartLoadWithRequest:request navigationType:navigationType];
    return resultBOOL;
}

- (void)webViewProgress:(MRWebViewProgress *)webViewProgress updateProgress:(CGFloat)progress {
    
    self.estimatedProgress = progress;
    [self callbackWebViewUpdateProgress:progress];
}

#pragma mark - 
#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    BOOL resultBOOL = [self callbackWebViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
    BOOL isLoadingDisableScheme = [self isLoadingWKWebViewDisableScheme:navigationAction.request.URL];
    
    if (resultBOOL && !isLoadingDisableScheme) {
        self.currentRequest = navigationAction.request;
        if (navigationAction.targetFrame == nil) {
            [webView loadRequest:navigationAction.request];
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
    [self callbackWebViewDidStartLoad];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    [self callbackWebViewDidFinishLoad];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    [self callbackWebViewDidFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    [self callbackWebViewDidFailLoadWithError:error];
}

#pragma mark - 
#pragma mark CallBack MRWebView Delegate
- (void)callbackWebViewDidFinishLoad {

    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinishLoad:self];
    }
}

- (void)callbackWebViewDidStartLoad {
    
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:self];
    }
}

- (void)callbackWebViewDidFailLoadWithError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

- (BOOL)callbackWebViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType {
    
    BOOL resultBOOL = YES;
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        if (navigationType == -1) {
            navigationType = UIWebViewNavigationTypeOther;
        }
        resultBOOL = [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return resultBOOL;
}

- (void)callbackWebViewUpdateProgress:(CGFloat)progress {
    
    if ([self.delegate respondsToSelector:@selector(webView:updateProgress:)]) {
        [self.delegate webView:self updateProgress:progress];
    }
}
#pragma mark -

- (BOOL)isLoadingWKWebViewDisableScheme:(NSURL *)url {
    
    BOOL retValue = NO;
    
    if ([url.scheme isEqualToString:@"tel"] || [url.host isEqualToString:@"itunes.apple.com"] ) {
        UIApplication* app = [UIApplication sharedApplication];
        
        if ([app canOpenURL:url]) {
            if ([app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                [app openURL:url options:@{} completionHandler:^(BOOL success) {
                }];
            } else {
                BOOL success = [app openURL:url];
            }
            retValue = YES;
        }
    }
    return retValue;
}

- (UIScrollView *)scrollView {
    
    return [(id)self.realWebView scrollView];
}

- (id)loadRequest:(NSURLRequest *)request {
    
    self.originRequest = request;
    self.currentRequest = request;
    
    if (_usingUIWebView) {
        [(UIWebView*)self.realWebView loadRequest:request];
        return nil;
    }
    else {
        return [(WKWebView*)self.realWebView loadRequest:request];
    }
}

- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    
    if (_usingUIWebView) {
        [(UIWebView*)self.realWebView loadHTMLString:string baseURL:baseURL];
        return nil;
    }
    else {
        return [(WKWebView*)self.realWebView loadHTMLString:string baseURL:baseURL];
    }
}

- (NSURLRequest *)currentRequest {
    
    if (_usingUIWebView) {
        return [(UIWebView*)self.realWebView request];
    }
    else {
        return _currentRequest;
    }
}

- (NSURL *)URL {
    
    if (_usingUIWebView) {
        return [(UIWebView*)self.realWebView request].URL;
    }
    else {
        return [(WKWebView*)self.realWebView URL];
    }
}

- (BOOL)isLoading {
    
    return [self.realWebView isLoading];
}

- (BOOL)canGoBack {
    
    return [self.realWebView canGoBack];
}

- (BOOL)canGoForward {
    
    return [self.realWebView canGoForward];
}

- (id)goBack {
    
    if (_usingUIWebView) {
        [(UIWebView*)self.realWebView goBack];
        return nil;
    }
    else {
        return [(WKWebView*)self.realWebView goBack];
    }
}

- (id)goForward {
    
    if (_usingUIWebView) {
        [(UIWebView*)self.realWebView goForward];
        return nil;
    }
    else {
        return [(WKWebView*)self.realWebView goForward];
    }
}

- (id)reload {
    
    if (_usingUIWebView) {
        [(UIWebView*)self.realWebView reload];
        return nil;
    }
    else {
        return [(WKWebView*)self.realWebView reload];
    }
}

- (id)reloadFromOrigin {
    
    if (_usingUIWebView) {
        if (self.originRequest) {
            [self evaluateJavaScript:[NSString stringWithFormat:@"window.location.replace('%@')", self.originRequest.URL.absoluteString] completionHandler:nil];
        }
        return nil;
    }
    else {
        return [(WKWebView*)self.realWebView reloadFromOrigin];
    }
}

- (void)stopLoading {
    
    [self.realWebView stopLoading];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    
    if (_usingUIWebView) {
        NSString* result = [(UIWebView*)self.realWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        if (completionHandler) {
            completionHandler(result, nil);
        }
    }
    else {
        return [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    }
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString {
    
    if (_usingUIWebView) {
        NSString* result = [(UIWebView*)self.realWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        return result;
    }
    else {
        __block NSString* result = nil;
        __block BOOL isExecuted = NO;
        [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:^(id obj, NSError* error) {
            result = obj;
            isExecuted = YES;
        }];
        
        while (isExecuted == NO) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        return result;
    }
}

- (void)setScalesPageToFit:(BOOL)scalesPageToFit {
    
    if (_usingUIWebView) {
        UIWebView* webView = _realWebView;
        webView.scalesPageToFit = scalesPageToFit;
    }
    else {
        if (_scalesPageToFit == scalesPageToFit) {
            return;
        }
        
        WKWebView* webView = _realWebView;
        
        NSString* jScript =
        @"var head = document.getElementsByTagName('head')[0];\
        var hasViewPort = 0;\
        var metas = head.getElementsByTagName('meta');\
        for (var i = metas.length; i>=0 ; i--) {\
        var m = metas[i];\
        if (m.name == 'viewport') {\
        hasViewPort = 1;\
        break;\
        }\
        }; \
        if(hasViewPort == 0) { \
        var meta = document.createElement('meta'); \
        meta.name = 'viewport'; \
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
        head.appendChild(meta);\
        }";
        
        WKUserContentController *userContentController = webView.configuration.userContentController;
        NSMutableArray<WKUserScript *> *array = [userContentController.userScripts mutableCopy];
        WKUserScript* fitWKUScript = nil;
        for (WKUserScript* wkUScript in array) {
            if ([wkUScript.source isEqual:jScript]) {
                fitWKUScript = wkUScript;
                break;
            }
        }
        if (scalesPageToFit) {
            if (!fitWKUScript) {
                fitWKUScript = [[NSClassFromString(@"WKUserScript") alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
                [userContentController addUserScript:fitWKUScript];
            }
        }
        else {
            if (fitWKUScript) {
                [array removeObject:fitWKUScript];
            }
            [userContentController removeAllUserScripts];
            for (WKUserScript* wkUScript in array) {
                [userContentController addUserScript:wkUScript];
            }
        }
    }
    _scalesPageToFit = scalesPageToFit;
}

- (BOOL)scalesPageToFit {
    
    if (_usingUIWebView) {
        return [_realWebView scalesPageToFit];
    }
    else {
        return _scalesPageToFit;
    }
}

- (void)setAllowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback {
    
    if (_usingUIWebView) {
        UIWebView* webView = _realWebView;
        webView.allowsInlineMediaPlayback = allowsInlineMediaPlayback;
    }
    else {
        if (_allowsInlineMediaPlayback == allowsInlineMediaPlayback) {
            return;
        }
        
        WKWebView* webView = _realWebView;
        WKWebViewConfiguration *webViewConfiguration = webView.configuration;
        webViewConfiguration.allowsInlineMediaPlayback = allowsInlineMediaPlayback;
    }
    _allowsInlineMediaPlayback = allowsInlineMediaPlayback;
}

- (BOOL)allowsInlineMediaPlayback {
    
    return _allowsInlineMediaPlayback;
}

- (NSInteger)countOfHistory {
    
    if (_usingUIWebView) {
        UIWebView* webView = self.realWebView;
        
        int count = [[webView stringByEvaluatingJavaScriptFromString:@"window.history.length"] intValue];
        if (count) {
            return count;
        }
        else {
            return 1;
        }
    }
    else {
        WKWebView* webView = self.realWebView;
        return webView.backForwardList.backList.count;
    }
}

- (void)goBackWithStep:(NSInteger)step {
    
    if (self.canGoBack == NO)
        return;
    
    if (step > 0) {
        NSInteger historyCount = self.countOfHistory;
        if (step >= historyCount) {
            step = historyCount - 1;
        }
        if (_usingUIWebView) {
            UIWebView* webView = self.realWebView;
            [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.history.go(-%ld)", (long)step]];
        }
        else {
            WKWebView* webView = self.realWebView;
            WKBackForwardListItem* backItem = webView.backForwardList.backList[step];
            [webView goToBackForwardListItem:backItem];
        }
    }
    else {
        [self goBack];
    }
}

#pragma mark - 
#pragma mark Selector
- (BOOL)respondsToSelector:(SEL)aSelector {
    
    BOOL hasResponds = [super respondsToSelector:aSelector];
    if (hasResponds == NO) {
        hasResponds = [self.delegate respondsToSelector:aSelector];
    }
    if (hasResponds == NO) {
        hasResponds = [self.realWebView respondsToSelector:aSelector];
    }
    return hasResponds;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    NSMethodSignature* methodSign = [super methodSignatureForSelector:aSelector];
    if (methodSign == nil) {
        if ([self.realWebView respondsToSelector:aSelector]) {
            methodSign = [self.realWebView methodSignatureForSelector:aSelector];
        }
        else {
            methodSign = [(id)self.delegate methodSignatureForSelector:aSelector];
        }
    }
    return methodSign;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    if ([self.realWebView respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.realWebView];
    }
    else {
        [anInvocation invokeWithTarget:self.delegate];
    }
}

- (void)dealloc {
    
    if (_usingUIWebView) {
        UIWebView* webView = _realWebView;
        webView.delegate = nil;
    }
    else {
        WKWebView* webView = _realWebView;
        webView.UIDelegate = nil;
        webView.navigationDelegate = nil;
        [webView removeObserver:self forKeyPath:@"estimatedProgress"];
        [webView removeObserver:self forKeyPath:@"title"];
    }
    [_realWebView removeObserver:self forKeyPath:@"loading"];
    [_realWebView scrollView].delegate = nil;
    [_realWebView stopLoading];
    [(UIWebView*)_realWebView loadHTMLString:@"" baseURL:nil];
    [_realWebView stopLoading];
    [_realWebView removeFromSuperview];
    _realWebView = nil;
}

@end
