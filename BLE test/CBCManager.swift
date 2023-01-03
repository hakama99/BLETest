import UIKit
import CoreData
import SwiftyJSON
import CoreBluetooth
import NotificationCenter

enum MotionCMDType:Int{
    case CleanCache = 0x00
    case SetParams1 = 0x01
    case SetParams2 = 0x02
    case GetParams1 = 0x08
    case GetParams2 = 0x09
    case CurrentLux = 0x11
    case AdvanceTime = 0x22
    case CfgCOmmit = 0xff
}

enum RemoteCMDType:Int{
    case GetKeyMM = 0x9F
    case GetkeyGroup1 = 0xA0
    case GetkeyGroup2 = 0xA1
    case GetkeyGroup3 = 0xA2
    case GetkeyGroup4 = 0xA3
    case GetkeyCommit = 0xA4
    case GetMicrowaveStatus = 0xA8
    case SetKeyMM = 0x5F
    case SetkeyGroup1 = 0x60
    case SetkeyGroup2 = 0x61
    case SetkeyGroup3 = 0x62
    case SetkeyGroup4 = 0x63
    case CfgCommit = 0x64
    case SetMicrowaveStatus = 0x68
    case Get_MMWAVE_PH13_Page1 = 0xAB
    case Get_MMWAVE_PH13_Page2 = 0xAC
    case Set_MMWAVE_PH13_Page1 = 0x2B
    case Set_MMWAVE_PH13_Page2 = 0x2C
    case Set_MMWAVE_PH13_Page3 = 0x6D
}

@objc class CBCDevice:NSObject {
    var peripheral:CBPeripheral!
    var uuid:String!
    var device_name:String!
    var mesh_name:String!
    
    var facturer_id:Int!
    var deviceType:Int!
    var macAddress:Int!
    var mac:String! //整理過mac
    var firmware:Int!
    //var meshUuid:Int!
    var device_id:Int!
    var status:Int!
    var otaCode:Int!
    var chipType:Int!
    var sType:Int!
    var productId:Int!
    var fullMacAddress:Int!
    
    var rssi:Int!//連線強度
    
    var isSelect = false
    var isKoreaVer = false
    
    //kumo前兩個位元是錯的不判斷 可用getMac取得正確的
    func isSameMac(_ compareMac:String) -> Bool{
        if mac == nil || mac.count<5{
            return false
        }
        
        if isKoreaVer{
            return mac.uppercased().substring(from: 4) == compareMac.uppercased().substring(from: 4)
        }else{
            return mac.uppercased() == compareMac.uppercased()
        }
    }
}

@objc protocol CBCManagerDelegate {
    @objc optional func ScanDeviceResult(device:CBCDevice) -> Bool
    @objc optional func OnlineAllResult(device:CBCDevice)
    @objc optional func onConnectFinish(device:CBCDevice,success:Bool)
    @objc optional func SetDeviceIdCb(device:CBCDevice,success:Bool)
    @objc optional func SetGroupCb(device:CBCDevice,success:Bool)
    @objc optional func SetMeshCb(device:CBCDevice,success:Bool)
    @objc optional func SetKickoutCb(device:CBCDevice,success:Bool)
    @objc optional func GetMacCb(device:CBCDevice,success:Bool,newMac:String)
    @objc optional func StartBlinkCb(device:CBCDevice)
    @objc optional func StopBlinkCb(device:CBCDevice)
}

public class CBCManager:NSObject{
    private var queue: DispatchQueue = DispatchQueue(label: "serialQueue1",qos: .default)
    private static var _singleInstance:CBCManager!
    
