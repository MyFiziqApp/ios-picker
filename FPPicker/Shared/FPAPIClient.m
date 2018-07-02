//
//  FPAPIClient.m
//  FPPicker
//
//  Created by Ruben Nine on 18/06/14.
//  Copyright (c) 2014 Filepicker.io. All rights reserved.
//

#import "FPAPIClient.h"
#import "FPConfig.h"

// MFZ DEV: alias classes
@implementation AFHTTPRequestOperationManager
@end
@implementation AFHTTPRequestOperation
@end

@implementation FPAPIClient

+ (instancetype)sharedClient
{
    static FPAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedClient = [[FPAPIClient alloc] initWithBaseURL:[FPConfig sharedInstance].baseURL];
        _sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _sharedClient.responseSerializer = [AFJSONResponseSerializer serializer];
        _sharedClient.operationQueue.maxConcurrentOperationCount = 5;
    });

    return _sharedClient;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
             usingOperationQueue:(NSOperationQueue *)operationQueue
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString *fullPath = [self.baseURL.absoluteString stringByAppendingString:URLString];
    NSURL *url = [NSURL URLWithString:fullPath];
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:url];

    mRequest.HTTPMethod = @"POST";

    NSError *error;
    NSURLRequest *serializedRequest = [[AFHTTPRequestSerializer serializer] requestBySerializingRequest:mRequest
                                                                                         withParameters:parameters
                                                                                                  error:&error];

    if (error)
    {
        FPLogError(@"Error serializing request: %@: %@", serializedRequest, error);

        return nil;
    }

    // MFZ DEV: 'HTTPRequestOperationWithRequest:' has been removed, now need to call the request directly.
    __block AFHTTPRequestOperation * _Nonnull operation = (AFHTTPRequestOperation *)[super dataTaskWithRequest:mRequest
                                                                               uploadProgress:nil
                                                                             downloadProgress:nil
                                                                            completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                                                if (error && failure) {
                                                                                    failure(operation, error);
                                                                                } else if (!error && success) {
                                                                                    success(operation, responseObject);
                                                                                }
                                                                            }];
    [operation resume];
    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
       constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
             usingOperationQueue:(NSOperationQueue *)operationQueue
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];

    if (serializationError)
    {
        if (failure)
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ? : dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }

        return nil;
    }

    // MFZ DEV: 'HTTPRequestOperationWithRequest:' has been removed, now need to call the request directly.
    __block AFHTTPRequestOperation * _Nonnull operation = (AFHTTPRequestOperation *)[super dataTaskWithRequest:request
                                                                                                uploadProgress:nil
                                                                                              downloadProgress:nil
                                                                                             completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                                                                 if (error && failure) {
                                                                                                     failure(operation, error);
                                                                                                 } else if (!error && success) {
                                                                                                     success(operation, responseObject);
                                                                                                 }
                                                                                             }];
    [operation resume];
    return operation;
}

@end
