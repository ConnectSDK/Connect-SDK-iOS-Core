//
//  ConnectSDK.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
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

#import "DiscoveryManager.h"
#import "DiscoveryManagerDelegate.h"
#import "DiscoveryProviderDelegate.h"

#import "ConnectableDevice.h"
#import "ConnectableDeviceDelegate.h"

#import "DevicePicker.h"
#import "DevicePickerDelegate.h"

#import "ServiceAsyncCommand.h"
#import "ServiceCommand.h"
#import "ServiceCommandDelegate.h"
#import "ServiceSubscription.h"

#import "CapabilityFilter.h"
#import "ExternalInputControl.h"
#import "KeyControl.h"
#import "TextInputControl.h"
#import "Launcher.h"
#import "MediaControl.h"
#import "PlayListControl.h"
#import "MediaPlayer.h"
#import "MouseControl.h"
#import "PowerControl.h"
#import "SubtitleInfo.h"
#import "ToastControl.h"
#import "TVControl.h"
#import "VolumeControl.h"
#import "WebAppLauncher.h"

#import "AppInfo.h"
#import "ChannelInfo.h"
#import "ExternalInputInfo.h"
#import "ImageInfo.h"
#import "MediaInfo.h"
#import "TextInputStatusInfo.h"
#import "ProgramInfo.h"
#import "LaunchSession.h"
#import "WebAppSession.h"

#import "AirPlayService.h"
#import "AirPlayServiceHTTPKeepAlive.h"
#import "AirPlayWebAppSession.h"
#import "AppStateChangeNotifier.h"
#import "BlockRunner.h"
#import "CastDiscoveryProvider.h"
#import "CastService.h"
//#import "CastServiceChannel.h"
#import "CastWebAppSession.h"
#import "CommonMacros.h"
#import "ConnectError.h"
#import "ConnectSDKDefaultPlatforms.h"
#import "ConnectUtil.h"
//#import "CTASIAuthenticationDialog.h"
//#import "CTASICacheDelegate.h"
//#import "CTASIDataCompressor.h"
//#import "CTASIDataDecompressor.h"
//#import "CTASIDownloadCache.h"
//#import "CTASIFormDataRequest.h"
//#import "CTASIHTTPRequest.h"
//#import "CTASIHTTPRequestConfig.h"
//#import "CTASIHTTPRequestDelegate.h"
//#import "CTASIInputStream.h"
//#import "CTASINetworkQueue.h"
//#import "CTASIProgressDelegate.h"
#import "CTGuid.h"
#import "CTReachability.h"
#import "CTXMLReader.h"
#import "DefaultConnectableDeviceStore.h"
#import "DeviceServiceReachability.h"
#import "DIALService.h"
#import "DiscoveryProvider.h"
#import "DispatchQueueBlockRunner.h"
#import "DLNAHTTPServer.h"
#import "DLNAService.h"
//#import "FireTVCapabilityMixin.h"
#import "FireTVDiscoveryProvider.h"
//#import "FireTVMediaControl.h"
//#import "FireTVMediaPlayer.h"
#import "FireTVService.h"
#import "GCDWebServer.h"
#import "GCDWebServerConnection.h"
#import "GCDWebServerDataRequest.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"
#import "GCDWebServerFileRequest.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerFunctions.h"
#import "GCDWebServerHTTPStatusCodes.h"
#import "GCDWebServerMultiPartFormRequest.h"
#import "GCDWebServerPrivate.h"
#import "GCDWebServerRequest.h"
#import "GCDWebServerResponse.h"
#import "GCDWebServerStreamedResponse.h"
#import "GCDWebServerURLEncodedFormRequest.h"
#import "LGSRWebSocket.h"
#import "NetcastTVService.h"
#import "NetcastTVServiceConfig.h"
#import "NSDictionary+KeyPredicateSearch.h"
#import "NSMutableDictionary+NilSafe.h"
#import "NSString+Common.h"
#import "RokuService.h"
#import "SSDPDiscoveryProvider.h"
#import "SSDPSocketListener.h"
#import "SubscriptionDeduplicator.h"
#import "SynchronousBlockRunner.h"
#import "WebOSTVService.h"
#import "WebOSTVServiceConfig.h"
#import "WebOSTVServiceMouse.h"
#import "WebOSTVServiceSocketClient.h"
#import "WebOSWebAppSession.h"
#import "XMLWriter+ConvenienceMethods.h"
#import "XMLWriter.h"
#import "ZeroConfDiscoveryProvider.h"

@interface ConnectSDK : NSObject

@end
