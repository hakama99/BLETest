//
//  BottonSelectCell.swift
//  FireBEE
//
//  Created by 陳力維 on 2021/8/20.
//  Copyright © 2021 BLTC Network. All rights reserved.
//

import UIKit

class GeneralCellData:NSObject{
    @objc var title:String = ""
    @objc var buttonTitle:String = ""
    @objc var buttonImage:String = ""
    @objc var key:String = ""
}

class GeneralCell: UITableViewCell {
    static let CELL_ID = "GeneralCell"
    @objc var label:UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func initialize(){
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        label = UILabel.init()
        label.backgroundColor = .white
        label.textColor = .black
        label.isUserInteractionEnabled = false
        self.attachViewLayout(label)
    }
}

extension UIView{
    public func attachViewLayout(_ view:UIView)
    {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layoutAttachAll(to: self)
    }
    
    private func layoutAttachAll(to parentView:UIView)
    {
        let left = self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 0)
        let right = self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: 0)
        let bottom = self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: 0)
        let top = self.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            left,
            right,
            bottom,
            top
        ])
    }
}
