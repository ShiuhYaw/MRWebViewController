//
//  ViewController.m
//  MRWebViewController
//
//  Created by Yaw on 15/3/17.
//  Copyright © 2017 Yaw. All rights reserved.
//

#import "ViewController.h"
#import "MRWebView.h"

@interface ViewController ()
@property (strong, nonatomic) MRWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.webView = [[MRWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    if (_webView.usingUIWebView) {
        self.title = @"UIWebView";
    }
    else {
        self.title = @"MKWebView";
    }
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://loopslive.com/?userId=191236&token=4e4b93a301415a53cd9af911bb53d38f&lang=en&sig=37077857f976e9680679b843c56ac673"]]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
