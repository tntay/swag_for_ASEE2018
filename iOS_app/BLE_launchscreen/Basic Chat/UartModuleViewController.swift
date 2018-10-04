//
//  UartModuleViewController.swift
//  Basic Chat
//
//  Created by Trevor Beaton on 12/4/16.
//  Copyright © 2016 Vanguard Logic LLC. All rights reserved.
//
//  Modified by Trenton Taylor on 6/6/18.




import UIKit
import CoreBluetooth


/*
 *  Notification Center Channel Names
 */
extension Notification.Name {
    
    static let notifyName_temp = Notification.Name("TEMPERATURE")
    static let notifyName_hum = Notification.Name("HUMIDITY")
    static let notifyName_pres = Notification.Name("PRESSURE")
    static let notifyName_BleDisconnect = Notification.Name("BLEDISCONNECTED")
}

/*
 *  View Controller class definition
 */
class UartModuleViewController: UIViewController, CBPeripheralManagerDelegate {
    
    //UI
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gaugeViewTemp: LMGaugeView!
    @IBOutlet weak var gaugeViewHum: LMGaugeView!
    @IBOutlet weak var gaugeViewPres: LMGaugeView!
    @IBOutlet weak var switchViewTemp: UISwitch!
    @IBOutlet weak var switchViewPres: UISwitch!
    @IBOutlet weak var labelViewTempToggle: UILabel!
    @IBOutlet weak var labelViewPresToggle: UILabel!
    @IBOutlet weak var labelViewDisconnected: UILabel!
    
    //Data
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral!
    private var consoleAsciiText:NSAttributedString? = NSAttributedString(string: "")
    var cur_temp : Int = 0
    var cur_pres : Float = 0
    var defaultTempUnits : Bool = true
    var defaultPresUnits : Bool = true
    
    
    
