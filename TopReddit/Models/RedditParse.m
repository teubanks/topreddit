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
    if(![modHashFilePath length] == 0){
        NSError *modHashReadError = nil;
        _modhash = [NSString stringWithContentsOfFile:modHashFilePath encoding:NSUTF8StringEncoding error:&modHashReadError];
        // we have a modhash. just return
        [self.delegate didLogin];
        return;
    }

    return; // always return for now

    NSString *loginBodyString = [NSString stringWithFormat:@"api_type=json&rem=true&username=%@&passwd=%@", username, password];
    NSData *loginData = [loginBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *loginURLString = [NSString stringWithFormat:@"%@/api/login", kRedditAPIURL];
    NSURL *loginURL = [NSURL URLWithString:loginURLString];
    NSMutableURLRequest *mutableLoginRequest = [[NSMutableURLRequest alloc] initWithURL:loginURL];
    [mutableLoginRequest setHTTPMethod:@"POST"];
    [mutableLoginRequest setValue:[NSString stringWithFormat:@"%d", [loginData length]] forHTTPHeaderField:@"Content-Length"];
    [mutableLoginRequest setValue:@"application/x-www-form-urlencoded charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [mutableLoginRequest setHTTPBody:loginData];

    [NSURLConnection sendAsynchronousRequest:mutableLoginRequest queue:_apiRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError){
            [self.delegate didReceiveError:[connectionError userInfo]];
            return;
        }

        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);

        NSError *error = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error){
            [self.delegate didReceiveError:[error userInfo]];
            return;
        }

        responseDictionary = [responseDictionary objectForKey:@"json"]; // remove json key, don't need it
        NSArray *loginErrors = [[responseDictionary objectForKey:@"errors"] objectAtIndex:0];
        if([loginErrors count] > 0) {
            NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
            [errorInfo setValue:[loginErrors objectAtIndex:0] forKey:@"errorConstant"];
            [errorInfo setValue:[loginErrors objectAtIndex:1] forKey:@"errorMessage"];
            [errorInfo setValue:[loginErrors objectAtIndex:2] forKey:@"eckifino"];
            [self.delegate didReceiveError:errorInfo];
            return;
        }
        _modhash = [[responseDictionary objectForKey:@"data"] objectForKey:@"modhash"];
        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"modhash"] URLByAppendingPathExtension:@"trh"];
        NSData *modHashData = [_modhash dataUsingEncoding:NSUTF8StringEncoding];
        [modHashData writeToURL:fileURL atomically:YES];
        [self.delegate didLogin];
    }];
}

-(void)fetchImageData {
    NSURL *funnyImagesURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/r/funny", kRedditAPIURL]];
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
            [self.delegate setImageId:[childInfo objectForKey:@"id"]];
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
    NSString *loginBodyString = [NSString stringWithFormat:@"dir=%i&id=%@", voteDirection, objectId];
    NSData *loginData = [loginBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *loginURLString = [NSString stringWithFormat:@"%@/api/vote", kRedditAPIURL];
    NSURL *loginURL = [NSURL URLWithString:loginURLString];
    NSMutableURLRequest *mutableLoginRequest = [[NSMutableURLRequest alloc] initWithURL:loginURL];
    [mutableLoginRequest setHTTPMethod:@"POST"];
    [mutableLoginRequest setValue:[NSString stringWithFormat:@"%d", [loginData length]] forHTTPHeaderField:@"Content-Length"];
    [mutableLoginRequest setValue:@"application/x-www-form-urlencoded charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [mutableLoginRequest setValue:self.modhash forHTTPHeaderField:@"X-Modhash"];
    [mutableLoginRequest setHTTPBody:loginData];

    [NSURLConnection sendAsynchronousRequest:mutableLoginRequest queue:_apiRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError){
            [self.delegate didReceiveError:[connectionError userInfo]];
            return;
        }

        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);

        NSError *error = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error){
            [self.delegate didReceiveError:[error userInfo]];
            return;
        }

        responseDictionary = [responseDictionary objectForKey:@"json"]; // remove json key, don't need it
        NSArray *loginErrors = [[responseDictionary objectForKey:@"errors"] objectAtIndex:0];
        if([loginErrors count] > 0) {
            NSMutableDictionary *errorInfo = [[NSMutableDictionary alloc] init];
            [errorInfo setValue:[loginErrors objectAtIndex:0] forKey:@"errorConstant"];
            [errorInfo setValue:[loginErrors objectAtIndex:1] forKey:@"errorMessage"];
            [errorInfo setValue:[loginErrors objectAtIndex:2] forKey:@"eckifino"];
            [self.delegate didReceiveError:errorInfo];
            return;
        }
    }];
}
@end
