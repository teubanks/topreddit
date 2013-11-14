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
    UIAlertView *loginErrorAlert = [[UIAlertView alloc] initWithTitle:@"Error Logging In" message:[errorInfo objectForKey:@"errorMessage"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [self.view addSubview:loginErrorAlert];
    [loginErrorAlert show];
}

-(void)loadImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageDisplay setImage:image];
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
- (IBAction)voteUp:(id)sender {
    [self.redditAPIParser downVoteObjectWithId:self.imageId];
}

- (IBAction)voteDown:(id)sender {
    [self.redditAPIParser upVoteObjectWithId:self.imageId];
}
@end
