//
//  SystemData.swift
//  EndoPersonal
//
//  Created by 陳力維 on 2020/11/2.
//

import SwiftyJSON

class SystemData  {

    //ble單次加燈上限
    public static var BLE_ADD_LIMIT = 15
    //房間裝置上限(包含gateway)
    public static var DEVICE_LIMIT = 251
    //燈泡圖片提供數量
    public static var LAMP_ICON_COUNT = 9
    //room上限
    public static var MAX_ROOM_COUNT = 20
    //group上限
    public static var MAX_GROUP_COUNT = 20
    //scene上限
    public static var MAX_SCENE_COUNT = 10
    //schedule上限
    public static var MAX_SCHEDULE_COUNT = 8
    //sensor上限
    public static var MAX_SENSOR_PIR_COUNT = 6
    //schedule 存scene上限
    public static var MAX_SCENE_DETAIL_IN_SCHEDULE = 30
    //
    public static var MAX_SENSOR_LIGHT_COUNT = 1
    
    //system info memo
    public static let MEMO_BACKTIME = "backtime"
    public static let MEMO_SOUND = "sound"
    public static let MEMO_INIT_FINISH = "initial_finish"
    public static let MEMO_FW_VERSION = "fw_version"
    public static let MEMO_OTA_VERSION = "ota_version"
    //共用sensor data
    public static let MEMO_SENSOR_DATA = "room_sensor"

    public static let MANAGE_PASSWORD = "12345678"
    
    class Icon {
        var photo1 = ""
        var photo2 = ""
        var photo3 = ""
        var icon = ""
        var iconName = ""

        public init(icon:String) {
            self.icon = icon
        }
        
        public init(icon:String,iconName:String) {
            self.icon = icon
            self.iconName = iconName
        }
        
        public init(photo1:String,photo2:String,photo3:String) {
            self.photo1 = photo1
            self.photo2 = photo2
            self.photo3 = photo3
        }
    }
    
    /*Room 圖片對照   */
    static var RoomIconData:Dictionary<Int,Icon> =
        [
            0:Icon.init(icon: "ic_room", iconName: NSLocalizedString("room", comment: "")),
            1:Icon.init(icon: "ic_room_living", iconName: NSLocalizedString("room_living", comment: "")),
            2:Icon.init(icon: "ic_room_dining", iconName: NSLocalizedString("room_dining", comment: "")),
            3:Icon.init(icon: "ic_room_kitchen", iconName: NSLocalizedString("room_kitchen", comment: "")),
            4:Icon.init(icon: "ic_room_gallery", iconName: NSLocalizedString("room_gallery", comment: "")),
            5:Icon.init(icon: "ic_room_toilet", iconName: NSLocalizedString("room_toilet", comment: "")),
            6:Icon.init(icon: "ic_room_wash_face", iconName: NSLocalizedString("room_wash_face", comment: "")),
            7:Icon.init(icon: "ic_room_japanese", iconName: NSLocalizedString("room", comment: "")),
            8:Icon.init(icon: "ic_room_bed", iconName: NSLocalizedString("room", comment: "")),
            9:Icon.init(icon: "ic_room_office", iconName: NSLocalizedString("room", comment: "")),
            10:Icon.init(icon: "ic_room_meeting", iconName: NSLocalizedString("room", comment: "")),
            11:Icon.init(icon: "ic_room_rest", iconName: NSLocalizedString("room", comment: "")),
            12:Icon.init(icon: "ic_room_garden", iconName: NSLocalizedString("room", comment: "")),
        ]
    
    static func GetRoomIcon(icon:Int)->Icon{
        if let result = RoomIconData[icon]{
            return result
        }
        return RoomIconData.first!.value
    }
    
