// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let user = try? newJSONDecoder().decode(User.self, from: jsonData)

import Foundation


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let user = try? newJSONDecoder().decode(User.self, from: jsonData)

import Foundation

// MARK: - User
struct AvilableCabsModel: Codable {
    let availableCabList: [AvailableCab]
    let tsiteDB: String
    let googleAPIReplacementURL: String
    
    enum CodingKeys: String, CodingKey {
        case availableCabList = "AvailableCabList"
        case tsiteDB = "TSITE_DB"
        case googleAPIReplacementURL = "GOOGLE_API_REPLACEMENT_URL"
    }
}

// MARK: - AvailableCabList
struct AvailableCab: Codable {
    let idriverdestinations, iDriverID, vName, vLastName: String
    let vAvgRating, vImage, price, date: String
    let passengers: Int?
    let messageTrip:String?
    let petsFree, noSmoking, musicPlay, loveChatting: Bool
    let cityStart, cityEnd, latEnd, longEnd: String
    let tDriverMiddleDest, latStart, longStart,tripType: String
    let bar: [Int]

    enum CodingKeys: String, CodingKey {
        case idriverdestinations
        case iDriverID = "iDriverId"
        case vName, vLastName, vAvgRating, vImage, price, date, passengers
        case petsFree = "pets_free"
        case noSmoking = "no_smoking"
        case musicPlay = "music_play"
        case loveChatting = "love_chatting"
        case cityStart = "city_start"
        case cityEnd = "city_end"
        case tripType = "TripType"
        case messageTrip = "MessageTrip"
        case latEnd, longEnd,bar, tDriverMiddleDest, latStart, longStart
    }
}

