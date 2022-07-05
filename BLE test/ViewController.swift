//
//  ViewController.swift
//  BLE test
//
//  Created by 陳力維 on 2022/7/5.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var table: UITableView!
    
    var tableData:[CBCDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        table.delegate = self
        table.dataSource = self
        table.register(GeneralCell.self, forCellReuseIdentifier: String.init(describing:  type(of: GeneralCell.self)))
        CBCManager.GetSingleInstance().del = self
    }


    @IBAction func scanClick(_ sender: Any) {
        tableData = []
        table.reloadData()
        CBCManager.GetSingleInstance().stopScan()
        CBCManager.GetSingleInstance().startScan()
    }
}

extension ViewController:CBCManagerDelegate{
    func ScanDeviceResult(device:CBCDevice) -> Bool{
        tableData.append(device)
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
}

extension ViewController:UITableViewDataSource,UITableViewDelegate{
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CBCManager.GetSingleInstance().stopScan()
        let data = tableData[indexPath.row]
        CBCManager.GetSingleInstance().connect(device: data)
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
        cell.label.text = "\(data.device_name ?? "")   \(data.uuid ?? "")"
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