    /*Room 圖片對照   */
    static var RoomPicData:Dictionary<Int,Icon> =
        [
            0:Icon.init(photo1: "bg_0_1",photo2: "bg_0_2",photo3: "bg_0_3"),
            1:Icon.init(photo1: "bg_1_1",photo2: "bg_1_2",photo3: "bg_1_3"),
            2:Icon.init(photo1: "bg_2_1",photo2: "bg_2_2",photo3: "bg_2_3"),
            3:Icon.init(photo1: "bg_3_1",photo2: "bg_3_2",photo3: "bg_3_3"),
            4:Icon.init(photo1: "bg_4_1",photo2: "bg_4_2",photo3: "bg_4_3"),
            5:Icon.init(photo1: "bg_5_1",photo2: "bg_5_2",photo3: "bg_5_3"),
            6:Icon.init(photo1: "bg_6_1",photo2: "bg_6_2",photo3: "bg_6_3"),
            7:Icon.init(photo1: "bg_7_1",photo2: "bg_7_2",photo3: "bg_7_3"),
            8:Icon.init(photo1: "bg_8_1",photo2: "bg_8_2",photo3: "bg_8_3"),
            9:Icon.init(photo1: "bg_9_1",photo2: "bg_9_2",photo3: "bg_9_3"),
            10:Icon.init(photo1: "bg_10_1",photo2: "bg_10_2",photo3: "bg_10_3"),
            11:Icon.init(photo1: "bg_11_1",photo2: "bg_11_2",photo3: "bg_11_3"),
            12:Icon.init(photo1: "bg_12_1",photo2: "bg_12_2",photo3: "bg_12_3"),
            13:Icon.init(photo1: "bg_13_1",photo2: "bg_13_2",photo3: "bg_13_3"),
            14:Icon.init(photo1: "bg_14_1",photo2: "bg_14_2",photo3: "bg_14_3"),
            15:Icon.init(photo1: "bg_15_1",photo2: "bg_15_2",photo3: "bg_15_3"),
        ]
    
    static func GetRoomPic(photo:Int)->Icon{
        if let result = RoomPicData[photo]{
            return result
        }
        return RoomPicData.first!.value
    }

    // Mode:0=manual, 0x01=off, 0x82=sensor, 0x03=scene, 0x04=schedule
    static func GetRoomStatusIcon(mode:Int)->String{
        switch mode{
        case 0:
            return "ic_during_manual_operation"
        case 0x01:
            return ""
        case 0x82:
            return "ic_sensor"
        case 0x03:
            return "ic_scene_new"
        case 0x04:
            return "ic_schedule"
        default:
            return ""
        }
    }
    
    static func GetRoomStatusDescription(mode:Int)->String{
        switch mode{
        case 0:
            return "during_manual_operation"
        case 0x01:
            return "during_off_operation"
        case 0x82:
            return "during_sensor_operation"
        case 0x03:
            return "during_scene_operation"
        case 0x04:
            return "during_scheduled_operation"
        default:
            return "during_off_operation"
        }
    }
    

    static var SceneData:Dictionary<Int,Icon> =
        [
            0:Icon.init(icon: "ic_scene0",iconName: NSLocalizedString("scene_name_0", comment: "")),
            1:Icon.init(icon: "ic_scene1", iconName: NSLocalizedString("scene_name_1", comment: "")),
            2:Icon.init(icon: "ic_scene2", iconName: NSLocalizedString("scene_name_2", comment: "")),
            3:Icon.init(icon: "ic_scene3", iconName: NSLocalizedString("scene_name_3", comment: "")),
            4:Icon.init(icon: "ic_scene4", iconName: NSLocalizedString("scene_name_4", comment: "")),
            5:Icon.init(icon: "ic_scene5", iconName: NSLocalizedString("scene_name_5", comment: "")),
            6:Icon.init(icon: "ic_scene6", iconName: NSLocalizedString("scene_name_6", comment: "")),
            7:Icon.init(icon: "ic_scene7", iconName: NSLocalizedString("scene_name_7", comment: "")),
            8:Icon.init(icon: "ic_scene8", iconName: NSLocalizedString("scene_name_8", comment: "")),
            9:Icon.init(icon: "ic_scene9", iconName: NSLocalizedString("scene_name_9", comment: "")),
            10:Icon.init(icon: "ic_scene10", iconName: NSLocalizedString("", comment: "")),
            11:Icon.init(icon: "ic_scene11", iconName: NSLocalizedString("", comment: "")),
            12:Icon.init(icon: "ic_scene12", iconName: NSLocalizedString("", comment: "")),
            13:Icon.init(icon: "ic_scene13", iconName: NSLocalizedString("", comment: "")),
            14:Icon.init(icon: "ic_scene14", iconName: NSLocalizedString("", comment: "")),
        ]
    
