//
//  DLNAHTTPServer.m
//  Connect SDK
//
//  Created by Jeremy White on 9/30/14.
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

#import <ifaddrs.h>
#import <arpa/inet.h>
#import "DLNAHTTPServer.h"
#import "DLNAService.h"
#import "CTXMLReader.h"
#import "GCDWebServerDataRequest.h"


@implementation DLNAHTTPServer
{
    DLNAService *_service;
    NSMutableArray *_subscriptions;
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _server = [[GCDWebServer alloc] init];
        _server.delegate = self;

        GCDWebServerResponse *(^webServerResponseBlock)(GCDWebServerRequest *request) = ^GCDWebServerResponse *(GCDWebServerRequest *request) {
            [self processRequest:(GCDWebServerDataRequest *)request];
            return [GCDWebServerResponse responseWithStatusCode:204];
        };

        [self.server addDefaultHandlerForMethod:@"NOTIFY"
                                   requestClass:[GCDWebServerDataRequest class]
                                   processBlock:webServerResponseBlock];
    }

    return self;
}

- (instancetype) initWithService:(DLNAService *)service
{
    self = [self init];

    if (self)
    {
        _service = service;
    }

    return self;
}

- (BOOL) isRunning
{
    return _server.isRunning;
}

- (void) start
{
    [self.server startWithPort:_service.serviceDescription.port bonjourName:nil];
}

- (void) stop
{
    [self.server stop];
}

- (void) addSubscription:(ServiceSubscription *)subscription
{

}

- (void) removeSubscription:(ServiceSubscription *)subscription
{

}

- (NSArray *) subscriptions
{
    return [NSArray arrayWithArray:_subscriptions];
}

- (void) processRequest:(GCDWebServerDataRequest *)request
{
    if (!request.data || request.data.length == 0)
        return;

    NSError *xmlParseError;
    NSDictionary *requestDataXML = [CTXMLReader dictionaryForXMLData:request.data error:&xmlParseError];

    if (xmlParseError)
    {
        DLog(@"XML Parse error %@", xmlParseError.description);
        return;
    }


}

#pragma mark - GCDWebServerDelegate

- (void) webServerDidStart:(GCDWebServer *)server
{
    _subscriptions = [NSMutableArray new];
}

- (void) webServerDidStop:(GCDWebServer *)server
{
}

#pragma mark - Utility

- (NSString *)getHostPath
{
    return [NSString stringWithFormat:@"http://%@:%d/", [self getIPAddress], _service.serviceDescription.port];
}

-(NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Get NSString from C String
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
