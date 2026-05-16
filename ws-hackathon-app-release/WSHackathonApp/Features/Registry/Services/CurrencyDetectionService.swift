// CurrencyDetectionService.swift
// WSHackathonApp

import Foundation
import Combine
import CoreLocation

// MARK: - Country → Currency map

private let countryCurrencyMap: [String: CurrencyInfo] = [
    "IN": CurrencyInfo(code: "INR", symbol: "₹"),
    "US": CurrencyInfo(code: "USD", symbol: "$"),
    "GB": CurrencyInfo(code: "GBP", symbol: "£"),
    "JP": CurrencyInfo(code: "JPY", symbol: "¥"),
    "AU": CurrencyInfo(code: "AUD", symbol: "A$"),
    "CA": CurrencyInfo(code: "CAD", symbol: "CA$"),
    "AE": CurrencyInfo(code: "AED", symbol: "د.إ"),
    "SG": CurrencyInfo(code: "SGD", symbol: "S$"),
    "CN": CurrencyInfo(code: "CNY", symbol: "¥"),
    "CH": CurrencyInfo(code: "CHF", symbol: "Fr"),
    "SE": CurrencyInfo(code: "SEK", symbol: "kr"),
    "NO": CurrencyInfo(code: "NOK", symbol: "kr"),
    "DK": CurrencyInfo(code: "DKK", symbol: "kr"),
    "NZ": CurrencyInfo(code: "NZD", symbol: "NZ$"),
    "HK": CurrencyInfo(code: "HKD", symbol: "HK$"),
    "KR": CurrencyInfo(code: "KRW", symbol: "₩"),
    "MX": CurrencyInfo(code: "MXN", symbol: "MX$"),
    "BR": CurrencyInfo(code: "BRL", symbol: "R$"),
    "ZA": CurrencyInfo(code: "ZAR", symbol: "R"),
    "TH": CurrencyInfo(code: "THB", symbol: "฿"),
    "MY": CurrencyInfo(code: "MYR", symbol: "RM"),
    "ID": CurrencyInfo(code: "IDR", symbol: "Rp"),
    "PH": CurrencyInfo(code: "PHP", symbol: "₱"),
    // Euro-zone countries
    "DE": CurrencyInfo(code: "EUR", symbol: "€"),
    "FR": CurrencyInfo(code: "EUR", symbol: "€"),
    "IT": CurrencyInfo(code: "EUR", symbol: "€"),
    "ES": CurrencyInfo(code: "EUR", symbol: "€"),
    "NL": CurrencyInfo(code: "EUR", symbol: "€"),
    "BE": CurrencyInfo(code: "EUR", symbol: "€"),
    "PT": CurrencyInfo(code: "EUR", symbol: "€"),
    "AT": CurrencyInfo(code: "EUR", symbol: "€"),
    "FI": CurrencyInfo(code: "EUR", symbol: "€"),
    "IE": CurrencyInfo(code: "EUR", symbol: "€"),
    "GR": CurrencyInfo(code: "EUR", symbol: "€"),
]

// MARK: - Currency Detection Service

@MainActor
final class CurrencyDetectionService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = CurrencyDetectionService()

    @Published var detectedCurrency: CurrencyInfo = .usd
    @Published var isDetecting: Bool = false

    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<CurrencyInfo, Never>?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public API

    func detectCurrency() async -> CurrencyInfo {
        isDetecting = true
        defer { isDetecting = false }

        let status = locationManager.authorizationStatus

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            if status == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            // If still not authorized, return USD
            let currentStatus = locationManager.authorizationStatus
            guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
                return .usd
            }
            return await reverseGeocode()
        }

        return await reverseGeocode()
    }

    // MARK: - Private

    private func reverseGeocode() async -> CurrencyInfo {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.locationManager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            Task { @MainActor in self.continuation?.resume(returning: .usd) }
            return
        }

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let isoCode = placemarks?.first?.isoCountryCode ?? "US"
            let currency = countryCurrencyMap[isoCode] ?? .usd
            Task { @MainActor in
                self.detectedCurrency = currency
                self.continuation?.resume(returning: currency)
                self.continuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(returning: .usd)
            self.continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handled in detectCurrency flow
    }
}
