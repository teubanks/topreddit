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
    [_redditAPIParser loginWithUsername:kRedditUsername andPassword:kRedditPassword];

    _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _loadingIndicator.center = self.view.center;
    [_loadingIndicator startAnimating];
    [self.view addSubview:_loadingIndicator];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// --------- RedditParseLoginProtocol methods --------- //
-(void)didLogin {
    [self.redditAPIParser fetchImageData];
}

-(void)didReceiveError:(NSDictionary *)errorInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *loginErrorAlert = [[UIAlertView alloc] initWithTitle:@"Error Logging In" message:[errorInfo objectForKey:@"errorMessage"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [self.view addSubview:loginErrorAlert];
        [loginErrorAlert show];
    });
}

-(void)loadImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageDisplay setImage:image];
        [self.loadingIndicator removeFromSuperview];
        [self.voteDownButton setEnabled:YES];
        [self.voteUpButton setEnabled:YES];
    });
}

-(void)setImageTitle:(NSString *)imageTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:imageTitle attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
        CGFloat width = 300.0f;
        CGRect labelBounds = [titleString boundingRectWithSize:CGSizeMake(width, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
        [self.pictureTitle setBounds:labelBounds];
        [self.pictureTitle setText:imageTitle];
    });
}

// --------- IB Actions ---------  //
// In a real world, these button backgrounds would be set after we recieve a 200 OK response
// indicating that our up/down vote was successful. It'd also be set upon login, showing that
// we've already voted one way or the other, but I'm out of time
- (IBAction)voteUp:(id)sender {
    [self.redditAPIParser upVoteObjectWithId:self.imageId];
    [self.voteDownButton setBackgroundColor:[UIColor clearColor]];
    [self.voteUpButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.25]];
}

- (IBAction)voteDown:(id)sender {
    [self.redditAPIParser downVoteObjectWithId:self.imageId];
    [self.voteUpButton setBackgroundColor:[UIColor clearColor]];
    [self.voteDownButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.25]];
}
@end
