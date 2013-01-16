//
//  OCWatchingVideoViewController.m
//  OnCourse
//
//  Created by admin on 12/10/12.
//  Copyright (c) 2012 phatle. All rights reserved.
//

#import "OCWatchingVideoViewController.h"
#import "OCWatchingVideo.h"
#import "OCJavascriptFunctions.h"
#import "OCUtility.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Lecture+CoreData.h"
#import "MBProgressHUD.h"

@interface OCWatchingVideoViewController ()

@property (nonatomic, strong) OCWatchingVideo *watchingVideoView;
@property (nonatomic, strong) NSString *videoDirectLink;
@property (nonatomic, strong) Lecture *currentLecture;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIWebView *webviewPlayer;

@end

@implementation OCWatchingVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithLecture:(Lecture *)lecture
{
    self = [super init];
    if (self) {
        self.webviewPlayer = [[UIWebView alloc] init];
        self.webviewPlayer.delegate = self;
        self.currentLecture = lecture;
        self.watchingVideoView = [OCWatchingVideo new];
        self.moviePlayer = self.watchingVideoView.moviePlayer;
        if (lecture.directVideoLink) {
            self.videoDirectLink = self.currentLecture.directVideoLink;
            [self playVideo];
        }
        else
        {
            [self loadRequest:self.currentLecture.link];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
    return self;
}

- (void)loadRequest:(NSString *)videoLink
{
    [self.webviewPlayer loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:videoLink]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view = self.watchingVideoView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
}

- (void)MPMoviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if ((self.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK) == MPMovieLoadStatePlaythroughOK) {
        //add your code
        NSLog(@"Played video");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *requestString = [[request URL] absoluteString];
    
    NSLog(@"request : %@",requestString);
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        
        NSString *function = (NSString*)[components objectAtIndex:1];
        if ([@"pageLoaded" isEqualToString:function])
        {
            NSLog(@"Getting direct video link");
            [self checkDirectLink];
        }
        else if ([@"haveDirectLink" isEqualToString:function])
        {
            self.videoDirectLink = [self getDirectLink];
            self.currentLecture.directVideoLink = self.videoDirectLink;
            [self playVideo];
            self.webviewPlayer = nil;
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
        return NO;
    }
    
    return YES;
}

- (void)checkDirectLink
{
    [self.webviewPlayer stringByEvaluatingJavaScriptFromString:[OCJavascriptFunctions jsPlayLectureVideo]];
}

- (NSString *)getDirectLink
{
    return [self.webviewPlayer stringByEvaluatingJavaScriptFromString:[OCJavascriptFunctions jsGetDirectLink]];
}

- (void)playVideo
{
    NSURL *url = [NSURL URLWithString:self.videoDirectLink];
    [self.moviePlayer setContentURL:url];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
}

- (void)stopVideo
{
    [self.moviePlayer stop];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.webviewPlayer stringByEvaluatingJavaScriptFromString:[OCJavascriptFunctions jsCallObjectiveCFunction]];
    [self.webviewPlayer stringByEvaluatingJavaScriptFromString:[OCJavascriptFunctions checkPageLoaded]];
}
@end
