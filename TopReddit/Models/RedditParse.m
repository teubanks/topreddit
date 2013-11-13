//
//  RedditParse.m
//  TopReddit
//
//  Created by Tracey Eubanks on 11/13/13.
//  Copyright (c) 2013 Tracey Eubanks. All rights reserved.
//

#import "RedditParse.h"

const NSString *kRedditAPIURL = @"http://api.reddit.com";
NSString *kRedditUsername = @"youmakemydaybrighter";
NSString *kRedditPassword = @"singularity";

@implementation RedditParse
-(id)init{
    self = [super init];
    if(self){
        _apiRequestQueue = [[NSOperationQueue alloc] init];
        [_apiRequestQueue setMaxConcurrentOperationCount:3];

    }
    return self;
}

-(void)loginWithUsername:(NSString *)username andPassword:(NSString *)password {
    NSString *loginBodyString = [NSString stringWithFormat:@"api_type=json&rem=false&username=%@&passwd=%@", username, password];
    NSData *loginData = [loginBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *loginURLString = [NSString stringWithFormat:@"%@/api/login", kRedditAPIURL];
    NSURL *loginURL = [NSURL URLWithString:loginURLString];
    NSMutableURLRequest *mutableLoginRequest = [[NSMutableURLRequest alloc] initWithURL:loginURL];
    [mutableLoginRequest setHTTPMethod:@"POST"];
    [mutableLoginRequest setHTTPBody:loginData];
    
    [NSURLConnection sendAsynchronousRequest:mutableLoginRequest queue:_apiRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError)
            [self.delegate didReceiveError:[connectionError userInfo]];

        NSError *error = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        responseDictionary = [responseDictionary objectForKey:@"json"]; // remove json key, don't need it
        if(error)
            [self.delegate didReceiveError:[error userInfo]];

        NSArray *loginErrors = [[responseDictionary objectForKey:@"errors"] objectAtIndex:0];
        if([loginErrors count] > 0) {
            NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
            [errorInfo setValue:[loginErrors objectAtIndex:0] forKey:@"errorConstant"];
            [errorInfo setValue:[loginErrors objectAtIndex:1] forKey:@"errorMessage"];
            [errorInfo setValue:[loginErrors objectAtIndex:2] forKey:@"eckifino"];
            [self.delegate didReceiveError:errorInfo];
        }
    }];
}

-(UIImage *)firstImage {

}
@end