    /*
     *
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        
        //Create and start the peripheral manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        //Set up temperature gauge
        gaugeViewTemp.minValue = -40
        gaugeViewTemp.maxValue = 100
        gaugeViewTemp.limitValue = 0
        gaugeViewTemp.divisionsColor = UIColor.blue
        gaugeViewTemp.backgroundColor = UIColor.black
        gaugeViewTemp.valueTextColor = UIColor.white
        gaugeViewTemp.ringBackgroundColor = UIColor.white
        gaugeViewTemp.unitOfMeasurement = "°C"
        gaugeViewTemp.ringThickness = CGFloat(5.0)
        gaugeViewTemp.valueFont = UIFont(name: "HelveticaNeue-CondensedBold", size: 50)
        gaugeViewTemp.numOfDivisions = 7
        gaugeViewTemp.divisionsPadding = 10
        
        //Set up humidity gauge
        gaugeViewHum.minValue = 0
        gaugeViewHum.maxValue = 100
        gaugeViewHum.limitValue = 0
        gaugeViewHum.divisionsColor = UIColor.blue
        gaugeViewHum.backgroundColor = UIColor.black
        gaugeViewHum.valueTextColor = UIColor.white
        gaugeViewHum.ringBackgroundColor = UIColor.white
        gaugeViewHum.unitOfMeasurement = "%"
        gaugeViewHum.ringThickness = CGFloat(5.0)
        gaugeViewHum.valueFont = UIFont(name: "HelveticaNeue-CondensedBold", size: 50)
        gaugeViewHum.numOfDivisions = 5
        gaugeViewHum.divisionsPadding = 10
        
        //Set up pressure gauge
        gaugeViewPres.minValue = 0
        gaugeViewPres.maxValue = 140
        gaugeViewPres.limitValue = 0
        gaugeViewPres.divisionsColor = UIColor.blue
        gaugeViewPres.backgroundColor = UIColor.black
        gaugeViewPres.valueTextColor = UIColor.white
        gaugeViewPres.ringBackgroundColor = UIColor.white
        gaugeViewPres.unitOfMeasurement = "kPa"
        gaugeViewPres.ringThickness = CGFloat(5.0)
        gaugeViewPres.valueFont = UIFont(name: "HelveticaNeue-CondensedBold", size: 50)
        gaugeViewPres.numOfDivisions = 7
        gaugeViewPres.divisionsPadding = 10
        
        //Registor to recieve notifications on the four difined channels
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(UartModuleViewController.setViewTemperature), name: .notifyName_temp, object: nil)
        nc.addObserver(self, selector: #selector(UartModuleViewController.setViewHumidity), name: .notifyName_hum, object: nil)
        nc.addObserver(self, selector: #selector(UartModuleViewController.setViewPressure), name: .notifyName_pres, object: nil)
        nc.addObserver(self, selector: #selector(UartModuleViewController.lostBleConnection), name: .notifyName_BleDisconnect, object: nil)
    }
    
    
    /*
     *
     */
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    
    /*
     *
     */
    override func viewDidDisappear(_ animated: Bool) {
        
        // peripheralManager?.stopAdvertising()
        // self.peripheralManager = nil
        super.viewDidDisappear(animated)
        
        //Stop listening for notifications
        NotificationCenter.default.removeObserver(self, name: .notifyName_temp, object: nil)
        NotificationCenter.default.removeObserver(self, name: .notifyName_hum, object: nil)
        NotificationCenter.default.removeObserver(self, name: .notifyName_pres, object: nil)
    }
    
    
    /*
     *
     */
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if peripheral.state == .poweredOn {
            return
        }
        print("Peripheral manager is running")
    }
    
    
    /*
     *
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        print("Device subscribe to characteristic")
    }
    
    
    /*
     *
     */
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        
        if let error = error {
            print("\(error)")
            return
        }
    }
    
    
    /*
     *  switch action toggle temperuature units
     */
    @IBAction func switchToggleTemp(_ sender: Any) {
        
        if switchViewTemp.isOn {
            // Toggle to C. Update UI. Set flag to notify that no data conversion is needed.
            labelViewTempToggle.text = "°C"
            gaugeViewTemp.unitOfMeasurement = "°C"
            gaugeViewTemp.minValue = -40
            gaugeViewTemp.maxValue = 100
            gaugeViewTemp.limitValue = 0
            gaugeViewTemp.numOfDivisions = 7
            let cel = CGFloat(cur_temp)
            gaugeViewTemp.value = cel
            defaultTempUnits = true
        }
        else {
            // Toggle to F. Update UI. Set flag to notify conversion of data.
            labelViewTempToggle.text = "°F"
            gaugeViewTemp.unitOfMeasurement = "°F"
            gaugeViewTemp.minValue = -40
            gaugeViewTemp.maxValue = 212
            gaugeViewTemp.limitValue = 0
            gaugeViewTemp.numOfDivisions = 6
            let doubleVal : Double = Double(cur_temp)
            let feren = CGFloat(doubleVal * 1.8 + 32)
            gaugeViewTemp.value = feren
            defaultTempUnits = false
        }
    }
    
    
    /*
     *  switch action toggle temperuature units
     */
    @IBAction func switchTogglePres(_ sender: Any) {
        
        if switchViewPres.isOn {
            // Toggle to Pa. Update UI. Set flag to notify that no data conversion is needed.
            labelViewPresToggle.text = "kPa"
            gaugeViewPres.unitOfMeasurement = "kPa"
            gaugeViewPres.minValue = 0
            gaugeViewPres.maxValue = 140
            gaugeViewPres.limitValue = 0
            gaugeViewPres.numOfDivisions = 7
            let kpa = CGFloat(cur_pres)
            gaugeViewPres.value = kpa
            defaultPresUnits = true
        }
        else {
            // Toggle to Atm. Update UI. Set flag to notify conversion of data.
            labelViewPresToggle.text = "PSI"
            gaugeViewPres.unitOfMeasurement = "PSI"
            gaugeViewPres.minValue = 0
            gaugeViewPres.maxValue = 20
            gaugeViewPres.limitValue = 0
            gaugeViewPres.numOfDivisions = 4
            let psi : CGFloat = CGFloat(cur_pres * 0.14503773773020923)
            gaugeViewPres.value = psi
            defaultPresUnits = false
        }
    }
    
    
    // Notification Center regesterd functions //
    
    /*
     *  Update temperature in view with new sensor reading posted in NC
     */
    func setViewTemperature(notification: NSNotification) {
        
        if let data = notification.userInfo as? [String: Int] {
            for (_, val) in data {
                cur_temp = val
                
                if !defaultTempUnits {
                    let doubleVal : Double = Double(cur_temp)
                    let feren = CGFloat(doubleVal * 1.8 + 32)
                    gaugeViewTemp.value = feren
                }
                else {
                    let cel = CGFloat(cur_temp)
                    gaugeViewTemp.value = cel
                }
            }//for
        }//if let data
        else {
            print("Didnt get the sensor data!")
        }
    }
    
    
    /*
     *  Update humidity in view with new sensor reading posted in NC
     */
    func setViewHumidity(notification: NSNotification) {
        
        if let data = notification.userInfo as? [String: Int] {
            for (_, val) in data {
                let cgfloat = CGFloat(val)
                gaugeViewHum.value = cgfloat
            }
        }
        else {
            print("Didnt get the sensor data!")
        }
    }
    
    
    /*
     *  Update pressure in view with new sensor reading posted in NC
     */
    func setViewPressure(notification: NSNotification) {
        
        if let data = notification.userInfo as? [String: Int] {
            for (_, val) in data {
                let floatVal : Float = Float(val)
                cur_pres = floatVal / 1000
                
                if !defaultPresUnits {
                    let psi : CGFloat = CGFloat(cur_pres * 0.14503773773020923)
                    gaugeViewPres.value = psi
                }
                else {
                    let kpa = CGFloat(cur_pres)
                    gaugeViewPres.value = kpa
                }
            }//for
        }//if let data
        else {
            print("Didnt get the sensor data!")
        }
    }
    
    
    /*
     *  Update temperature in view with new sensor reading posted in NC
     */
    func lostBleConnection(notification: NSNotification) {
        
        labelViewDisconnected.text = "WARNING: lost connection... \nPlease reconnect your device."
    }
    
}//end class declaration




/*
 // Define identifier
 let notificationName = Notification.Name("NotificationIdentifier")
 
 // Register to receive notification
 NotificationCenter.default.addObserver(self, selector: #selector(YourClassName.methodOfReceivedNotification), name: notificationName, object: nil)
 
 // Post notification
 NotificationCenter.default.post(name: notificationName, object: nil)
 
 // Stop listening notification
 NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
 */



