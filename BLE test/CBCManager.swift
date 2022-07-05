import UIKit
import CoreBluetooth
import NotificationCenter

@objc class CBCDevice:NSObject {
    var peripheral:CBPeripheral!
    var uuid:String!
    var device_name:String!
    var mesh_name:String!
    var rssi:Int!//連線強度
}

@objc protocol CBCManagerDelegate {
    @objc optional func ScanDeviceResult(device:CBCDevice) -> Bool
    @objc optional func notifyCB(device:CBCDevice, bytes:UnsafeMutablePointer<UInt8>)
}

public class CBCManager:NSObject{
    private var queue: DispatchQueue = DispatchQueue(label: "serialQueue1",qos: .default)
    private static var _singleInstance:CBCManager!
    
    static var SERVICE_UUID = "1fee6acf-a826-4e37-9635-4d8a01642c5d"
    static var CHARACTERISTIC_UUID = "7691b78a-9015-4367-9b95-fc631c412cc6"
    
    @discardableResult public static func GetSingleInstance() -> CBCManager {
        if(_singleInstance == nil){
            _singleInstance = CBCManager()
            _singleInstance.setUp()
        }
        return _singleInstance
    }
    
    var del:CBCManagerDelegate!
    var centralManger:CBCentralManager!
    var centerState:CBManagerState = .unknown
    //scan裝置列表
    var devices:[CBCDevice] = []
    //正在連線裝置
    var tempDevice:CBCDevice!
    var tempPeripherals:CBPeripheral!
    var timer:SwiftTimerQueue!
    
    var commandFeature:CBCharacteristic!
    var isScan = false
    
    private func setUp(){
        centralManger = CBCentralManager.init(delegate: self, queue: nil,options: [CBCentralManagerOptionShowPowerAlertKey:true])
        devices = []
        isScan = false
        tempPeripherals = nil
        timer = SwiftTimerQueue.init(interval: .milliseconds(400))
    }
    
    func GetBlueToothStatus()->Bool{
        return centralManger.state == .poweredOn
    }
    
    func reSet(){
        self.commandFeature=nil
        timer?.suspend()
        timer = nil
        timer = SwiftTimerQueue.init(interval: .milliseconds(400))
    }
    
    func startScan() {
        print("startscan\(centerState != .poweredOn)")
        if centerState != .poweredOn{
            isScan = true
            return
        }
        devices.removeAll()
        centralManger?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan(){
        isScan = false
        centralManger?.stopScan()
    }
    
    //清除連線或搜尋的裝置
    func clean(){
        stopScan()
        for item in devices{
            centralManger.cancelPeripheralConnection(item.peripheral)
        }
        devices.removeAll()
        reSet()
    }
    
    func sendCommand(cmd:UnsafeMutablePointer<UInt8>,len:Int){
        let cmdArr = changeCommandToArray(cmd: cmd, len: len)
        timer?.addQueue { [self] in
            cmdTimer(temp: cmdArr)
        }
    }
    
    func cmdTimer(temp:NSArray){
        let len = temp.count
        let cmd = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        for i in 0..<len{
            if let str = temp[i] as? String{
                cmd[i] = UInt8(strtoul(str, nil, 16))
            }
        }
        exeCMD(cmd: cmd,len:len)
    }
    
    func exeCMD(cmd:UnsafeMutablePointer<UInt8>,len:Int){
        logByte(bytes: cmd, len: len, str: "exeCMD")
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        writeValue(characteristic: commandFeature, buffer: buffer, len: len, type: .withResponse)
    }

    func logByte(bytes:UnsafeMutablePointer<UInt8>,len:Int,str:String){
        var tempStr = ""
        for i in 0..<len{
            //let hex = Int.init(bytes[i])
            tempStr += String(format: "%02X ", bytes[i])
        }
        print("\(str) \(tempStr)")
    }

    func writeValue(characteristic:CBCharacteristic?,buffer:UnsafeMutablePointer<UInt8>,len:Int,type:CBCharacteristicWriteType){
        logByte(bytes: buffer, len: 20, str: "writeValue")
        if characteristic == nil{
            return
        }
        if tempPeripherals == nil{
            return
        }
        if tempPeripherals.state != .connected {
            return
        }
        let tempData = NSData.init(bytes: buffer, length: len)
        tempPeripherals.writeValue(tempData as Data, for: characteristic!, type: type)
    }
    
    func changeCommandToArray(cmd:UnsafeMutablePointer<UInt8>,len:Int)->NSArray{
        let arr = NSMutableArray.init()
        for i in 0..<len{
            arr.add(String.init(format: "%02X", cmd[i]))
        }
        return arr
    }
    
    //解析資料
    func pasterData(buffer:UnsafeMutablePointer<UInt8>){
        logByte(bytes: buffer, len: 20, str: "pasterData")
        passUsefulMessageWithBytes(bytes:buffer)
    }
    
    //解析資料
    func passUsefulMessageWithBytes(bytes:UnsafeMutablePointer<UInt8>){
        del?.notifyCB?(device:tempDevice, bytes:bytes)
    }
    
    func connect(device:CBCDevice){
        tempDevice = device
        tempPeripherals = device.peripheral
        centralManger.connect(tempPeripherals, options: nil)
    }
    
    // MARK: command
    func getInfo(device:CBCDevice){
        var cmd:[UInt8] = [0x00,0x00,0xD4,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00]
        sendCommand(cmd: &cmd, len: 20)
    }
}

extension CBCManager:CBCentralManagerDelegate{
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState\(central)")
        centerState = central.state
        if isScan,centerState == .poweredOn{
            isScan = false
            startScan()
        }
        
