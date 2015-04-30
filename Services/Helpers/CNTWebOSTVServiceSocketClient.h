//
//  CNTWebOSTVServiceSocketClient.h
//  Connect SDK
//
//  Created by Jeremy White on 6/19/14.
//  Copyright (c) 2014 LG Electronics.
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

#import <Foundation/Foundation.h>
#import "CNTServiceCommandDelegate.h"
#import "CNTServiceCommand.h"
#import "LGSRWebSocket.h"

@class CNTWebOSTVService;
@protocol WebOSTVServiceSocketClientDelegate;


@interface CNTWebOSTVServiceSocketClient : NSObject <CNTServiceCommandDelegate, LGSRWebSocketDelegate>

- (instancetype) initWithService:(CNTWebOSTVService *)service;

- (void) connect;
- (void) disconnect;
- (void) disconnectWithError:(NSError *)error;

- (CNTServiceSubscription *) addSubscribe:(NSURL *)URL payload:(NSDictionary *)payload success:(SuccessBlock)success failure:(FailureBlock)failure;
- (CNTServiceSubscription *) killSubscribe:(NSURL *)URL payload:(NSDictionary *)payload;

- (void) sendDictionaryOverSocket:(NSDictionary *)payload;
- (void) sendStringOverSocket:(NSString *)payload;

@property (nonatomic) id<WebOSTVServiceSocketClientDelegate> delegate;
@property (nonatomic) CNTWebOSTVService *service;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) LGSRWebSocket *socket;
@property (nonatomic, readonly) NSDictionary *activeConnections;
@property (nonatomic, readonly) NSArray *commandQueue;

@end

@protocol WebOSTVServiceSocketClientDelegate <NSObject>

- (void) socketDidConnect:(CNTWebOSTVServiceSocketClient *)socket;
- (void) socket:(CNTWebOSTVServiceSocketClient *)socket didCloseWithError:(NSError *)error;
- (void) socket:(CNTWebOSTVServiceSocketClient *)socket didFailWithError:(NSError *)error;

@optional
// TODO : Deprecate this method and rename this to more meaningful one probably socketWillRequirePairingWithPairingType:
- (void) socketWillRegister:(CNTWebOSTVServiceSocketClient *)socket;
- (void) socket:(CNTWebOSTVServiceSocketClient *)socket registrationFailed:(NSError *)error;
- (BOOL) socket:(CNTWebOSTVServiceSocketClient *)socket didReceiveMessage:(NSDictionary *)message;

@end
