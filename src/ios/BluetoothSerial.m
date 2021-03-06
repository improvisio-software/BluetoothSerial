//
//  BluetoothSerial.m
//  EADemo
//
//  Created by Matěj Kříž on 27.01.15.
//
//

#import "BluetoothSerial.h"
#import <Cordova/CDV.h>

@implementation BluetoothSerial


- (void)connect:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    NSString *deviceID = [command.arguments objectAtIndex:0];

    if (!_eaSessionController){
        _eaSessionController = [EADSessionController sharedController];
    }

    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];

    EAAccessory *accessory = nil;
    for (EAAccessory *obj in accessories) {
        if ([obj connectionID] == [deviceID integerValue]){
            accessory = obj;
            break;
        }
    }

    bool result = [_eaSessionController openSession:accessory];

    NSMutableDictionary *deviceDictionary = [[NSMutableDictionary alloc] init];

    [deviceDictionary setObject:accessory.name forKey:@"name"];
    [deviceDictionary setObject:[NSString stringWithFormat:@"%@",  @(accessory.connectionID)] forKey:@"id"];


    if(result){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:deviceDictionary];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device could not connect!"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)disconnect:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    [self removeSubscription];
    [_eaSessionController closeSession];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Device disconnected!"];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(NSMutableArray*)getList
{
    if (!_eaSessionController){
        _eaSessionController = [EADSessionController sharedController];
    }

    _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    NSLog(@"_accessoryList %@", _accessoryList);

    NSMutableArray *accessoryDictionary = [[NSMutableArray alloc] init];
    for (EAAccessory *device in _accessoryList) {
        if ([[device protocolStrings] containsObject:@"com.RovingNetworks.btdemo"]) {
            NSMutableDictionary *tmpDic=[[NSMutableDictionary alloc] init];
            [tmpDic setObject:device.name forKey:@"name"];
            [tmpDic setObject:[NSString stringWithFormat:@"%@",  @(device.connectionID)] forKey:@"id"];

            [accessoryDictionary addObject:tmpDic];
        }
    }
    return accessoryDictionary;
}

- (void)list:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[self getList]];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)connectIOS:(CDVInvokedUrlCommand*)command
{
    if (!_eaSessionController){
        _eaSessionController = [EADSessionController sharedController];
    }

    [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:^(NSError *error) {
        [self.commandDelegate runInBackground:^{
            CDVPluginResult* pluginResult = nil;
            if(error != nil && [error code] == EABluetoothAccessoryPickerResultCancelled) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
            } else {
                // connectedAccessories need some time to load protocolStrings properly
                usleep(3500000);
                NSMutableArray *accessoryDictionary  = [self getList];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:accessoryDictionary];

            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}

- (void)isEnabled:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    if (!_eaSessionController){
        _eaSessionController = [EADSessionController sharedController];
    }

    bool isEnabled = _eaSessionController?true:false;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isEnabled];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isConnected:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    if (!_eaSessionController){
        _eaSessionController = [EADSessionController sharedController];
    }

    bool connected = [_eaSessionController.session.accessory isConnected];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:connected];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)available:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    NSString* available = [NSString stringWithFormat: @"%lu", (unsigned long)[_eaSessionController readBytesAvailable]];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:available];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)read:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    NSData *data = [[NSData alloc] init];
    unsigned long bytesAvailable = 0;
    while ((bytesAvailable = [_eaSessionController readBytesAvailable]) > 0) {
        data = [_eaSessionController readData:bytesAvailable];
    }

    unsigned char *buffer;
    buffer = (unsigned char*)[data bytes];
    [data getBytes:buffer length:[data length]];

    NSString* message = [NSString stringWithFormat: @"%s", (char *)buffer];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)readUntil:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"ReadUntil not implemented yet!"];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)write:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Write not implemented yet!"];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribe:(CDVInvokedUrlCommand*)command
{
    NSString *delimiter = [command.arguments objectAtIndex:0];

    if (delimiter == nil) {
        delimiter = @"\n";
    }

    _subscribeCallbackId = [command.callbackId copy];
    _delimiter = [delimiter copy];

    [_eaSessionController setDelimiter:delimiter];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    _dataReceivedObserver = [center addObserverForName:@"EADSessionDataReceivedNotification" object:nil
                                                     queue:mainQueue usingBlock:^(NSNotification *note) {
                                                         [self sendDataToSubscriber];
                                                     }];
}


- (NSString*)readUntilDelimiter: (NSString*) delimiter {

    NSData *data = [[NSData alloc] init];
    unsigned long bytesAvailable = 0;
    if ((bytesAvailable = [_eaSessionController readBytesAvailable]) > 0) {
        data = [_eaSessionController readData:bytesAvailable];
    }

    unsigned char *buffer;
    buffer = (unsigned char*)[data bytes];
    [data getBytes:buffer length:[data length]];
    NSString* _buffer = [NSString stringWithFormat: @"%s", (char *)buffer];

    NSRange range = [_buffer rangeOfString: delimiter];
    NSString *message = @"";

    if (range.location != NSNotFound) {

        int end = range.location + range.length;
        message = [_buffer substringToIndex:end];
    }
    return message;
}

- (void) sendDataToSubscriber {

    NSString *message = [self readUntilDelimiter:_delimiter];

    if ([message length] > 0) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: message];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_subscribeCallbackId];

        [self sendDataToSubscriber];
    }

}

- (void) removeSubscription {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:_dataReceivedObserver];
}

- (void)unsubscribe:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    [self removeSubscription];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Unsubscribed!"];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clear:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    [_eaSessionController clearData];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Data cleared!"];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