    static func GetSceneIcon(icon:Int)->Icon{
        if let scene = SceneData[icon]{
            return scene
        }
        return SceneData.first!.value
    }
        
    
    static var LampData:Dictionary<Int,Icon> =
        [
            0:Icon.init(icon: "ic_lamp",iconName: NSLocalizedString("bulb", comment: "")),
            1:Icon.init(icon: "ic_down_light", iconName: NSLocalizedString("down_light", comment: "")),
            2:Icon.init(icon: "ic_spot_light", iconName: NSLocalizedString("spot_light", comment: "")),
            3:Icon.init(icon: "ic_indirect_light", iconName: NSLocalizedString("indirect_light", comment: "")),
            4:Icon.init(icon: "ic_pendant_light", iconName: NSLocalizedString("pendant_light", comment: "")),
            5:Icon.init(icon: "ic_chandelier_light", iconName: NSLocalizedString("chandelier_light", comment: "")),
            6:Icon.init(icon: "ic_stand_light", iconName: NSLocalizedString("stand_light", comment: "")),
            7:Icon.init(icon: "ic_bracket", iconName: NSLocalizedString("bracket", comment: "")),
            8:Icon.init(icon: "ic_garden_light", iconName: NSLocalizedString("garden_light", comment: "")),
        ]
    //有換過再使用
    static func GetLampIcon(icon:Int)->Icon{
        if let scene = LampData[icon]{
            return scene
        }
        return LampData.first!.value
    }
    
    static func GetGroupIcon()->String{
        return "ic_group"
    }
    
    static func GetLampCh(typecode:Int)->String?{
        let type = DeviceType.init(rawValue: typecode & 0x7f)
        switch (type){
        case .LAMP:
            return nil
        case .LAMP_2CH:
            return "ic_type_2ch"
        case .LAMP_3CH
             ,.LIGHT_RGB:
            return "ic_type_3ch"
        case .LIGHT_RGBW:
            return "ic_type_3ch"
        case .LIGHT_RGB_CW_WW:
            return "ic_type_3ch"
        case .LIGHT_1CH_BEACON:
            return nil
        case .LIGHT_2CH_BEACON:
            return "ic_type_2ch"
        case .LIGHT_3CH_BEACON:
            return "ic_type_3ch"
        default:
            return nil
        }
    }
    
    static func GetGroupCh(type:Int)->String?{
        switch (type){
        case 2:
            return "ic_type_2ch"
        case 3:
            return "ic_type_3ch"
        default:
            return nil
        }
    }
    
    
    
    /*顏色對照表 */
    class RGB{
        var R:Int!
        var G:Int!
        var B:Int!
        
        init(r:Int,g:Int,b:Int) {
            R = r
            G = g
            B = b
        }
        
        
        func toInt16()->Int{
            return R * 256 * 256 + G * 256 + B
        }
    }
    