    static var BTDevInfo_Name = "Telink tLight"
    static var MaxSnValue = 0xffffff
    //廠商
    static var BTDevInfo_UID = 0x1102
    var KOREA_VAR = "0a0b0c0d0e0f".uppercased()
    //原廠mesh帳號
    static var DEFAULT_MESH_NAME = "endo"
    //原廠mesh密碼
    static var DEFAULT_MESH_PASSWORD = "smartledz"
    static var BTDevInfo_ServiceUUID = "00010203-0405-0607-0809-0A0B0C0D1910"
    //通知用
    static var BTDevInfo_FeatureUUID_Notify = "00010203-0405-0607-0809-0A0B0C0D1911"
    //下達指令
    static var BTDevInfo_FeatureUUID_Command = "00010203-0405-0607-0809-0A0B0C0D1912"
    //連線相關
    static var BTDevInfo_FeatureUUID_Pair = "00010203-0405-0607-0809-0A0B0C0D1914"
    static var BTDevInfo_FeatureUUID_OTA = "00010203-0405-0607-0809-0A0B0C0D1913"
    static var Service_Device_Information = "0000180a-0000-1000-8000-00805f9b34fb"
    static var Characteristic_Firmware = "00002a26-0000-1000-8000-00805f9b34fb"
    static var meshBuffer:UnsafeMutablePointer<UInt8>{
        get{
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 20)
            memset(buffer, 0, 20)
            
            for j in 0..<16{
                if (j<8) {
                    buffer[j] = UInt8(0xc0+j);
                }
                else {
                    buffer[j] = UInt8(0xd0+j);
                }
            }
            return buffer
        }
    }
    
    enum ConnectStatus:Int{
        case DevOperaStatus_Normal=1
        case DevOperaStatus_Connect_Start//連線中
        case DevOperaStatus_ScanSrv_Finish//完成扫描服务uuid
        case DevOperaStatus_ScanChar_Finish//完成扫描特征
        case DevOperaStatus_Login_Start
        case DevOperaStatus_Login_Finish
        case DevOperaStatus_SetGroup
        case DevOperaStatus_SetDevAddress
        case DevOperaStatus_SetDevAddress_Finish
        case DevOperaStatus_SetName_Start
        case DevOperaStatus_SetPassword_Start
        case DevOperaStatus_SetLtk_Start
        case DevOperaStatus_SetNetwork_Finish
        case DevOperaStatus_FireWareVersion
        case DevOperaStatus_GetMac
    }
    
    enum Action{
        case Blink
        case StopBlink
        case Kickout
        case SetDevAddress
        case SetGroup
        case SetMesh
        case GetMac
    }
    
    
    public static func GetSingleInstance() -> CBCManager {
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
    var devices:[CBCDevice]!
    //正在連線裝置
    var tempDevice:CBCDevice!
    var tempPeripherals:CBPeripheral!
    //連線狀態
    var connectStatus:ConnectStatus = .DevOperaStatus_Normal
    //設定mesh步驟有三個 等待數  3 = done
    var readIndex = 0
    //新的網路
    var newMeshName = ""
    var newMeshPassword = ""
    //現有連線網路
    var meshName = ""
    var meshPassword = ""
    //新的id
    var newDevId = 0
    var newRoomId = 0
    var timer:SwiftTimerQueue!
    //是否連線
    var isLogin = false
    //連線後處理
    var actionAfterLogin:Action!
    //是否等待踢掉 disconnect
    var isKickout = false
    var waitCBTimer:SwiftTimer!
    var loginTImer:SwiftTimer!
    var notifyTimer:SwiftTimer!
    var blinkTimer:SwiftTimer!
    var blinkList:Dictionary<String,DispatchTime> = [:]
    var CONNECT_TIME = 8
    
    //流水號
    var addIndex = 0
    var snNo = 0
    var tempMac = ""
    
    //characteristic
    var commandFeature:CBCharacteristic!
    var pairFeature:CBCharacteristic!
    var otaFeature:CBCharacteristic!
    var fireWareFeature:CBCharacteristic!
    var notifyFeature:CBCharacteristic!

    var loginRand:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    var sectionKey:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    var tempbuffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 20)
    
    var isScan = false
    
    private func setUp(){
        centralManger = CBCentralManager.init(delegate: self, queue: nil,options: [CBCentralManagerOptionShowPowerAlertKey:true])
        devices = []
        isScan = false
        memset(tempbuffer, 0, 20)
        readIndex = 0
        tempPeripherals = nil
        timer = SwiftTimerQueue.init(interval: .milliseconds(400))
        blinkTimer = SwiftTimer.init(interval: .seconds(1),repeats: true, handler: { (timer) in
            
        })
    }
    
    func reSet(){
        
        self.commandFeature=nil
        self.pairFeature=nil
        self.notifyFeature=nil
        self.fireWareFeature = nil
        self.otaFeature = nil
        connectStatus = .DevOperaStatus_Normal
        memset(loginRand, 0, 8)
        memset(sectionKey, 0, 16)
        timer?.suspend()
        timer = nil
        timer = SwiftTimerQueue.init(interval: .milliseconds(400))
        blinkTimer?.suspend()
        blinkTimer = SwiftTimer.init(interval: .seconds(1),repeats: true, handler: { (timer) in
            
        })
        isLogin = false
    }
    
    func startScan() {
        print("startscan")
        if centerState != .poweredOn{
            isScan = true
            return
        }
        devices?.removeAll()
        centralManger?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan(){
        isScan = false
        centralManger.stopScan()
    }
    
    func setMesh(meshName:String,meshPassword:String){
        print("setmesh")
        if self.meshName != meshName{
            print("setmeshaaa")
            isLogin = false
        }
        self.meshName = meshName
        self.meshPassword = meshPassword
    }
    
    //連線任一台
    func connectAuto(meshName:String,meshPassword:String){
        print("connectAuto")
        self.meshName = meshName
        self.meshPassword = meshPassword
        connectStatus = .DevOperaStatus_Connect_Start
        isLogin = false
        
        if devices.count>0{
            for i in 0..<devices.count{
                let sameDeviceid = devices.filter({$0.device_id == devices[i].device_id})
                if sameDeviceid.count==1{
                    tempDevice = sameDeviceid.first
                    tempPeripherals = sameDeviceid.first!.peripheral
                    break;
                }
            }
        }else{
            return
        }
        centralManger.connect(tempPeripherals, options: nil)
    }
    
    func connect(device:CBCDevice,meshName:String,meshPassword:String ){
        print("connect mac:\(device.mac) id:\(device.device_id)")
        self.meshName = meshName
        self.meshPassword = meshPassword
        connectStatus = .DevOperaStatus_Connect_Start
        isLogin = false
        tempDevice = device
        tempPeripherals = device.peripheral
        if !devices.contains(where: {$0.mac == tempDevice.mac}){
            devices.append(tempDevice)
        }
        
        waitCBTimer?.suspend()
        waitCBTimer = SwiftTimer.init(interval: .seconds(CONNECT_TIME), handler: { [self] (timer) in
            print("connect time out\(device.mac) \(connectStatus)")
            if connectStatus == .DevOperaStatus_Connect_Start || connectStatus == .DevOperaStatus_Login_Start{
                del?.onConnectFinish?(device: device, success: false)
                if actionAfterLogin == .Blink{
                    //ActivityIndicatoryUtils.sharedInstance().deleteActivityIndicator()
                }
            }
        })
        waitCBTimer?.start()
        centralManger.connect(tempPeripherals, options: nil)
    }
    
    //停止指定連線
    func disconnect(device:CBCDevice,waitHandler:@escaping ()->Void){
        for item in devices{
            if item.mac == device.mac{
                centralManger.cancelPeripheralConnection(item.peripheral)
            }
        }
        reSet()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            waitHandler()
        }
    }
    
    //停止所有連線
    func stopConnect(waitHandler:@escaping ()->Void){
        for item in devices{
            centralManger.cancelPeripheralConnection(item.peripheral)
        }
        reSet()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            waitHandler()
        }
    }
    
    //清除連線或搜尋的裝置
    func clean(){
        if isScan{
            stopScan()
        }
        for item in devices{
            centralManger.cancelPeripheralConnection(item.peripheral)
        }
        devices.removeAll()
        reSet()
    }
    
    func writeValueForCharacteristic(hex:Data,forChracteristic characteristics:CBCharacteristic){
        if tempPeripherals == nil{
            return
        }
        
        if (characteristics.properties.rawValue & CBCharacteristicProperties.write.rawValue) == CBCharacteristicProperties.write.rawValue{
            tempPeripherals?.writeValue(hex, for: characteristics,type: CBCharacteristicWriteType.withResponse)
        }else{
            tempPeripherals?.writeValue(hex, for: characteristics,type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    func reverseString(str:String)->String{
        var arr:[String] = []
        let time = str.count/2
        for i in 0..<time{
            arr.append(str.substring(from: i*2,count: 2))
        }
        var result = ""
        arr = arr.reversed()
        for item in arr{
            result.append(item)
        }
        return result
    }
    
    //登入
    func loginWithPwd(password:String = ""){
        if pairFeature == nil{
            return
        }
        if !password.isEmpty{
            meshPassword = password
        }
        
        connectStatus = .DevOperaStatus_Login_Start
        
        let buffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 17)
        CryptoAction.getRandPro(loginRand, len: 8)
        for i in 0..<8{
            loginRand[i] = UInt8(i)
        }
        
        buffer[0]=12
        CryptoAction.encryptPair(meshName, pas: meshPassword, prand: loginRand, pResult: buffer+1)
        writeValue(characteristic: pairFeature,buffer: buffer,len: 17,type: CBCharacteristicWriteType.withResponse)
    }
    
    //閃爍
    func deviceBlink(device:CBCDevice){
        print("deviceBlink:\(device.device_id)")
        print("device mesh_name:\(device.mesh_name)")
        print("meshName:\(meshName)")
        print("isLogin:\(isLogin)")
        let sameDeviceid = devices.filter({$0.device_id == device.device_id})
        if !isLogin || (isLogin && device.mesh_name != tempDevice.mesh_name) || (sameDeviceid.count>1 && tempDevice.mac != device.mac){
            print("blink reconnect\(device.mac)")
            //id相同 斷線連該燈
            //ActivityIndicatoryUtils.sharedInstance().showActivityIndicator()
            stopConnect { [self] in
                actionAfterLogin = .Blink
                connect(device:device,meshName:self.meshName,meshPassword:self.meshPassword)
            }
            return
        }
        //ActivityIndicatoryUtils.sharedInstance().deleteActivityIndicator()
        del?.StartBlinkCb?(device: device)
        blinkList[device.mac] = .now() + 3
        let addr = UInt8(device.device_id ?? 0)
        var cmd:[UInt8] = [0xAD,0x18,0xD4,0x00,0x00,addr & 0xff,0x00,0xF0,0x11,0x02,0x00,0x01,0x16,0x11,0x01,0x01,0x00,0x00,0x00,0x00]

        if addr > 255{
            cmd[5] = (addr >> 8) & 0xff
        }else{
            cmd[5] = addr & 0xff
        }

        sendCommand(cmd: &cmd, len: 20)
        
        //3秒後幫他停止閃爍
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
            if let b = blinkList[device.mac],b > DispatchTime.now(){
                return
            }
            del?.StopBlinkCb?(device: device)
            if device.isKoreaVer{
                //ActivityIndicatoryUtils.sharedInstance().deleteActivityIndicator()
                if tempDevice.mac == device.mac{
                    setMesh(meshName: meshName, meshPassword: meshPassword)
                    stopBlink(device: device)
                }
            }
        }
    }
    
    func stopBlink(device:CBCDevice){
        print("stopBlink")
        let sameDeviceid = devices.filter({$0.device_id == device.device_id})
        if !isLogin || (isLogin && device.mesh_name != tempDevice.mesh_name) || (sameDeviceid.count>1 && tempDevice.mac != device.mac){
            //id相同 斷線連該燈
            stopConnect { [self] in
                actionAfterLogin = .StopBlink
                connect(device:device,meshName:self.meshName,meshPassword:self.meshPassword)
            }
            return
        }
        let addr = UInt8(device.device_id ?? 0)
        var cmd:[UInt8] = [0xAD,0x18,0xD4,0x00,0x00,addr & 0xff,0x00,0xF0,0x11,0x02,0x00,0x01,0x16,0x11,0x01,0x00,0x00,0x00,0x00,0x00]

        if addr > 255{
            cmd[5] = (addr >> 8) & 0xff
        }else{
            cmd[5] = addr & 0xff
        }

        sendCommand(cmd: &cmd, len: 20)
    }
    
    //踢掉
    func kickDevice(device:CBCDevice){
        print("kickDevice")
        if !isLogin{
            actionAfterLogin = .Kickout
            connect(device:device,meshName:self.meshName,meshPassword:self.meshPassword)
            return
        }
        var cmd:[UInt8] = [0x11,0x61,0x31,0x00,0x00,0x00,0x00,0xe3,0x11,0x02,0x01,0x03]
        //cmd[6] = UInt8((device.device_id>>8) & 0xff);
        //cmd[5] = UInt8(device.device_id & 0xff);  // 00 踢直連燈
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        isKickout = true
        //五秒後沒斷線當作失敗
        waitCBTimer?.suspend()
        waitCBTimer = SwiftTimer.init(interval: .seconds(20), handler: { [self] (timer) in
            if isKickout{
                isKickout = false
                del?.SetKickoutCb?(device: tempDevice, success: false)
            }
        })
        waitCBTimer?.start()
        sendCommand(cmd:&cmd, len: 12)
    }
    
    func configMesh(){
        if !isLogin{
            actionAfterLogin = .SetMesh
            connect(device:tempDevice,meshName:self.meshName,meshPassword:self.meshPassword)
            return
        }
        
        waitCBTimer?.suspend()
        waitCBTimer = SwiftTimer.init(interval: .seconds(5), handler: { [self] (timer) in
            if connectStatus == .DevOperaStatus_SetName_Start || connectStatus == .DevOperaStatus_SetPassword_Start || connectStatus == .DevOperaStatus_SetLtk_Start{
                del?.SetMeshCb?(device: tempDevice,success: false)
            }
        })
        waitCBTimer.start()
        
        let buffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 20)
        memset(buffer, 0, 20)
        readIndex = 0
        connectStatus = .DevOperaStatus_SetName_Start
        CryptoAction.getNetworkInfo(buffer, opcode: 4, str: newMeshName, psk: sectionKey)
        print("configMesh SetName")
        writeValue(characteristic: pairFeature, buffer: buffer, len: 20, type: CBCharacteristicWriteType.withResponse)
        
        connectStatus = .DevOperaStatus_SetPassword_Start
        CryptoAction.getNetworkInfo(buffer, opcode: 5, str: newMeshPassword, psk: sectionKey)
        print("configMesh SetPassword")
        writeValue(characteristic: pairFeature, buffer: buffer, len: 20, type: CBCharacteristicWriteType.withResponse)
        
        connectStatus = .DevOperaStatus_SetLtk_Start
        CryptoAction.getNetworkInfoByte(buffer, opcode: 6, str: tempbuffer, psk: sectionKey)
        print("configMesh SetLtk")
        writeValue(characteristic: pairFeature, buffer: buffer, len: 20, type: CBCharacteristicWriteType.withResponse)
    }
    
    //設定網路
    func setMeshInfo(oldName:String,oldPassword:String,newName:String,newPassword:String,buffer:UnsafeMutablePointer<UInt8>,item:CBCDevice){
        print("setMeshInfo")
        meshName = oldName
        meshPassword = oldPassword
        newMeshName = newName
        newMeshPassword = newPassword
        tempDevice = item
        
        if buffer != nil {
            for i in 0..<20{
                tempbuffer[i] = buffer[i];
            }
        }
        
        configMesh()
    }
    
    //設定id
    func setDeviceId(device:CBCDevice,id:Int){
        print("setDeviceId")
        newDevId = id
        if !isLogin{
            actionAfterLogin = .SetDevAddress
            connect(device:device,meshName:self.meshName,meshPassword:self.meshPassword)
            return
        }
        /*
        if device.device_id == id{
            del?.SetDeviceIdCb(device: device, success: true)
            return
        }*/
        
        //https://docs.google.com/spreadsheets/d/1WLGCv9nTVWIzrsMGVLVdXT6Ojn5U7m8EpNLTcyexid0/edit#gid=1418844599
        //Set device ID  OPcode = 7  Vendor code = 8 9 ,0x0A = 10 ,0x09 = 11, mac = 12~17 顛倒值
        connectStatus = .DevOperaStatus_SetDevAddress
        
        var cmd:[UInt8] = [0x11,0x11,0x70,0x00,0x00,0x00,0x00,0xe0,0x11,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]

        /*
        //直連可以不用帶mac 不用設定舊id
        var cmd:[UInt8] = [0x11,0x11,0x70,0x00,0x00,0x00,0x00,0xe0,0x11,0x02,0x00,0x00,0x01,0x10,0x00,0x00,0x00,0x00,0x00,0x00]
        cmd[6] = UInt8((device.device_id>>8) & 0xff);
        cmd[5] = UInt8(device.device_id & 0xff);
        cmd[19] = UInt8(device.mac.strHex2Int()>>40 & 0xff);
        cmd[18] = UInt8(device.mac.strHex2Int()>>32 & 0xff);
        cmd[17] = UInt8(device.mac.strHex2Int()>>24 & 0xff);
        cmd[16] = UInt8(device.mac.strHex2Int()>>16 & 0xff);
        cmd[15] = UInt8(device.mac.strHex2Int()>>8 & 0xff);
        cmd[14] = UInt8(device.mac.strHex2Int() & 0xff);*/
        cmd[10] = UInt8(id & 0xff);
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        
        //有可能壞掉不回傳。所以要設timeout
        waitCBTimer?.suspend()
        waitCBTimer = SwiftTimer.init(interval: .seconds(5), handler: { [self] (timer) in
            if connectStatus == .DevOperaStatus_SetDevAddress{
                del?.SetDeviceIdCb?(device: tempDevice, success: false)
            }
        })
        waitCBTimer?.start()
        sendCommand(cmd: &cmd, len: 20)
    }
    
    //設定id
    func setGroup(device:CBCDevice,roomid:Int){
        print("setGroup")
        newRoomId = roomid
        if !isLogin{
            actionAfterLogin = .SetGroup
            connect(device:device,meshName:self.meshName,meshPassword:self.meshPassword)
            return
        }
        /*
         :5]:0x0000，表示Src为0x0000，该值不需要变动。 [6:7]:0x0000，表示destination addr为0x0000，即只对本地连接的灯响应该
         命令(和BLE直接连接的灯)，表示将要操作对象是本地连接的灯。 [8]:0xd7，表示cmd为0xd7，为组操作的命令码。
         [9:10]VendorID:默认为 0x11 0x02，该值不需要变动。 [11]:0x01表示添加组(第0个parameter的值)。 [12:13]:0x8001表示添加的组号为0x8001(即第一组，组号的识别规则及取
         值范围详细解析见 “命令格式解析”)111111
         */
        connectStatus = .DevOperaStatus_SetGroup
        var cmd:[UInt8] = [0x11,0x11,0x21,0x00,0x00,0x00,0x00,0xd7,0x11,0x02,0x01,0x00,0x00]

        //print(device.mac.strHex2Int())
        //cmd[6] = UInt8((device.device_id>>8) & 0xff)
        //cmd[5] = UInt8(device.device_id & 0xff)
        print(roomid)
        print(UInt8(roomid>>8 & 0xff))
        print(UInt8(roomid & 0xff))
        cmd[12] = UInt8(roomid>>8 & 0xff)
        cmd[11] = UInt8(roomid & 0xff)

        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        
        //有可能壞掉不回傳。所以要設timeout
        waitCBTimer?.suspend()
        waitCBTimer = SwiftTimer.init(interval: .seconds(5), handler: { [self] (timer) in
            if connectStatus == .DevOperaStatus_SetGroup{
                del?.SetGroupCb?(device: tempDevice, success: false)
            }
        })
        waitCBTimer.start()
        sendCommand(cmd: &cmd, len: 20)
    }
    
    func getMac(device:CBCDevice){
        print("getMac \(device.mac)")
        if !isLogin{
            actionAfterLogin = .GetMac
            connect(device:device,meshName:self.meshName,meshPassword:self.meshPassword)
            return
        }
        tempMac = ""
        connectStatus = .DevOperaStatus_GetMac
        let devicceType = SystemData.DeviceType.init(rawValue: device.deviceType)
        var type = 1
        switch devicceType {
        case .PWM:
            type = 5
        case .A_CONTACT:
            type = 1
        default:
            type = 1
        }
        
        waitCBTimer?.suspend()
        waitCBTimer = SwiftTimer.init(interval: .seconds(5), handler: { [self] (timer) in
            print("get mac time out\(device.mac) \(connectStatus)")
            if connectStatus == .DevOperaStatus_GetMac{
                del?.GetMacCb?(device: tempDevice, success: false,newMac: "")
            }
        })
        waitCBTimer.start()
        
        let mode = SystemData.GetDeviceType(typecode: device.deviceType)
        switch mode {
        case .SENSOR:
            sensorMacAddrGet(index: 0)
            sensorMacAddrGet2(index: 0)
            break
        case .REMOTE,
             .WALL_REMOTE:
            remoteGetMacAddr(index: 0)
            remoteGetMacAddr2(index: 0)
            break
        case .GATEWAY:
            gwMacAddrGet(index: 255)
            gwMacAddrGet2(index: 255)
            break
        default:
            getDeviceMacAddress(deviceid: 0, deviceType: type, index: 1)
            getDeviceMacAddress(deviceid: 0, deviceType: type, index: 2)
        }
    }
    
    private func getDeviceMacAddress(deviceid:Int,deviceType:Int,index:Int){
        var cmd:[UInt8] = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x00,0x03,0x21,0x04]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        
        cmd[5] = UInt8(deviceid & 0xff)
        cmd[11] = UInt8(deviceType)
        cmd[13] = index == 1 ? 0x21: 0x22
        cmd[14] = index == 1 ? 4: 2
        
        sendCommand(cmd: &cmd, len: 15)
    }
    
    private func sensorMacAddrGet(index:Int){
        var cmd:[UInt8] = [0xC4,0xB2,0x16,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x02,0x03,0x21,0x04,0x00,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        
        cmd[5] = UInt8(index & 0xff);
        sendCommand(cmd: &cmd, len: 17)
    }
    private func sensorMacAddrGet2(index:Int){
        var cmd:[UInt8] = [0xC4,0xB3,0x16,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x02,0x03,0x22,0x02,0x00,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        
        cmd[5] = UInt8(index & 0xff);
        sendCommand(cmd: &cmd, len: 17)
    }

    private func gwMacAddrGet(index:Int){
        var cmd:[UInt8] = [0xC4,0xB7,0x16,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x04,0x03,0x21,0x04,0x00,0x00]
        cmd[5] = UInt8(index & 0xff);
        sendCommand(cmd: &cmd, len: 17)
    }
    
    private func gwMacAddrGet2(index:Int){
        var cmd:[UInt8] = [0xC4,0xB7,0x16,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x04,0x03,0x22,0x02,0x00,0x00]
        cmd[5] = UInt8(index & 0xff);
        sendCommand(cmd: &cmd, len: 17)
    }
    

    private func remoteGetMacAddr(index:Int){
        var cmd:[UInt8] = [0xC4,0xB3,0x16,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x03,0x05,0x21,0x04,0x00,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        if(index < 256) {
            if(index > 0) {
                cmd[5] = UInt8(index & 0xff);
            }
        } else {
            cmd[5] = UInt8((index >> 8) & 0xff);
        }
        sendCommand(cmd: &cmd, len: 17)
    }

    private func remoteGetMacAddr2(index:Int){
        var cmd:[UInt8] = [0xC4,0xB4,0x16,0x00,0x00,0x00,0x00,0xF0,0x11,0x02,0x01,0x03,0x05,0x22,0x02,0x00,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        if(index < 256) {
            if(index > 0) {
                cmd[5] = UInt8(index & 0xff);
            }
        } else {
            cmd[5] = UInt8((index >> 8) & 0xff);
        }
        sendCommand(cmd: &cmd, len: 17)
    }
    
    func getScene(target:Int,sceneID:Int){
        var cmd:[UInt8] = [0x11,0x11,0x6e,0x00,0x00,0x00,0x00,0xc0,0x11,0x02,0x0a,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        cmd[5] = UInt8(target & 0xff)
        cmd[6] = UInt8((target >> 8) & 0xff)
        cmd[11] = UInt8(sceneID)
        sendCommand(cmd: &cmd, len: 12)
    }
    
    func getAniScene(target:Int,aniSceneID:Int,frameID:Int){
        var cmd:[UInt8] = [0x11,0x12,0x54,0x00,0x00,0x00,0x00,0xf6,0x11,0x02,0x93,0x00,0x00,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        cmd[5] = UInt8(target & 0xff)
        cmd[6] = UInt8((target >> 8) & 0xff)
        cmd[11] = UInt8(aniSceneID)
        cmd[12] = UInt8(frameID)
        sendCommand(cmd: &cmd, len: 13)
    }
    
    func getSchedule(target:Int,scheduleID:Int){
        var cmd:[UInt8] = [0x11,0x12,0x54,0x00,0x00,0x00,0x00,0xE6,0x11,0x02,0x10,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        cmd[5] = UInt8(target & 0xff)
        cmd[6] = UInt8((target >> 8) & 0xff)
        cmd[11] = UInt8(scheduleID)
        sendCommand(cmd: &cmd, len: 13)
    }
    
    func getTime(target:Int){
        var cmd:[UInt8] = [0x11,0x12,0x57,0x00,0x00,0x00,0x00,0xE8,0x11,0x02,0x10]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        cmd[5] = UInt8(target & 0xff)
        cmd[6] = UInt8((target >> 8) & 0xff)
        sendCommand(cmd: &cmd, len: 12)
    }
    
    func getMotion(target:Int,type:MotionCMDType){
        var cmd:[UInt8] = [0x11,0x11,0x5c,0x00,0x00,0x00,0x00,0xf4,0x11,0x02,0x20,0x00]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        cmd[5] = UInt8(target & 0xff)
        cmd[6] = UInt8((target >> 8) & 0xff)
        cmd[11] = UInt8(type.rawValue)
        sendCommand(cmd: &cmd, len: 12)
    }
    
    func getRemote(target:Int,type:RemoteCMDType){
        var cmd:[UInt8] = [0x11,0x11,0x5c,0x00,0x00,0x00,0x00,0xf6,0x11,0x02,0x20]
        cmd[2] = cmd[2] + UInt8(addIndex)
        if cmd[2]>=254 {
            addIndex = 0
            cmd[2]=1;
        }
        addIndex += 1
        cmd[5] = UInt8(target & 0xff)
        cmd[6] = UInt8((target >> 8) & 0xff)
        cmd[10] = UInt8(type.rawValue)
        sendCommand(cmd: &cmd, len: 11)
    }
    
    func sendCommand(cmd:UnsafeMutablePointer<UInt8>,len:Int){
        //print("sendCommand")
        let cmdArr = changeCommandToArray(cmd: cmd, len: len)
        if (cmd[7]==0xd0 || cmd[7]==0xd2 || cmd[7]==0xe2) {
            timer?.addQueue { [self] in
                cmdTimer(temp: cmdArr)
            }
        }else{
            timer?.addQueue { [self] in
                cmdTimer(temp: cmdArr)
            }
        }
    }
    
    func cmdTimer(temp:NSArray){
        //print("cmdTimer")
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
        //print("exeCMD")
        logByte(bytes: cmd, len: len, str: "exeCMD")
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 20)
        let sec_ivm = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
        
        memset(buffer, 0, 20);
        memcpy(buffer, cmd, len);
        memset(sec_ivm, 0,8);
        
        getNextSeq()
        buffer[0] = UInt8(snNo & 0xff);
        buffer[1] = UInt8((snNo>>8) & 0xff);
        buffer[2] = UInt8((snNo>>16) & 0xff);
        
        let tempMac = tempDevice?.macAddress ?? 0
        
        sec_ivm[0]=UInt8((tempMac>>24) & 0xff);
        sec_ivm[1]=UInt8((tempMac>>16) & 0xff);
        sec_ivm[2]=UInt8((tempMac>>8) & 0xff);
        sec_ivm[3]=UInt8(tempMac & 0xff);
        
        sec_ivm[4]=1;
        sec_ivm[5]=buffer[0];
        sec_ivm[6]=buffer[1];
        sec_ivm[7]=buffer[2];

        CryptoAction.encryptionPpacket(sectionKey, iv: sec_ivm, mic: buffer+3, micLen: 2, ps: buffer+5, len: 15)
        writeValue(characteristic: commandFeature, buffer: buffer, len: 20, type: .withResponse)
    }

    func logByte(bytes:UnsafeMutablePointer<UInt8>,len:Int,str:String){
        var tempStr = ""
        for i in 0..<len{
            //let hex = Int.init(bytes[i])
            tempStr += String(format: "%02X ", bytes[i])
        }
        print("\(str) \(tempStr)")
        if str == "Notify"{
            let data = NSData.init(bytes: bytes, length: len)
            //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Rec_Notify"), object: self, userInfo: ["Rec_Notify":str,"byteData":data])
        }
    }
    
    func logData(data:Data?,len:Int,str:String){
        if var d = data{
            d.withUnsafeMutableBytes { (tempData:UnsafeMutablePointer<UInt8>) -> Void in
                logByte(bytes: tempData, len: len, str: str)
            }
        }
    }

    func writeValue(characteristic:CBCharacteristic?,buffer:UnsafeMutablePointer<UInt8>,len:Int,type:CBCharacteristicWriteType){
        //print("writeValue")
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
    
    func getNextSeq()->Int{
        snNo += 1
        if snNo>CBCManager.MaxSnValue{
            snNo = 1
        }
        return snNo
    }
    
    //解析資料
    func pasterData(buffer:UnsafeMutablePointer<UInt8>){
        //print("pasterData:\(buffer)")
        let tempMac = tempDevice.macAddress ?? 0
        let sec_ivm = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
        
        sec_ivm[0] = UInt8((tempMac >> 24) & 0xff)
        sec_ivm[1] = UInt8((tempMac >> 16) & 0xff)
        sec_ivm[2] = UInt8((tempMac >> 8) & 0xff)
        
        memcpy(sec_ivm+3, buffer, 5);
        
        if (!(buffer[0] == 0 && buffer[1] == 0 && buffer[2] == 0))
        {
            if CryptoAction.decryptionPpacket(sectionKey, iv: sec_ivm, mic: buffer+5, micLen: 2, ps: buffer+7, len: 13){
                
            }else{
                //解密失敗
            }
        }
        logByte(bytes: buffer, len: 20, str: "pasterData")
        sendDevNotify(bytes:buffer)
    }

    func sendDevNotify(bytes:UnsafeMutablePointer<UInt8>){
        passUsefulMessageWithBytes(bytes:bytes)
        
    }
    
    //解析資料
    func passUsefulMessageWithBytes(bytes:UnsafeMutablePointer<UInt8>){
        if (bytes[8]==0x11 && bytes[9]==0x02 && bytes[7] == 0xe1) {
            //設定id回傳
            var mac = ""
            for i in 12...17{
                mac += String(format: "%02X", bytes[i])
            }
            
            //直連燈不用判斷mac
            if /*tempDevice.mac == reverseString(str: mac),*/bytes[10] == newDevId{
                del?.SetDeviceIdCb?(device:tempDevice, success:true)
            }else{
                del?.SetDeviceIdCb?(device:tempDevice, success:false)
            }
            return
        }
        
        if (bytes[7] == 0xd4 && bytes[8] == 0x11 && bytes[9] == 0x02) {
            //set group
            logByte(bytes: bytes, len: 20, str: "DevOperaStatus_SetGroup")
            waitCBTimer?.suspend()
            waitCBTimer = nil
            if connectStatus == .DevOperaStatus_SetGroup{
                del?.SetGroupCb?(device: tempDevice, success: true)
            }
            return
        }
        
        if (bytes[7] == 0xdc && bytes[8] == 0x11 && bytes[9] == 0x02) {
            //print("light status")
            //print(bytes[10])
            //print(bytes[13])
            //print(bytes[14])
            //print(bytes[17])
            for device in devices{
                if device.isKoreaVer{
                    if device.device_id == bytes[10]{
                        print("Korea_type \(device.mac) \(bytes[10]) isKoreaVer:\(bytes[13])")
                        device.deviceType = Int(bytes[13])
                        del?.OnlineAllResult?(device: device)
                    }else if device.device_id == bytes[14]{
                        print("Korea_type \(device.mac) \(bytes[14]) isKoreaVer:\(bytes[17])")
                        device.deviceType = Int(bytes[17])
                        del?.OnlineAllResult?(device: device)
                    }
                }
            }
            
            return
        }
        
        if (bytes[7] == 0xea && bytes[8] == 0x11 && bytes[9] == 0x02) {
            
            if bytes[14] == 0x21 && bytes[15] == 0x04{
                var mac = ""
                for i in 16...19{
                    mac += String(format: "%02X", bytes[i])
                }
                tempMac = reverseString(str: mac)
                print("getmac \(tempDevice.mac) tempmac:\(tempMac)")
            }else if bytes[14] == 0x22 && bytes[15] == 0x02{
                waitCBTimer?.suspend()
                waitCBTimer = nil
                var mac = ""
                for i in 16...17{
                    mac += String(format: "%02X", bytes[i])
                }
                tempMac = reverseString(str: mac) + tempMac
                print("getmac \(tempDevice.mac) tempmac:\(tempMac)")
                if tempMac.count<10{
                    del?.GetMacCb?(device: tempDevice,success: false,newMac: "")
                }else{
                    del?.GetMacCb?(device: tempDevice,success: true,newMac: tempMac)
                }
            }
            return
        }
    }
    
    //設定notify
    func setNotifyOpenPro(){
        //print("setNotifyOpenPro")
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        buffer[0] = 1
        
        writeValue(characteristic: notifyFeature, buffer: buffer, len: 1, type: .withResponse)
    }
}

extension CBCManager:CBCentralManagerDelegate{
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
        //print(peripheral)
        //print(advertisementData)

        var deviceName = ""
        if let name = advertisementData["kCBAdvDataLocalName"] as? String{
            deviceName = name
        }
        /*
        //只加入endo產品
        if deviceName != GlobalData.PERSONAL_DEVICE_NAME {
            return
        }*/
        guard let nsdata = advertisementData["kCBAdvDataManufacturerData"] as? NSData else{
            return
        }
        //print("nsdata:\(nsdata)")
        let publicData = Data(bytes: nsdata.bytes, count: Int(nsdata.length))
        let str = publicData.dataToHexString
        if str.count<30{
            return
        }
        //print("str:\(str)")
        //device
        let tempVid = str.substring(from: 0, count: 4).strHex2Int()
        if tempVid != CBCManager.BTDevInfo_UID{
            return
        }
        //print("tempVid:\(tempVid)")
        let device_type = str.substring(from: 44,count: 2).strHex2Int()

        //特殊型號
        let korea_var = str.substring(from: 58,count: 12)
        //支援型號
        if SystemData.DeviceType.init(rawValue: device_type) == nil && korea_var != KOREA_VAR{
            print("device_type:\(device_type)")
            print("korea_var:\(korea_var)")
            //return
        }
        
        let uuid = peripheral.identifier.uuidString
        let device = CBCDevice()
        device.peripheral = peripheral
        device.uuid = uuid
        device.device_name = peripheral.name
        device.mesh_name = deviceName
        device.rssi = RSSI.intValue
        device.facturer_id = tempVid
        //device.meshuuid = str.substring(from: 4,count: 4).strHex2Int()
        let mac = str.substring(from: 8,count: 8)
        let title = str.substring(from: 56,count: 4)
        device.macAddress = mac.strHex2Int()
        device.mac = reverseString(str: title).uppercased() + reverseString(str: mac).uppercased()
        let header = str.substring(from: 28,count: 2)
        let tailer = str.substring(from: 30,count: 2)
        device.productId = (header + tailer).strHex2Int()
        device.status = str.substring(from: 32,count: 2).strHex2Int()
        
        //注意:app only use low byte as address
        //device address:e7 00 app:e7
        let deviceAddress = str.substring(from: 34,count: 2).strHex2Int()
        device.device_id = deviceAddress
        device.deviceType = device_type
        device.firmware = str.substring(from: 48,count: 8).strHex2Int()
        if korea_var == KOREA_VAR{
            device.isKoreaVer = true
        }
        device.otaCode = str.substring(from: 62,count: 2).strHex2Int()
        device.sType = str.substring(from: 68,count: 2).strHex2Int()
        
        //已有重複
        if let dev = (devices?.filter({ return $0.mac == device.mac})),dev.count>0{
            print("exist \(device.mac)")
            return
        }
        //devices?.append(device)
        print("device.device_id\(device.device_id)")
        print("device.mac\(device.mac)")
        print("device.rssi\(device.rssi)")
        if let bo = del?.ScanDeviceResult?(device:device),bo{
            devices?.append(device)
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
        print("fail to connect to peipheral:\(error)")
        if connectStatus == .DevOperaStatus_Connect_Start || connectStatus == .DevOperaStatus_Login_Start{
            waitCBTimer?.suspend()
            waitCBTimer = nil
            del?.onConnectFinish?(device: tempDevice, success: false)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnect")
        //如果是剔除中。當作完成剔除
        if isKickout{
            waitCBTimer?.suspend()
            waitCBTimer = nil
            isKickout = false
            del?.SetKickoutCb?(device: tempDevice, success: true)
        }
        
        print("Disconnect status\(connectStatus)")
        print("Disconnect timer\(waitCBTimer)")
    }
}


extension CBCManager:CBPeripheralDelegate{
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        if error != nil{
            print(error)
            return
        }
        
        guard  let services = peripheral.services else {
            return
        }
        for item in services{
            if item.uuid == CBUUID.init(string: CBCManager.BTDevInfo_ServiceUUID){
                peripheral.discoverCharacteristics(nil, for: item)
                
            }
            /*else if item.uuid.isEqual(UUID.init(uuidString: Service_Device_Information)){
                peripheral.discoverCharacteristics(nil, for: item)
            }*/
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        if error != nil{
            print(error)
            return
        }
        
        guard  let characteristics = service.characteristics else {
            return
        }
        
        for item in characteristics{
            print("characteristics\(item)")
            if item.uuid == CBUUID(string: CBCManager.BTDevInfo_FeatureUUID_Notify){
                peripheral.setNotifyValue(true, for: item)
                notifyFeature = item
            }else if item.uuid == CBUUID(string: CBCManager.BTDevInfo_FeatureUUID_Command){
                commandFeature = item
            }else if item.uuid == CBUUID(string: CBCManager.BTDevInfo_FeatureUUID_Pair){
                pairFeature = item
                loginWithPwd()
            }else if item.uuid == CBUUID(string: CBCManager.BTDevInfo_FeatureUUID_OTA){
                otaFeature = item
            }else if item.uuid == CBUUID(string: CBCManager.Characteristic_Firmware){
                fireWareFeature = item
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("didWriteValueFor")
        if error != nil{
            print(error)
            return
        }

        logData(data: characteristic.value, len: 20, str: "")
        //print("characteristic\(characteristic)")
        if characteristic == pairFeature{
            readIndex += 1
            var isRead = false
            if connectStatus == .DevOperaStatus_SetName_Start || connectStatus == .DevOperaStatus_SetPassword_Start || connectStatus == .DevOperaStatus_SetLtk_Start{
                if readIndex == 3{
                    isRead = true
                }
            }else{
                isRead = true
            }
            if isRead{
                //通知 didUpdateValueFor
                tempPeripherals.readValue(for: pairFeature)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("didUpdateValueFor")
        if error != nil{
            print(error)
            return
        }
        //print("characteristic\(characteristic)")
        
        guard var data = characteristic.value else{
            return
        }
        logData(data: characteristic.value, len: 20, str: "")
        
        if characteristic == pairFeature{
            //登入判斷
            if connectStatus == .DevOperaStatus_Login_Start{
                data.withUnsafeMutableBytes { (tempData:UnsafeMutablePointer<UInt8>) -> Void in
                    waitCBTimer?.suspend()
                    waitCBTimer = nil
                    if tempData[0] == 13{
                        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
                        if CryptoAction.encryptPair(meshName, pas: meshPassword, prand: tempData + 1, pResult: buffer){
                            memset(buffer, 0, 16)
                            CryptoAction.getSectionKey(meshName, pas: meshPassword, prandm: loginRand, prands: tempData+1, pResult: buffer)
                            memcpy(sectionKey,buffer,16)

                            isLogin = true
                            connectStatus = .DevOperaStatus_Login_Finish
                            
                            //notify設定
                            notifyTimer = SwiftTimer.init(interval: .milliseconds(500), handler: { [self] (timer) in
                                self.setNotifyOpenPro()
                            })
                            notifyTimer.start()
             
                            //登入完成後回傳
                            loginTImer = SwiftTimer.init(interval: .milliseconds(1500), handler: { [self] (timer) in
                                waitCBTimer?.suspend()
                                waitCBTimer = nil
                                del?.onConnectFinish?(device:tempDevice,success: true)
                                if actionAfterLogin != nil{
                                    let act = actionAfterLogin
                                    actionAfterLogin = nil
                                    switch act {
                                    case .Blink:
                                        deviceBlink(device: tempDevice)
                                    case .StopBlink:
                                        stopBlink(device: tempDevice)
                                    case .Kickout:
                                        kickDevice(device: tempDevice)
                                    case .SetDevAddress:
                                        setDeviceId(device: tempDevice, id: newDevId)
                                    case .SetMesh:
                                        configMesh()
                                    case .GetMac:
                                        getMac(device: tempDevice)
                                    default:
                                        break;
                                    }
                                }
                            })
                            loginTImer.start()
                            
                        }
                    }else{
                        del?.onConnectFinish?(device:tempDevice,success: false)
                    }
                }
            }else if connectStatus == .DevOperaStatus_SetName_Start || connectStatus == .DevOperaStatus_SetPassword_Start || connectStatus == .DevOperaStatus_SetLtk_Start{
                
                data.withUnsafeMutableBytes { (tempData:UnsafeMutablePointer<UInt8>) -> Void in
                    waitCBTimer?.suspend()
                    waitCBTimer = nil
                    connectStatus = .DevOperaStatus_SetNetwork_Finish
                    del?.SetMeshCb?(device: tempDevice,success: tempData[0] == 7)
                }
            }
        }else if(characteristic == commandFeature){
            /*
            //set device id
            guard var data = characteristic.value else{
                return
            }
            print("set device id:\(isLogin)")
            if connectStatus == .DevOperaStatus_SetDevAddress{
                connectStatus = .DevOperaStatus_SetDevAddress_Finish
                waitCBTimer?.suspend()
                waitCBTimer = nil
                if isLogin{
                    data.withUnsafeMutableBytes { (tempData:UnsafeMutablePointer<UInt8>) -> Void in
                        pasterData(buffer:tempData)
                    }
                }else{
                    del?.SetDeviceIdCb(device:tempDevice, success:false)
                }
            }*/
        }else if characteristic == self.notifyFeature{
            
            guard var data = characteristic.value else{
                return
            }
            data.withUnsafeMutableBytes { (tempData:UnsafeMutablePointer<UInt8>) -> Void in
                pasterData(buffer:tempData)
            }
        }
    }
}
