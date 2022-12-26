//
//  Location.swift
//  MapApp
//
//  Created by Harun Demirkaya on 24.12.2022.
//

import Foundation

class LocationModel {
    var id: UUID
    var title: String
    var subTitle =  ""
    var latitude = 0.0
    var longitude = 0.0
    
    init(id: UUID, title: String, subTitle: String = "", latitude: Double = 0.0, longitude: Double = 0.0) {
        self.id = id
        self.title = title
        self.subTitle = subTitle
        self.latitude = latitude
        self.longitude = longitude
    }
}