    //show
    static func GetShowColor11()->[[RGB]]{
        let list = "236,255,39,228,255,78,221,255,118,213,255,158,206,255,200,198,255,242,170,228,255,140,197,255,117,172,255,98,153,255,83,137,255,251,255,39,246,255,76,241,255,113,236,255,152,230,255,192,225,255,232,204,237,255,171,204,255,145,178,255,124,157,255,107,140,255,255,242,37,255,245,70,255,247,105,255,250,142,255,252,181,255,255,222,245,248,255,209,213,255,179,185,255,156,163,255,137,145,255,255,227,35,255,226,63,255,226,91,255,226,121,255,225,152,255,225,185,255,224,219,255,223,254,223,194,255,196,170,255,174,150,255,255,212,32,255,209,55,255,207,79,255,204,103,255,201,127,255,198,152,255,195,178,255,192,205,255,188,233,249,179,255,223,158,255,255,198,30,255,193,48,255,189,67,255,184,85,255,179,104,255,174,123,255,169,143,255,164,162,255,159,183,255,153,203,255,148,224,255,184,28,255,178,42,255,172,56,255,166,70,255,159,83,255,153,97,255,147,111,255,140,125,255,133,139,255,127,153,255,120,168,255,171,27,255,164,36,255,156,45,255,149,55,255,141,64,255,134,73,255,126,83,255,119,92,255,111,101,255,104,110,255,96,119,255,159,25,255,150,30,255,142,36,255,133,41,255,124,47,255,116,52,255,108,57,255,100,62,255,91,67,255,84,72,255,76,77,255,147,23,255,137,25,255,128,27,255,118,29,255,109,30,255,100,32,255,91,34,255,82,35,255,74,37,255,65,38,255,57,40,255,136,21,255,125,20,255,115,18,255,105,17,255,95,15,255,85,14,255,76,12,255,67,11,255,58,9,255,49,8,255,41,7"
        let arr = list.components(separatedBy: ",")
        var result = [[RGB]]()
        for i in 0..<11 {
            var rt = [RGB]()
            for j in 0..<11 {
                let index = (i * 11 + j) * 3
                if index + 2 >= arr.count {
                    break;
                }
                let rgb = RGB.init(r: arr[index].IntValue(), g: arr[index+1].IntValue(), b: arr[index+2].IntValue())
                rt.append(rgb)
            }
            result.append(rt)
        }
        
        return result
    }
    //input
    static func GetInputColor11()->[[RGB]]{
        let list = "0,255,0,0,255,28,0,248,62,0,217,93,0,186,124,0,155,155,0,124,186,0,93,217,0,62,248,0,28,255,0,0,255,13,255,0,16,255,27,19,235,56,20,206,84,22,176,111,23,147,139,25,118,167,26,88,195,28,59,223,29,29,251,28,0,255,28,255,0,34,251,25,37,223,50,40,195,74,43,167,99,46,139,124,50,111,149,53,84,173,56,56,198,59,28,223,62,0,248,45,255,0,51,237,22,56,211,43,60,184,65,65,158,87,70,132,108,74,105,130,79,79,152,84,53,173,88,26,195,93,0,217,62,248,0,68,223,19,74,198,37,81,173,56,87,149,74,93,124,93,99,99,111,105,74,130,111,50,149,118,25,167,124,0,186,77,232,0,85,209,15,93,186,31,101,163,46,108,139,62,116,116,77,124,93,93,132,70,108,139,46,124,147,23,139,155,0,155,93,217,0,102,195,12,111,173,25,121,152,37,130,130,50,139,108,62,149,7,74,158,65,87,167,43,99,176,22,111,186,0,124,108,201,0,119,181,9,130,161,19,141,141,28,152,121,37,163,101,46,173,81,56,184,60,65,195,40,74,206,20,84,217,0,93,124,186,0,136,167,6,149,149,12,161,130,19,173,111,25,186,93,31,198,74,37,211,56,43,223,37,50,235,19,56,248,0,62,139,170,0,153,153,3,167,136,6,181,119,9,195,102,12,209,85,15,223,68,19,237,51,22,251,34,25,255,16,27,255,0,28,155,155,0,170,139,0,186,124,0,201,108,0,218,93,0,232,77,0,248,62,0,255,45,0,255,28,0,255,13,0,255,0,0"
        let arr = list.components(separatedBy: ",")
        var result = [[RGB]]()
        for i in 0..<11 {
            var rt = [RGB]()
            for j in 0..<11 {
                let index = (i * 11 + j) * 3
                if index + 2 >= arr.count {
                    break;
                }
                let rgb = RGB.init(r: arr[index].IntValue(), g: arr[index+1].IntValue(), b: arr[index+2].IntValue())
                rt.append(rgb)
            }
            result.append(rt)
        }
        
        return result
    }
    
    
    static func ConvertShowColor11(int16:Int)->RGB?{
        let input = GetInputColor11()
        let show = GetShowColor11()
        for i in 0..<input.count{
            for j in 0..<input[i].count{
                if input[i][j].toInt16() == int16{
                    return show[i][j]
                }
            }
        }
        return nil//RGB.init(r: 0, g: 0, b: 0)
    }
    
