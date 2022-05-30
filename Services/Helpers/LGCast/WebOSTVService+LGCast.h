//
//  WebOSTVService+LGCast.h
//  LGCast
//
//  Copyright (c) 2022 LG Electronics. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ConnectSDK.h"
#import "WebOSTVService.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebOSTVService (LGCast)
- (ServiceSubscription *)subscribeCommandWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribePowerStateWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendConnect:(NSString*)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendGetParameter:(NSString*)service sucess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendSetParameter:(NSDictionary *)sourceInfo service:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendSetParameter:(NSDictionary *)sourceInfo service:(NSString *)service deviceSpec:(NSDictionary *)deviceInfo success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendGetParameterResponse:(NSDictionary *)parameter service:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendSetParameterResponse:(NSDictionary *)parameter service:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendKeepAliveWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendTeardown:(NSString*)service success:(SuccessBlock)success;

@end

NS_ASSUME_NONNULL_END
