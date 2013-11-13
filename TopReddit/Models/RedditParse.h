//
//  RedditParse.h
//  TopReddit
//
//  Created by Tracey Eubanks on 11/13/13.
//  Copyright (c) 2013 Tracey Eubanks. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *kRedditAPIURL;
extern NSString *kRedditUsername;
extern NSString *kRedditPassword;

@protocol RedditParseLoginProtocol <NSObject>

@required
-(void)didLogin;
-(void)didReceiveError:(NSDictionary*)errorInfo;

@end

@interface RedditParse : NSObject
@property (strong, nonatomic) NSString *modhash; // reddit header for authentication
@property (strong, nonatomic) NSOperationQueue *apiRequestQueue;
@property (weak, nonatomic) id delegate;

-(UIImage*)firstImage;
-(void)upVote;
-(void)downVote;

-(void)loginWithUsername:(NSString*)username andPassword:(NSString*)password;

@end
