//
//  DataModel.swift
//  Basic Chat
//
//  Created by Trenton Taylor on 5/31/18.
//  Copyright © 2018 Vanguard Logic LLC. All rights reserved.
//

import Foundation


class DataModel {
    weak var delegate: DataModelDelegate?
    func requestData() {
        // the data was received and parsed to String
        let data = "hello"
        delegate?.didRecieveDataUpdate(data: data)
    }
}


protocol DataModelDelegate: class {
    
    func didRecieveDataUpdate(data: String)
    
}
