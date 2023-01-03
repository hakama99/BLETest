//
//  ViewController.swift
//  BLE test
//
//  Created by 陳力維 on 2022/7/5.
//

import UIKit

class TargetViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var meshNameLabel: UILabel!
    @IBOutlet weak var meshPasswordTextfield: UITextField!
    @IBOutlet weak var params1: UITextField!
    @IBOutlet weak var params2: UITextField!
    @IBOutlet weak var params3: UITextField!
    @IBOutlet weak var params4: UITextField!
    
    @IBOutlet weak var table: UITableView!
    
    var tableData:[GeneralCellData] = []
    var selectIndex = -1
    var device:CBCDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        
        table.delegate = self
        table.dataSource = self
        table.register(GeneralCell.self, forCellReuseIdentifier: String.init(describing:  type(of: GeneralCell.self)))
        selectIndex = -1
        var cell = GeneralCellData.init()
        cell.title = "group"
        cell.key = "group"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "scene"
        cell.key = "scene"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "aniScene"
        cell.key = "aniScene"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "schedule"
        cell.key = "schedule"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "dailySchedule"
        cell.key = "dailySchedule"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "time"
        cell.key = "time"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "wn198"
        cell.key = "wn198"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "wn196"
        cell.key = "wn196"
        tableData.append(cell)
        cell = GeneralCellData.init()
        cell.title = "rc"
        cell.key = "rc"
        tableData.append(cell)
        table.reloadData()

        meshNameLabel.text = device.mesh_name
        statusLabel.text = ""
        meshPasswordTextfield.text = ""
        
        setView()
    }

    func setView(){
        params1.isHidden = true
        params2.isHidden = true
        params3.isHidden = true
        params4.isHidden = true
        params1.text = ""
        params2.text = ""
        params3.text = ""
        params4.text = ""
        if selectIndex < 0{
            return
        }
        let data = tableData[selectIndex]
        switch data.key {
        case "scene":
            params1.isHidden = false
            params1.placeholder = "sceneID"
        case "aniScene":
            params1.isHidden = false
            params1.placeholder = "aniSceneID"
            params2.isHidden = false
            params2.placeholder = "frameID"
        case "schedule":
            params1.isHidden = false
            params1.placeholder = "scheduleID"
        case "dailySchedule":
            params1.isHidden = false
            params1.placeholder = "dailyScheduleID"
        case "time":
            break
        case "wn198":
            break
        case "wn196":
            break
        default:
            break
        }
        
        params1.placeHolderColor = .gray
        params2.placeHolderColor = .gray
        params3.placeHolderColor = .gray
        params4.placeHolderColor = .gray
    }
    
    //MARK: Action
    @IBAction func onConnectClick(_ sender: Any) {
        CBCManager.GetSingleInstance().del = self
        statusLabel.text = ""
        CBCManager.GetSingleInstance().stopScan()
        CBCManager.GetSingleInstance().connect(device: device, meshName: device.mesh_name, meshPassword: meshPasswordTextfield.text!)
        meshPasswordTextfield.endEditing(true)
    }
    @IBAction func onSendClick(_ sender: Any) {
        if selectIndex < 0{
            return
        }
        let data = tableData[selectIndex]
        switch data.key {
        case "scene":
            CBCManager.GetSingleInstance().getScene(target: 0, sceneID: params1.text?.IntValue() ?? 0)
        case "aniScene":
            CBCManager.GetSingleInstance().getAniScene(target: 0, aniSceneID: params1.text?.IntValue() ?? 0, frameID: params2.text?.IntValue() ?? 0)
        case "schedule":
            CBCManager.GetSingleInstance().getSchedule(target: 0, scheduleID: params1.text?.IntValue() ?? 0)
        case "dailySchedule":
            CBCManager.GetSingleInstance().getSchedule(target: 0, scheduleID: params1.text?.IntValue() ?? 0)
        case "time":
            CBCManager.GetSingleInstance().getTime(target: 0)
        case "wn198":
            CBCManager.GetSingleInstance().getMotion(target: 0, type: .GetParams1)
            CBCManager.GetSingleInstance().getMotion(target: 0, type: .GetParams2)
            CBCManager.GetSingleInstance().getMotion(target: 0, type: .AdvanceTime)
        case "wn196":
            CBCManager.GetSingleInstance().getMotion(target: 0, type: .GetParams1)
            CBCManager.GetSingleInstance().getMotion(target: 0, type: .GetParams2)
            CBCManager.GetSingleInstance().getMotion(target: 0, type: .AdvanceTime)
            
            CBCManager.GetSingleInstance().getRemote(target: 0, type: .Get_MMWAVE_PH13_Page1)
            CBCManager.GetSingleInstance().getRemote(target: 0, type: .Get_MMWAVE_PH13_Page2)
        case "rc":
            CBCManager.GetSingleInstance().getRemote(target: 0, type: .GetkeyGroup1)
            CBCManager.GetSingleInstance().getRemote(target: 0, type: .GetkeyGroup2)
            CBCManager.GetSingleInstance().getRemote(target: 0, type: .GetkeyGroup3)
            CBCManager.GetSingleInstance().getRemote(target: 0, type: .GetkeyGroup4)
        default:
            break
        }
    }
}

extension TargetViewController:CBCManagerDelegate{
    func ScanDeviceResult(device:CBCDevice) -> Bool{
        table.reloadData()
        return true
    }
    func notifyCB(device:CBCDevice, bytes:UnsafeMutablePointer<UInt8>){
        
        var tempStr = ""
        for i in 0..<20{
            //let hex = Int.init(bytes[i])
            tempStr += String(format: "%02X ", bytes[i])
        }
        
        print("get info device:\(device.device_name ?? "") bytes:\(tempStr)")
    }
    
    func onConnectFinish(device: CBCDevice, success: Bool) {
        print("\(device.mesh_name ?? "") login:\(success)")
        statusLabel.text = "login:\(success)"
    }
}

extension TargetViewController:UITableViewDataSource,UITableViewDelegate{
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectIndex = indexPath.row
        tableView.reloadData()
        setView()
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier:String.init(describing:  type(of: GeneralCell.self)), for: indexPath) as! GeneralCell
        cell.label.text = "\(data.title)"
        cell.backgroundColor = selectIndex == indexPath.row ? .blue : .white
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}
