//
//  DTDrone.m
//  parrot_demo
//
//  Created by cyborgninja on 2016/09/13.
//  Copyright © 2016年 松本隆. All rights reserved.
//

#import "DTDrone.h"
#import <libARDiscovery/ARDiscovery.h>
#import <libARController/ARController.h>

#pragma mark - functions
void stateChanged(eARCONTROLLER_DEVICE_STATE newState, eARCONTROLLER_ERROR error, void *customData)
{
  DTDrone *drone = (__bridge DTDrone *)customData;
  if (drone == nil) { return; }
  
  switch (newState) {
    case ARCONTROLLER_DEVICE_STATE_RUNNING:
      break;
    case ARCONTROLLER_DEVICE_STATE_STOPPED:
      dispatch_semaphore_signal(drone.stateSem);
      //dispatch_async(dispatch_get_main_queue(), ^{
      //});
      break;
    case ARCONTROLLER_DEVICE_STATE_STARTING:
      break;
    case ARCONTROLLER_DEVICE_STATE_STOPPING:
      break;
    default:
      break;
  }
}

void onCommandReceived (eARCONTROLLER_DICTIONARY_KEY commandKey, ARCONTROLLER_DICTIONARY_ELEMENT_t *elementDictionary, void *customData)
{
  DTDrone *drone = (__bridge DTDrone *)customData;
  if (drone == nil) { return; }
  
  if ((commandKey == ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_BATTERYSTATECHANGED) && (elementDictionary != NULL)) {
    ARCONTROLLER_DICTIONARY_ARG_t *arg = NULL;
    ARCONTROLLER_DICTIONARY_ELEMENT_t *element = NULL;
    
    HASH_FIND_STR (elementDictionary, ARCONTROLLER_DICTIONARY_SINGLE_KEY, element);
    if (element != NULL) {
      HASH_FIND_STR (element->arguments, ARCONTROLLER_DICTIONARY_KEY_COMMON_COMMONSTATE_BATTERYSTATECHANGED_PERCENT, arg);
      if (arg != NULL) { [drone setBatteryLevel:arg->value.U8]; }
    }
  }
}


#pragma mark - implementation
@implementation DTDrone


#pragma mark - class method
+ (DTDrone *)sharedInstance
{
  static DTDrone *drone  = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^ {
    drone = [[DTDrone alloc] init];
  });
  return drone;
}


#pragma mark - initializer


#pragma mark - destruction
- (void)dealloc
{
}


#pragma mark - public api
- (BOOL)connectWithService:(ARService *)service
{
  self.batteryLevel = 100;
  self.stateSem = dispatch_semaphore_create(0);
  
  ARDISCOVERY_Device_t *discoveryDevice = [self createDiscoveryDeviceWithService:service];
  if (discoveryDevice != NULL) {
    eARCONTROLLER_ERROR error = ARCONTROLLER_OK;
    self.deviceController = ARCONTROLLER_Device_New(discoveryDevice, &error);
    
    if (error == ARCONTROLLER_OK) {
      error = ARCONTROLLER_Device_AddStateChangedCallback(_deviceController, stateChanged, (__bridge void *)(self));
    }
    if (error == ARCONTROLLER_OK) {
      error = ARCONTROLLER_Device_AddCommandReceivedCallback(_deviceController, onCommandReceived, (__bridge void *)(self));
    }
    if (error == ARCONTROLLER_OK) {
      error = ARCONTROLLER_Device_Start(_deviceController);
    }
    
    ARDISCOVERY_Device_Delete (&discoveryDevice);
    if (error != ARCONTROLLER_OK) {
      if (_deviceController != NULL) { ARCONTROLLER_Device_Delete(&_deviceController); }
      self.deviceController = NULL;
      return FALSE;
    }
  }
  else { return FALSE; }
  return TRUE;
}

- (void)disconnect
{
  eARCONTROLLER_ERROR error = ARCONTROLLER_OK;
  eARCONTROLLER_DEVICE_STATE state = ARCONTROLLER_Device_GetState(_deviceController, &error);
  if ((error == ARCONTROLLER_OK) && (state != ARCONTROLLER_DEVICE_STATE_STOPPED)) {
    error = ARCONTROLLER_Device_Stop(_deviceController);
    if (error == ARCONTROLLER_OK) { dispatch_semaphore_wait(self.stateSem, DISPATCH_TIME_FOREVER); }
  }
  if (_deviceController != NULL) { ARCONTROLLER_Device_Delete(&_deviceController); }
  self.deviceController = NULL;
}

- (void)emergency
{
  __block __unsafe_unretained typeof(self) bself = self;
  dispatch_async(dispatch_get_main_queue(), ^ () {
    bself.deviceController->miniDrone->sendPilotingEmergency(bself.deviceController->miniDrone);
    
    
  });
}

- (void)takeoff
{
  __block __unsafe_unretained typeof(self) bself = self;
  dispatch_async(dispatch_get_main_queue(), ^ () {
    bself.deviceController->miniDrone->sendPilotingTakeOff(bself.deviceController->miniDrone);
  });
}

- (void)land
{
  __block __unsafe_unretained typeof(self) bself = self;
  dispatch_async(dispatch_get_main_queue(), ^ () {
    bself.deviceController->miniDrone->sendPilotingLanding(bself.deviceController->miniDrone);
  });
}

- (void)flip
{
  __block __unsafe_unretained typeof(self) bself = self;
  dispatch_async(dispatch_get_main_queue(), ^ () {
    bself.deviceController->miniDrone->sendAnimationsFlip(bself.deviceController->miniDrone,
                                                          ARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION_LEFT);
  });
  
  
  /*
   public enum eARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION {
   ARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION_FRONT = 0,
   ARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION_BACK,
   ARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION_RIGHT,
   ARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION_LEFT,
   ARCOMMANDS_MINIDRONE_ANIMATIONS_FLIP_DIRECTION_MAX
   }
   */
  
}



#pragma mark - private api
/**
 * create drone device
 * @param service ARService
 * @return drone device
 **/
- (ARDISCOVERY_Device_t *)createDiscoveryDeviceWithService:(ARService *)service
{
  ARDISCOVERY_Device_t *device = NULL;
  eARDISCOVERY_ERROR errorDiscovery = ARDISCOVERY_OK;
  device = ARDISCOVERY_Device_New (&errorDiscovery);
  if (errorDiscovery == ARDISCOVERY_OK) {
    ARBLEService *bleService = service.service;
    errorDiscovery = ARDISCOVERY_Device_InitBLE (device, ARDISCOVERY_PRODUCT_MINIDRONE, (__bridge ARNETWORKAL_BLEDeviceManager_t)(bleService.centralManager), (__bridge ARNETWORKAL_BLEDevice_t)(bleService.peripheral));
  }
  return device;
}


@end