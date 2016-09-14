//
//  DTDrone.h
//  parrot_demo
//
//  Created by cyborgninja on 2016/09/13.
//  Copyright © 2016年 松本隆. All rights reserved.
//

// #import <Foundation/Foundation.h>

#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>
#import <libARController/ARCONTROLLER_Device.h>

#pragma mark - interface
@interface DTDrone : NSObject {
}

#pragma mark - properties
@property (nonatomic) ARCONTROLLER_Device_t *deviceController;
@property (nonatomic, assign) uint8_t batteryLevel;
@property (nonatomic) dispatch_semaphore_t stateSem;

#pragma mark - class method
+ (DTDrone *)sharedInstance;

#pragma mark - public api
/**
 * connect drone
 * @param service ARService
 * @return success or failure BOOL
 **/
- (BOOL)connectWithService:(ARService *)service;

/**
 * disconnect drone
 **/
- (void)disconnect;

- (void)emergency;
- (void)takeoff;
- (void)land;
- (void)flip;

@end