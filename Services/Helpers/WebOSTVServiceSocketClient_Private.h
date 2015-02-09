//
//  WebOSTVServiceSocketClient_Private.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2/6/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "WebOSTVServiceSocketClient.h"

@class LGSRWebSocket;

@interface WebOSTVServiceSocketClient ()

/// Creates a new websocket instance with the given request.
- (LGSRWebSocket *)createSocketWithURLRequest:(NSURLRequest *)request;

- (NSDictionary *) manifest;

@end
