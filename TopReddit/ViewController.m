//
//  ViewController.m
//  TopReddit
//
//  Created by Tracey Eubanks on 11/13/13.
//  Copyright (c) 2013 Tracey Eubanks. All rights reserved.
//

#import "ViewController.h"
#import "RedditParse.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    _redditAPIParser = [[RedditParse alloc] init];
    _redditAPIParser.delegate = self;
//    [_redditAPIParser loginWithUsername:kRedditUsername andPassword:kRedditPassword];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"alerted");
}
// --------- RedditParseLoginProtocol methods --------- //
-(void)didLogin {

}

-(void)didReceiveError:(NSDictionary *)errorInfo {
    UIAlertView *loginErrorAlert = [[UIAlertView alloc] initWithTitle:@"Error Logging In" message:[errorInfo objectForKey:@"errorMessage"] delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [self.view addSubview:loginErrorAlert];
    [loginErrorAlert show];
}
@end
