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
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://loopslive.com/?userId=191236&token=4e4b93a301415a53cd9af911bb53d38f&lang=en&sig=37077857f976e9680679b843c56ac673"]]];
    _webView.delegate = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(MRWebView *)webView {
    
    self.progressView.progress = 0;
}

- (void)webViewDidFinishLoad:(MRWebView *)webView {
    
    self.progressView.progress = 0;
}

- (void)webView:(MRWebView *)webView didFailLoadWithError:(NSError *)error {
    
    self.progressView.progress = 0;
}

- (BOOL)webView:(MRWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSLog(@"webView:%@ request:%@ navigationType: %ld", webView, request, (long)navigationType);
    }
    self.progressView.hidden = NO;
    return YES;
}

- (void)webView:(MRWebView *)webView updateProgress:(CGFloat)progress {
    
    self.progressView.progress = progress;
}

@end