    //gateway型號
    static func IsGateway(name:String)->Bool{
        let list = ["FX492","FX493"]
        let filter = list.filter({ (gatewayName) -> Bool in
            if name.contains(gatewayName){
                return true
            }
            return false
        })
        
        return filter.count>0
    }
    
    static func IsBigGateway(name:String)->Bool{
        let list = ["FX492"]
        let filter = list.filter({ (gatewayName) -> Bool in
            if name.contains(gatewayName){
                return true
            }
            return false
        })
        
        return filter.count>0
    }

    enum Device:Int{
        case GATEWAY = 0
        case REMOTE
        case SENSOR
        case WALL_REMOTE
        case REPEATER
        case THREE_CH
        case TWO_CH
        case ONE_CH
        case UNKNOWN
    }

    enum DeviceType:Int{
        case UNKNOWN = -1
        case LAMP = 0x01
        case LAMP_2CH = 0x02
        //case SENSOR = 0x05
        //case SENSOR_PIR = 0x15
        //case SENSOR_LUX = 0x25
        case LIGHT_RGB = 0x30
        case LIGHT_RGBW = 0x31
        case LIGHT_RGB_CW_WW = 0x32
        case REPEATER = 0x33
        case LAMP_3CH = 0x34
        case LIGHT_1CH_BEACON = 0x35
        case LIGHT_2CH_BEACON = 0x36
        case LIGHT_3CH_BEACON = 0x37
        case REMOTE = 0x38
        case WALL_REMOTE_ONE = 0x39
        case WALL_REMOTE_TWO = 0x3A
        case WALL_REMOTE_ADJUSTMENT = 0x3B
        case WSS = 0x3C
        case CSS = 0x3D
        case OSS = 0x3E
        case GATEWAY_BIG = 0x3F
        case GATEWAY_SMALL = 0x40
        case AC = 0x06
        case PWM = 0x07
        case A_CONTACT = 0x08
    }
    
    //裝置對照表
    static func DeviceName(typecode:Int,mac:String)->String{
        let type = typecode & 0x7f
        let macStr = mac.substring(from: mac.count - 3)
        var name = ""
        if DeviceType.init(rawValue: type) == nil{
            name = NSLocalizedString("default_name", comment: "") + "_\(macStr)"
        }else{
            name = NSLocalizedString("kind_name_\(type.Int2strHex(2).uppercased())", comment: "") + "_\(macStr)"
        }
        /*
        switch (DeviceType.init(rawValue: type)){
        case .LAMP:
            name = "WM1_" + macStr
        case .LAMP_2CH:
            name = "WM2_" + macStr
        case .LAMP_3CH
             ,.LIGHT_RGB:
            name = "RGB_" + macStr
        case .LIGHT_RGBW:
            name = "RGBW_" + macStr
        case .LIGHT_RGB_CW_WW:
            name = "RGBWW_" + macStr
        case .LIGHT_1CH_BEACON:
            name = "BEACON_WM1_" + macStr
        case .LIGHT_2CH_BEACON:
            name = "BEACON_WM2_" + macStr
        case .LIGHT_3CH_BEACON:
            name = "BEACON_RGB_" + macStr
        case //.SENSOR
             //,.SENSOR_LUX
             //,.SENSOR_PIR
             .OSS
             ,.CSS
             ,.WSS:
            name = "SENSOR_" + macStr
        case .GATEWAY_BIG
             ,.GATEWAY_SMALL:
            name = "GATEWAY_" + macStr
        case .REMOTE
             ,.WALL_REMOTE_ADJUSTMENT
             ,.WALL_REMOTE_ONE
             ,.WALL_REMOTE_TWO:
            name = "REMOTE_" + macStr
        case .REPEATER:
            name = "REPEATER_" + macStr
        case .AC:
            name = "Phease_" + macStr
        case .PWM:
            name = "PWM_" + macStr
        case .A_CONTACT:
            name = "A Contact_" + macStr
        default:
            name = "Unknow_" + macStr
            break;
        }*/
        
        return name
    }
    
