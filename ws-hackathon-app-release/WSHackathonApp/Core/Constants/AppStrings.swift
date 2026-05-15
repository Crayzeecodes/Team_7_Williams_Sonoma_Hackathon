//
//  AppStrings.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
enum AppStrings {
    
    enum Tabs {
        static let home = "Home"
        static let registry = "Registry"
        static let cart = "Cart"
    }
    
    enum Home {
        static let title = "Home"
        static let searchPlaceHolder = "Search for products..."
        static let freeShiiping = "Free Shipping"
        static let noFreeShiiping = "No Free Shipping"
        static let addToCartButton = "Add to cart"
        static let addToRegistry = "Add to registry"
    }
    
    enum Cart {
        static let title = "Cart"
        static let emptyMessage = "Hi! Looks like your cart is empty..."
        static let emptyButton = "Continue Shopping"
        static let total = "Total"
        static let checkoutButton = "Checkout"
    }
    
    enum Registry {
        static let title = "Registry"
        static let create = "Create A Registry"
        static let createButton = "Create"
        
        static let noItemsAdded = "No items added yet"

        // Instruction Card
        static let topReasons = "TOP REASONS TO REGISTER WITH US"
        
        static let exclusiveProduct = "Exclusive Products"
        static let exclusiveProductsDesc = "Discover our hand-selected assortment, available in a range of styles and colors - only at Williams Sonoma."
        
        static let expertAdvice = "Free Expert Advice"
        static let expertAdviceDesc = "Visit us in-store or online for expert assistance in creating your registry and guiding your guests to the perfect gift. Request a free appointment."
        
        static let discountTitle = "10% Completion Discount"
        static let discountDesc = "Enjoy exclusive savings and gifts for completing your registry with us."
        
        static let inStoreTitle = "In-Store Experience"
        static let instStoreDesc = "For easy shopping and personalized service, you'll find over 150 stores across the country."
        
        static let firstName = "First Name"
        static let lastName = "Last Name"
        static let event = "Event Type"
        static let eventDate = "Event Date"
        static let createYourRegistry = "Create Your Registry"
    }
}
