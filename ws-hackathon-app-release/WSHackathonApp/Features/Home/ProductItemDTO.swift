//
//  ProductItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation

struct ProductItemDTO: Identifiable, Codable {
    let id: String
    let name: String
    let shortName: String?
    let primaryGroupId: String?
    let price: ProductPrice?
    let properties: ProductProperties?
    let media: ProductMedia?
    let availability: String?
    let deliveryEstimate: String?
}

struct ProductPrice: Codable {
    let regularPrice: Double?
    let surcharge: Double?
    let retailPrice: Double?
    let sellingPrice: Double?
    let monogramOrPersonalizationPrice: Double?
}

struct ProductProperties: Codable {
    let isMarketPlace: String?
    let isSpecialOrder: String?
    let pattern: String?
    let isFood: String?
    let isFurniture: String?
    let spiritType: String?
    let hasUtilityNeeds: String?
    let brand: String?
    let productType: String?
    let canGiftWrap: String?
    let collection: String?
    let allProductTypes: String?
    let material: String?
    let isShoppable: String?
    let name: String?
    let shortName: String?
}

struct ProductMedia: Codable {
    let images: [ProductImage]?
}

struct ProductImage: Codable {
    let type: String?
    let path: String?
    let aspect: String?
    let properties: ProductImageProperties?
}

struct ProductImageProperties: Codable {
    let altText: String?
}
