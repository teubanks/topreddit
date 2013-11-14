//
//  ViewController.h
//  TopReddit
//
//  Created by Tracey Eubanks on 11/13/13.
//  Copyright (c) 2013 Tracey Eubanks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditParse.h"

@interface ViewController : UIViewController <RedditParseLoginProtocol, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageDisplay;
@property (weak, nonatomic) IBOutlet UILabel *pictureTitle;
@property (weak, nonatomic) IBOutlet UIButton *voteUpButton;
@property (weak, nonatomic) IBOutlet UIButton *voteDownButton;

@property (strong, nonatomic) RedditParse *redditAPIParser;
@property (strong, nonatomic) NSString *imageId;

- (IBAction)voteUp:(id)sender;
- (IBAction)voteDown:(id)sender;
@end
