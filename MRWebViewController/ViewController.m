//
//  ViewController.m
//  MRWebViewController
//
//  Created by Yaw on 15/3/17.
//  Copyright © 2017 Yaw. All rights reserved.
//

#import "ViewController.h"
#import "MRWebView.h"

@interface ViewController () <MRWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet MRWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    if (_webView.usingUIWebView) {
        self.title = @"UIWebView";
    }
    else {
        self.title = @"MKWebView";
    }
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://test.loopslive.com/web-loops/title/dist/?userId=191236&token=708ba754290c70a7ca4c9e82cc89c744&lang=en&sig=1d857b0c7a9bcec92f7df58744bb7ecd"]]];
    _webView.delegate = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(MRWebView *)webView {
    
    NSLog(@"webViewDidStartLoad canGoForward %@", webView.canGoForward ? @"YES": @"NO");
    NSLog(@"webViewDidStartLoad canGoBack %@", webView.canGoBack ? @"YES": @"NO");
    self.progressView.progress = 0;
}

- (void)webViewDidFinishLoad:(MRWebView *)webView {
    
    NSLog(@"webViewDidFinishLoad canGoForward %@", webView.canGoForward ? @"YES": @"NO");
    NSLog(@"webViewDidFinishLoad canGoBack %@", webView.canGoBack ? @"YES": @"NO");
    self.progressView.progress = 0;
}

- (void)webView:(MRWebView *)webView didFailLoadWithError:(NSError *)error {
    
    NSLog(@"didFailLoadWithError %@", error);
    self.progressView.progress = 0;
}

- (BOOL)webView:(MRWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSLog(@"webView:%@ request:%@ navigationType: %ld", webView, request, (long)navigationType);
    }
    NSLog(@"shouldStartLoadWithRequest canGoForward %@", webView.canGoForward ? @"YES": @"NO");
    NSLog(@"shouldStartLoadWithRequest canGoBack %@", webView.canGoBack ? @"YES": @"NO");
    self.progressView.hidden = NO;
    return YES;
}

- (void)webView:(MRWebView *)webView updateProgress:(CGFloat)progress {
    
    self.progressView.progress = progress;
}

@end