    //ble加燈時會加上0x80。gateway尚未辨識前要先& 0x7f
    static func GetDeviceType(typecode:Int,with7f:Bool = true)->Device{
        let code = with7f ? typecode & 0x7f : typecode
        let type = DeviceType.init(rawValue: code)
        switch (type){
        case .LAMP:
            return .ONE_CH
        case .LAMP_2CH:
            return .TWO_CH
        case .LAMP_3CH
             ,.LIGHT_RGB:
            return .THREE_CH
        case .LIGHT_RGBW:
            return .THREE_CH
        case .LIGHT_RGB_CW_WW:
            return .THREE_CH
        case .LIGHT_1CH_BEACON:
            return .ONE_CH
        case .LIGHT_2CH_BEACON:
            return .TWO_CH
        case .LIGHT_3CH_BEACON:
            return .THREE_CH
        case //.SENSOR
             //,.SENSOR_LUX
             //,.SENSOR_PIR
             .OSS
             ,.CSS
             ,.WSS:
            return .SENSOR
        case .GATEWAY_BIG
             ,.GATEWAY_SMALL:
            return .GATEWAY
        case .REMOTE:
            return .REMOTE
        case .WALL_REMOTE_ADJUSTMENT
             ,.WALL_REMOTE_ONE
             ,.WALL_REMOTE_TWO:
            return .WALL_REMOTE
        case .REPEATER:
            return .REPEATER
        case .AC,
             .PWM,
             .A_CONTACT:
            return .ONE_CH
        default:
            return .UNKNOWN
        }
    }
    
    static func GetDeviceIcon(typecode:Int)->String{
        let type = DeviceType.init(rawValue: typecode & 0x7f)
        switch (type){
        case .LAMP:
            return "ic_lamp"
        case .LAMP_2CH:
            return "ic_lamp"
        case .LAMP_3CH
             ,.LIGHT_RGB:
            return "ic_lamp"
        case .LIGHT_RGBW:
            return "ic_lamp"
        case .LIGHT_RGB_CW_WW:
            return "ic_lamp"
        case .LIGHT_1CH_BEACON:
            return"ic_lamp"
        case .LIGHT_2CH_BEACON:
            return "ic_lamp"
        case .LIGHT_3CH_BEACON:
            return "ic_lamp"
        case //.SENSOR
             //,.SENSOR_LUX
             //,.SENSOR_PIR
             .OSS
             ,.CSS
             ,.WSS:
            return "ic_sensor"
        case .GATEWAY_BIG:
            return "ic_gateway_big"
        case .GATEWAY_SMALL:
            return "ic_gateway_small"
        case .REMOTE:
            return "ic_remote"
        case .WALL_REMOTE_ADJUSTMENT:
             return "ic_wall_remote_adjustment"
        case .WALL_REMOTE_ONE:
            return "ic_wall_remote_one"
        case .WALL_REMOTE_TWO:
            return "ic_wall_remote_two"
        case .REPEATER:
            return "ic_repeater"
        case .AC,
             .PWM,
             .A_CONTACT:
            return "ic_a_contact_pwm_phase"
        default:
            return "ic_unknow"
        }
    }

    
    //控制器數量
    static func GetDeviceControlCount(typecode:Int)->Int{
        let type = DeviceType.init(rawValue: typecode & 0x7f)
        switch (type){
        case .WALL_REMOTE_ONE:
            return 1
        case .WALL_REMOTE_TWO:
            return 2
        case .REMOTE:
            return 4
        case .GATEWAY_BIG:
            return 8
        case .GATEWAY_SMALL:
            return 4
        default:
            return 0
        }
    }


    enum DefaultRoomType:Int {
        case house = 0
        case office = 1
        case restaurant = 2
        case hotel = 3
        case custom = 4
    }
    
    //假資料流水號
    static var defaultFloatNumber = 1000
    static var floatNumber = 1050
}