        switch (central.state) {
        case .poweredOn:
            print("state On");
        case .poweredOff:
            print("state Off");
        case .unknown:
            fallthrough;
        default:
            print("state Unknow");
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == nil || peripheral.name?.count == 0{
            return
        }

        var deviceName = ""
        if let name = advertisementData["kCBAdvDataLocalName"] as? String{
            deviceName = name
        }

        guard let nsdata = advertisementData["kCBAdvDataManufacturerData"] as? NSData else{
            return
        }
        print("nsdata:\(nsdata)")
        let publicData = Data(bytes: nsdata.bytes, count: Int(nsdata.length))
        let str = publicData.reduce("") {$0 + String(format: "%02X", $1)}
        if str.count<30{
            return
        }
        let uuid = peripheral.identifier.uuidString
        let device = CBCDevice()
        device.peripheral = peripheral
        device.uuid = uuid
        device.device_name = peripheral.name
        device.mesh_name = deviceName
        device.rssi = RSSI.intValue

        if devices.contains(where:{ $0.uuid == device.uuid}){
            print("exist \(device.uuid ?? "")")
            return
        }
        if let bo = del?.ScanDeviceResult?(device:device),bo{
            devices.append(device)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        
        tempPeripherals = peripheral
        centralManger.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("fail to connect to peipheral:\(error?.localizedDescription ?? "")")
        tempPeripherals = nil
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
}


extension CBCManager:CBPeripheralDelegate{
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        if let error = error{
            print(error)
            return
        }
        
        guard  let services = peripheral.services else {
            return
        }
        for item in services{
            //print("characteristics  \(item.uuid)")
            if item.uuid == CBUUID.init(string: CBCManager.SERVICE_UUID){
                peripheral.discoverCharacteristics(nil, for: item)
                
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        if error != nil{
            print(error as Any)
            return
        }
        
        guard  let characteristics = service.characteristics else {
            return
        }
        
        for item in characteristics{
            print("characteristics \(item.uuid)")
            if item.uuid == CBUUID(string: CBCManager.CHARACTERISTIC_UUID){
                commandFeature = item
                tempPeripherals?.readValue(for: commandFeature)
                //peripheral.setNotifyValue(true, for: item)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor")
        if error != nil{
            print(error as Any)
            return
        }

        print("characteristic\(characteristic)")
        if characteristic == commandFeature{
            tempPeripherals?.readValue(for: commandFeature)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor")
        if error != nil{
            print(error as Any)
            return
        }
        print("characteristic\(characteristic)")
        
        guard var data = characteristic.value else{
            return
        }

        if characteristic == commandFeature{
            data.withUnsafeMutableBytes { tempData in
                pasterData(buffer:tempData)
            }
        }
    }
}
