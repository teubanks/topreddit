//
//  RedditParse.m
//  TopReddit
//
//  Created by Tracey Eubanks on 11/13/13.
//  Copyright (c) 2013 Tracey Eubanks. All rights reserved.
//

#import "RedditParse.h"

const NSString *kRedditAPIURL = @"http://api.reddit.com";

// Log into www.reddit.com using these credentials and navigate to the
// /r/funny url to see the results of your up/down voting on
// the website itself
NSString *kRedditUsername = @"youmakemydaybrighter";
NSString *kRedditPassword = @"singularity";

@interface RedditParse()
-(void)castVote:(VoteDirection)voteDirection forObjectWithId:(NSString*)objectId;
@end

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
    NSString *modHashFilePath = [NSTemporaryDirectory() stringByAppendingString:@"modhash.trh"];
    NSError *modHashReadError = nil;
    _modhash = [NSString stringWithContentsOfFile:modHashFilePath encoding:NSUTF8StringEncoding error:&modHashReadError];
    if([_modhash length] != 0){
        // we have a modhash. just return
        [self.delegate didLogin];
        return;
    }

    NSString *loginBodyString = [NSString stringWithFormat:@"api_type=json&rem=on&user=%@&passwd=%@",
                                            [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                            [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSData *loginData = [loginBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLRequest *loginRequest = [self postURLRequestForEndpoint:@"login" withData:loginData];

    [NSURLConnection sendAsynchronousRequest:loginRequest queue:_apiRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError){
            [self.delegate didReceiveError:[connectionError userInfo]];
            return;
        }

        NSError *error = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error){
            [self.delegate didReceiveError:[error userInfo]];
            return;
        }

        responseDictionary = [responseDictionary objectForKey:@"json"]; // remove json key, don't need it
        if([[responseDictionary objectForKey:@"errors"] count] > 0){
            NSArray *loginErrors = [[responseDictionary objectForKey:@"errors"] objectAtIndex:0];
            NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
            [errorInfo setValue:[loginErrors objectAtIndex:0] forKey:@"errorConstant"];
            [errorInfo setValue:[loginErrors objectAtIndex:1] forKey:@"errorMessage"];
            [self.delegate didReceiveError:errorInfo];
            return;
        }

        // Modhash is something used by Reddit to protect against CSRF
        _modhash = [[responseDictionary objectForKey:@"data"] objectForKey:@"modhash"];
        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"modhash"] URLByAppendingPathExtension:@"trh"];
        NSData *modHashData = [_modhash dataUsingEncoding:NSUTF8StringEncoding];
        [modHashData writeToURL:fileURL atomically:YES];
        [self.delegate didLogin];
    }];
}

-(void)fetchImageData {
    NSURL *funnyImagesURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/r/funny.json", kRedditAPIURL]];
    NSMutableURLRequest *fetchImagesRequest = [[NSMutableURLRequest alloc] initWithURL:funnyImagesURL];
    [fetchImagesRequest setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:fetchImagesRequest queue:_apiRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSError *jsonSerializationError = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonSerializationError];
        if(jsonSerializationError){
            NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
            [errorInfo setValue:@"Unknown Response for Image Fetch" forKey:@"errorMessage"];
            [self.delegate didReceiveError:errorInfo];
            return;
        }

        responseDict = [responseDict objectForKey:@"data"];
        NSArray *imagesArray = [responseDict objectForKey:@"children"];
        [imagesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *childInfo = [obj objectForKey:@"data"];
            if([[childInfo objectForKey:@"over_18"] boolValue] == YES){
                return; // skip NSFW content, shouldn't be any in the funny subreddit; this is just in case
            }

            NSURL *imageURL = [NSURL URLWithString:[childInfo objectForKey:@"url"]];
            if(![[imageURL pathExtension] isEqualToString:@"jpg"]){
                return; // skip non jpg content
            }

            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *fetchedImage = [UIImage imageWithData:imageData];
            [self.delegate loadImage:fetchedImage];
            [self.delegate setImageTitle:[childInfo objectForKey:@"title"]];
            [self.delegate setImageId:[childInfo objectForKey:@"name"]];
            *stop = YES; // got our image. Let's end it
        }];

    }];
}

-(void)upVoteObjectWithId:(NSString *)objectID {
    [self castVote:kVoteUp forObjectWithId:objectID];
}

-(void)downVoteObjectWithId:(NSString *)objectID {
    [self castVote:kVoteDown forObjectWithId:objectID];
}

-(void)castVote:(VoteDirection)voteDirection forObjectWithId:(NSString *)objectId {
    NSString *voteBodyString = [NSString stringWithFormat:@"api_type=json&dir=%i&id=%@", voteDirection, [objectId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSData *voteData = [voteBodyString dataUsingEncoding:NSUTF8StringEncoding];

    NSURLRequest *voteURLRequest = [self postURLRequestForEndpoint:@"vote" withData:voteData];

    [NSURLConnection sendAsynchronousRequest:voteURLRequest queue:_apiRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError){
            [self.delegate didReceiveError:[connectionError userInfo]];
            return;
        }

        NSError *error = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error){
            [self.delegate didReceiveError:[error userInfo]];
            return;
        }

        responseDictionary = [responseDictionary objectForKey:@"json"];
        NSArray *voteErrors = [[responseDictionary objectForKey:@"errors"] objectAtIndex:0];
        if([voteErrors count] > 0) {
            NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
            [errorInfo setValue:[voteErrors objectAtIndex:0] forKey:@"errorConstant"];
            [errorInfo setValue:[voteErrors objectAtIndex:1] forKey:@"errorMessage"];
            [self.delegate didReceiveError:errorInfo];
            return;
        }
    }];
}

// Method to dry up url requests for post method
-(NSURLRequest*)postURLRequestForEndpoint:(NSString*)endpoint withData:(NSData*)bodyData {
    NSString *loginURLString = [NSString stringWithFormat:@"%@/api/%@", kRedditAPIURL, endpoint];
    NSURL *loginURL = [NSURL URLWithString:loginURLString];
    NSMutableURLRequest *mutableLoginRequest = [[NSMutableURLRequest alloc] initWithURL:loginURL];
    [mutableLoginRequest setHTTPMethod:@"POST"];
    [mutableLoginRequest setValue:[NSString stringWithFormat:@"%d", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
    [mutableLoginRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    if(self.modhash)
        [mutableLoginRequest setValue:self.modhash forHTTPHeaderField:@"X-Modhash"];

    [mutableLoginRequest setHTTPBody:bodyData];
    return mutableLoginRequest;
}
@end
