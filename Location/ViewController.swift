//
//  ViewController.swift
//  Location
//
//  Created by Michael Harper on 1/26/18.
//  Copyright © 2018 Radius Networks, Inc. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class ViewController: UIViewController {
  let beaconMonitoringUUID = UUID(uuidString: "1A2B3C4D-5E1A-2B3C-4D5E-6F708192A3B4")!
  
  let beaconUUID = UUID(uuidString: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")!
  let beaconMajor = CLBeaconMajorValue(3255)
  let beaconMinor = CLBeaconMinorValue(1313)
  
  var locationManager: CLLocationManager?
  var monitoringBeaconRegion: Bool = false {
    didSet {
      DispatchQueue.main.async {
        self.startStopButton.setTitle(self.monitoringBeaconRegion ? "Stop UUID Region Monitoring" : "Start UUID Region Monitoring", for: .normal)
        if self.monitoringBeaconRegion {
          self.activityIndicator.startAnimating()
          self.locationManager?.requestState(for: self.uuidBeaconRegion)
        }
        else {
          self.activityIndicator.stopAnimating()
        }
      }
    }
  }
  lazy var uuidBeaconRegion = CLBeaconRegion(proximityUUID: beaconMonitoringUUID, identifier: "UUID Region")
  
  var broadcasting: Bool = false {
    didSet {
      DispatchQueue.main.async {
        self.startStopBroadcastingButton.setTitle(self.broadcasting ? "Stop Broadcasting As Beacon" : "Start Broadcasting As Beacon", for: .normal)
      }
    }
  }
  lazy var broadcaster = Broadcaster(uuid: beaconUUID, major: beaconMajor, minor: beaconMinor)
  
  var ranging: Bool = false {
    didSet {
      DispatchQueue.main.async {
        self.startStopRangingButton.setTitle(self.ranging ? "Stop Ranging Beacons" : "Start Ranging Beacons", for: .normal)
      }
    }
  }
  var centralManager: CBCentralManager?
  lazy var logger = Logger(logField: logTextView)
  
  @IBOutlet weak var startStopButton: UIButton!
  @IBOutlet weak var startStopBroadcastingButton: UIButton!
  @IBOutlet weak var startStopRangingButton: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var logTextView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    logger.clear()
    checkBluetoothStatus()
    if canBeacon() {
      checkAuthorizationStatus()
    }
    else {
      displayCannotBeacon()
    }
  }
}

