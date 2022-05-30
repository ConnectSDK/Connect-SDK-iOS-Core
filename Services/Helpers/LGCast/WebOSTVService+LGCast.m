//
//  WebOSTVService+LGCast.m
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

#import "WebOSTVService+LGCast.h"
#import "ServiceAsyncCommand.h"
#import "WebOSTVServiceSocketClient.h"

@implementation WebOSTVService (LGCast)
- (ServiceSubscription *)subscribeCommandWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/getCommand"];
    NSDictionary *payload = @{ @"subscribe" : @YES };

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:success failure:failure];

    return subscription;
}

- (ServiceSubscription *)subscribePowerStateWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tvpower/power/getPowerState"];
    NSDictionary *payload = @{ @"subscribe" : @YES };

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:success failure:failure];
    
    return subscription;
}

- (void)sendConnect:(NSString*)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"CONNECT",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        @"service" : service
    };

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void)sendGetParameter:(NSString*)service sucess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"GET_PARAMETER",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        @"service" : service
    };

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void)sendSetParameter:(NSDictionary *)sourceInfo service:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"SET_PARAMETER",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        service : sourceInfo
    };

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void)sendSetParameter:(NSDictionary *)sourceInfo service:(NSString *)service deviceSpec:(NSDictionary *)deviceInfo success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"SET_PARAMETER",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        service : sourceInfo,
        @"deviceInfo" : deviceInfo
    };
    
    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
 
    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void)sendGetParameterResponse:(NSDictionary *)parameter service:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"GET_PARAMETER_RESPONSE",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        service : parameter
    };
    
    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}


- (void)sendSetParameterResponse:(NSDictionary *)parameter service:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"SET_PARAMETER_RESPONSE",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        service : parameter
    };
    
    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void)sendKeepAliveWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"KEEPALIVE",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey]
    };
    
    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    
    command.callbackComplete = success;
    command.callbackError = failure;
    
    [command send];
}

- (void)sendTeardown:(NSString*)service success:(SuccessBlock)success {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *payload = @{
        @"cmd" : @"TEARDOWN",
        @"clientKey" : [[self webOSTVServiceConfig] clientKey],
        @"service" : service
    };
    
    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = ^(NSDictionary *responseDic) {
//        Log_info(@"response is %@", responseDic);
        if (success)
            success(nil);
    };

    command.callbackError = ^(NSError *error) {
//        Log_info(@"error is %@", error.localizedDescription);
        if (success)
            success(nil);
    };

    [command send];
}

@end
