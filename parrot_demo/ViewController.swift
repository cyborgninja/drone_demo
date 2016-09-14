//
//  ViewController.swift
//  parrot_demo
//
//  Created by 松本隆 on 2016/09/13.
//  Copyright © 2016年 松本隆. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var label1: UILabel!
  var isConnected = false
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    registerReceivers()
    startDiscovery()
  }
  
  func startDiscovery() {
    ARDiscovery.sharedInstance().start()
  }
  
  func registerReceivers() {
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(ViewController.discoveryDidUpdateServices(_:)),
      name: kARDiscoveryNotificationServicesDevicesListUpdated,
      object: nil
    )
  }
  
  func discoveryDidUpdateServices(notification: NSNotification) {
    if let userInfo = notification.userInfo {
      let deviceList = userInfo[kARDiscoveryServicesList] as! Array<ARService>
      // デバイスを発見したら呼ばれる
      if isConnected == false {
        let serviceList = deviceList as! [ARService]
        isConnected = DTDrone.sharedInstance().connectWithService(serviceList[0])
      }
    }
  }
  
  
  @IBAction func button(sender: AnyObject) {
    DTDrone.sharedInstance().takeoff() // 離陸
  }
  @IBAction func didPressFlip(sender: AnyObject) {
    DTDrone.sharedInstance().flip() // 一回転
  }
  @IBAction func didPressDrop(sender: AnyObject) {
    DTDrone.sharedInstance().land() // 着陸
  }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