extension ViewController : CLLocationManagerDelegate {
  func canBeacon() -> Bool {
    return CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) && CLLocationManager.isRangingAvailable()
  }
  
  func displayCannotBeacon() {
    let alert = UIAlertController(title: "Cannot Beacon!", message: "Real sorry, Dude, but I can't beacon under these circumstances. ☹️", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Bummer", style: .default))
    present(alert, animated: true, completion: nil)
  }
  
  func checkAuthorizationStatus() {
    DispatchQueue.main.async {
      let locationManager = CLLocationManager()
      locationManager.delegate = self
      self.locationManager = locationManager
      if CLLocationManager.authorizationStatus() != .authorizedAlways {
        locationManager.requestAlwaysAuthorization()
      }
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .notDetermined:
      logger.log("didChangeAuthorization to notDetermined")
    case .restricted:
      logger.log("didChangeAuthorization to restricted")
    case .denied:
      logger.log("didChangeAuthorization to denied")
    case .authorizedAlways:
      logger.log("didChangeAuthorization to authorizedAlways")
    case .authorizedWhenInUse:
      logger.log("didChangeAuthorization to authorizedWhenInUse")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    switch state {
    case .unknown:
      logger.log("didDetermineState unknown for region \(region.identifier)")
    case .inside:
      logger.log("didDetermineState inside for region \(region.identifier)")
    case .outside:
      logger.log("didDetermineState outside for region \(region.identifier)")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    logger.log("didEnterRegion \(region.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    logger.log("didExitRegion \(region.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    logger.log("didStartMonitoringFor \(region.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    logger.log("monitoringDidFailFor \(region?.identifier ?? "unknown region") with error \(error.localizedDescription)")
  }
  
  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    logger.log("didRangeBeacons (\(beacons.count)) in \(region.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
    logger.log("rangingBeaconsDidFailFor \(region.identifier) with error \(error.localizedDescription)")
  }
}

extension ViewController : CBCentralManagerDelegate {
  func checkBluetoothStatus() {
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .unknown:
      logger.log("centralManagerDidUpdateState unknown")
    case .unsupported:
      logger.log("centralManagerDidUpdateState unsupported")
    case .unauthorized:
      logger.log("centralManagerDidUpdateState unauthorized")
    case .resetting:
      logger.log("centralManagerDidUpdateState resetting")
    case .poweredOff:
      logger.log("centralManagerDidUpdateState powered off")
    case .poweredOn:
      logger.log("centralManagerDidUpdateState powered on")
    }
  }
}

extension ViewController {
  @IBAction func startStopAction(_ sender: Any) {
    monitoringBeaconRegion = !monitoringBeaconRegion
    if monitoringBeaconRegion {
      locationManager?.startMonitoring(for: uuidBeaconRegion)
    }
    else {
      locationManager?.stopMonitoring(for: uuidBeaconRegion)
    }
  }

  @IBAction func launchSettingsAction(_ sender: Any) {
    if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
      UIApplication.shared.open(appSettings)
    }
  }
  
  @IBAction func startStopBroadcastingAction(_ sender: Any) {
    broadcasting = !broadcasting
    if broadcasting {
      broadcaster.start()
    }
    else {
      broadcaster.stop()
    }
  }
  
  @IBAction func startStopRangingAction(_ sender: Any) {
    ranging = !ranging
    if ranging {
      locationManager?.startRangingBeacons(in: uuidBeaconRegion)
    }
    else {
      locationManager?.stopRangingBeacons(in: uuidBeaconRegion)
    }
  }
}

public class Broadcaster : NSObject {
  let uuid: UUID
  let major: CLBeaconMajorValue
  let minor: CLBeaconMinorValue
  
  lazy var beaconRegion: CLBeaconRegion = {
    return CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: "Location Beacon")
  }()
  
  var localPeripheralData: [String : Any]? {
    get {
      return beaconRegion.peripheralData(withMeasuredPower: nil) as? [String : Any]
    }
  }
  
  var peripheralManager: CBPeripheralManager?
  
  init(uuid: UUID, major: CLBeaconMajorValue, minor: CLBeaconMinorValue) {
    self.uuid = uuid
    self.major = major
    self.minor = minor
  }
  
  func start() {
    configureBluetooth()
  }
  
  func stop() {
    stopAdvertising()
  }
}

extension Broadcaster : CBPeripheralManagerDelegate {
  func configureBluetooth() {
    if peripheralManager == nil {
      peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
  }
  
  func startAdvertising() {
    peripheralManager?.startAdvertising(localPeripheralData)
  }
  
  func stopAdvertising() {
    peripheralManager?.stopAdvertising()
    peripheralManager = nil
  }
  
  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    switch peripheral.state {
    case .unknown:
      NSLog("peripheralManagerDidUpdateState unknown")
    case .unsupported:
      NSLog("peripheralManagerDidUpdateState unsupported")
    case .unauthorized:
      NSLog("peripheralManagerDidUpdateState unauthorized")
    case .resetting:
      NSLog("peripheralManagerDidUpdateState resetting")
    case .poweredOff:
      NSLog("peripheralManagerDidUpdateState powered off")
      startAdvertising()
    case .poweredOn:
      NSLog("peripheralManagerDidUpdateState powered on")
      startAdvertising()
    }
  }
  
  public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    NSLog("peripheralManagerDidStartAdvertising " + (error != nil ? "with error \(error!.localizedDescription)" : "without error"))
  }
}

struct Logger {
  let logField: UITextView
  
  init(logField: UITextView) {
    self.logField = logField
  }
  
  func log(_ message: String) {
    if logField.text.isEmpty {
      logField.text = message
    }
    else {
      logField.text = "\(logField.text!)\n\(message)"
    }
  }
  
  func clear() {
    logField.text = ""
  }
}
