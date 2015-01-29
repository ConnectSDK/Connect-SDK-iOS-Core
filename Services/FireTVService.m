//
//  FireTVService.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/26/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "FireTVService.h"
#import "DIALService.h"
#import "DiscoveryManager.h"

#import "GCDAsyncSocket.h"
#import "LGSRWebSocket.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

NSString *const kConnectSDKFireTVServiceId = @"FireTV";



typedef void(^ReadDataBlock)(NSData *data);

@interface TCPServer : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, copy) ReadDataBlock readDataBlock;

@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) NSMutableData *readData;

- (void)listenOnPort:(uint16_t)port;

@end

@implementation TCPServer

- (void)listenOnPort:(uint16_t)port {
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                   delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    NSError *error = nil;
    if (![self.serverSocket acceptOnPort:port error:&error]) {
        NSLog(@"Failed to open socket %@", error);
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"didAcceptNewSocket: %@", newSocket);
    newSocket.delegate = self;
    self.readData = [NSMutableData dataWithCapacity:4096];
    [newSocket readDataWithTimeout:5 tag:42];
    self.clientSocket = newSocket;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"didReadData: %@ %ld", data, tag);
    [self.readData appendData:data];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socketDidDisconnect: %@ %@", sock, err);

    NSAssert(self.readDataBlock, @"No read data block");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.readDataBlock([self.readData copy]);
        self.readData = nil;
    });

    self.clientSocket = nil;
    self.serverSocket.delegate = nil;
    self.serverSocket = nil;
}

- (void)dealloc {
    NSLog(@"dealloc %@", self);
}

@end




@interface FireTVService () <LGSRWebSocketDelegate>

/// The DIAL service of this FireTV.
@property (nonatomic, strong) DIALService *dialService;

/// The LaunchSession of the web app that was run most recently.
@property (nonatomic, strong) LaunchSession *webAppLaunchSession;

/// The current WebSocket connection to the web app.
@property (nonatomic, strong) LGSRWebSocket *webSocket;

@end


@implementation FireTVService

#pragma mark - Discovery

+ (DiscoveryFilter *) discoveryParameters
{
    return [DiscoveryFilter filterWithServiceId:kConnectSDKFireTVServiceId
                                         filter:@"urn:dial-multiscreen-org:service:dial:1"
                               requiredServices:nil
                       andModelNameMatcherBlock:^BOOL(NSString *modelName) {
                           return (NSNotFound != [modelName rangeOfString:@"FireTV"].location);
                       }];
}

#pragma mark - Capabilities

- (void)updateCapabilities {
    NSArray *capabilities = @[kWebAppLauncherLaunch,
                              kWebAppLauncherClose];
    self.capabilities = capabilities;
}

#pragma mark - WebAppLauncher

- (id<WebAppLauncher>)webAppLauncher {
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority {
    return CapabilityPriorityLevelNormal;
}

- (void)launchWebApp:(NSString *)webAppId
             success:(WebAppLaunchSuccessBlock)success
             failure:(FailureBlock)failure {
    [self launchWebApp:webAppId
                params:nil
               success:success
               failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId
              params:(NSDictionary *)params
             success:(WebAppLaunchSuccessBlock)success
             failure:(FailureBlock)failure {
    __block TCPServer *server = [TCPServer new];
    [server listenOnPort:33345];
    server.readDataBlock = ^(NSData *readData) {
        NSLog(@"Got data %@", [[NSString alloc] initWithData:readData
                                                    encoding:NSUTF8StringEncoding]);
        NSError *error = nil;
        NSDictionary *object = [NSJSONSerialization JSONObjectWithData:readData
                                                               options:0
                                                                 error:&error];
        NSAssert(object, @"Error %@", error);

        self.webSocket = [[LGSRWebSocket alloc] initWithURL:[NSURL URLWithString:object[@"url"]]];
        [self.webSocket open];
        self.webSocket.delegate = self;

        server = nil;
    };

    AppInfo *appInfo = [AppInfo appInfoForId:@"com.connectsdk.firetvcontainer"];
    NSDictionary *appParams = @{@"action": @"SendPort",
                                @"hostname": [self getIPAddress],
                                @"port": @33345};

    __weak typeof(self) wSelf = self;
    [self.dialService launchAppWithInfo:appInfo
                                 params:appParams
                                success:^(LaunchSession *launchSession) {
                                    NSLog(@"Launch app success => %@", launchSession);
                                    typeof(self) sSelf = wSelf;
                                    sSelf.webAppLaunchSession = launchSession;
                                } failure:^(NSError *error) {
                                    NSLog(@"Launch app failure => %@", error);
                                }];
}
/*
- (void)launchWebApp:(NSString *)webAppId
   relaunchIfRunning:(BOOL)relaunchIfRunning
             success:(WebAppLaunchSuccessBlock)success
             failure:(FailureBlock)failure {

}

- (void)launchWebApp:(NSString *)webAppId
              params:(NSDictionary *)params
   relaunchIfRunning:(BOOL)relaunchIfRunning
             success:(WebAppLaunchSuccessBlock)success
             failure:(FailureBlock)failure {

}

- (void)joinWebApp:(LaunchSession *)webAppLaunchSession
           success:(WebAppLaunchSuccessBlock)success
           failure:(FailureBlock)failure {

}

- (void)joinWebAppWithId:(NSString *)webAppId
                 success:(WebAppLaunchSuccessBlock)success
                 failure:(FailureBlock)failure {

}
*/
- (void)closeWebApp:(LaunchSession *)launchSession
            success:(SuccessBlock)success
            failure:(FailureBlock)failure {
    if (self.webAppLaunchSession) {
        [self.dialService closeApp:self.webAppLaunchSession
                           success:^(id responseObject) {
                               NSLog(@"Close app success => %@", responseObject);
                           } failure:^(NSError *error) {
                               NSLog(@"Close app failure => %@", error);
                           }];
        self.webAppLaunchSession = nil;
        self.webSocket = nil;
    }
}

#pragma mark - LGSRWebSocketDelegate

- (void)webSocketDidOpen:(LGSRWebSocket *)webSocket {
    NSLog(@"websocket connection open");

    [webSocket send:@"test from iOS 21#%!^@%#^$^%#^@#$^^U%&^*(%*(%^$*%&$%^@#$%!$#@"];
}

- (void)webSocket:(LGSRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"websocket didFail %@", error);
}

- (void)webSocket:(LGSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"websocket close %ld %@", (long)code, reason);
}

- (void)webSocket:(LGSRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"message %@", message);
}

#pragma mark - Helpers

- (DIALService *)dialService {
    // FIXME: remove the duplication with NetcastTVService
    if (!_dialService) {
        DiscoveryManager *discoveryManager = [DiscoveryManager sharedManager];
        ConnectableDevice *device = [discoveryManager.allDevices objectForKey:self.serviceDescription.address];

        if (device) {
            NSPredicate *dialServicePredicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@",
                                                 [DIALService class]];
            _dialService = [device.services filteredArrayUsingPredicate:dialServicePredicate].firstObject;
            NSAssert(_dialService, @"No DIAL in this FireTV?!");
        }
    }

    return _dialService;
}

// FIXME duplication from DLNAHTTPServer
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
