
import CoreLocation
import Foundation

@MainActor
final class CurrencyDetectionService: NSObject, CLLocationManagerDelegate {
    static let shared = CurrencyDetectionService()

    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    private override init() {
        super.init()
        manager.delegate = self
    }

    func detectCurrency() async -> CurrencyInfo {
        do {
            try await requestAuthorization()
            let location = try await requestLocation()
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            let isoCountryCode = placemarks.first?.isoCountryCode?.uppercased() ?? Locale.current.region?.identifier.uppercased() ?? "US"
            return Self.currencyMap[isoCountryCode] ?? CurrencyInfo(code: "USD", symbol: "$")
        } catch {
            let localeCode = Locale.current.region?.identifier.uppercased() ?? "US"
            return Self.currencyMap[localeCode] ?? CurrencyInfo(code: "USD", symbol: "$")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationContinuation?.resume()
            authorizationContinuation = nil
        case .denied, .restricted:
            authorizationContinuation?.resume(throwing: LocationError.denied)
            authorizationContinuation = nil
        case .notDetermined:
            break
        @unknown default:
            authorizationContinuation?.resume(throwing: LocationError.unknown)
            authorizationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    private func requestAuthorization() async throws {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            return
        }
        if status == .denied || status == .restricted {
            throw LocationError.denied
        }

        try await withCheckedThrowingContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private enum LocationError: Error {
        case denied
        case unknown
    }

    private static let currencyMap: [String: CurrencyInfo] = [
        "IN": .init(code: "INR", symbol: "₹"),
        "US": .init(code: "USD", symbol: "$"),
        "GB": .init(code: "GBP", symbol: "£"),
        "IE": .init(code: "EUR", symbol: "€"),
        "FR": .init(code: "EUR", symbol: "€"),
        "DE": .init(code: "EUR", symbol: "€"),
        "IT": .init(code: "EUR", symbol: "€"),
        "ES": .init(code: "EUR", symbol: "€"),
        "NL": .init(code: "EUR", symbol: "€"),
        "BE": .init(code: "EUR", symbol: "€"),
        "PT": .init(code: "EUR", symbol: "€"),
        "AT": .init(code: "EUR", symbol: "€"),
        "FI": .init(code: "EUR", symbol: "€"),
        "GR": .init(code: "EUR", symbol: "€"),
        "JP": .init(code: "JPY", symbol: "¥"),
        "AU": .init(code: "AUD", symbol: "A$"),
        "CA": .init(code: "CAD", symbol: "CA$"),
        "AE": .init(code: "AED", symbol: "د.إ"),
        "SG": .init(code: "SGD", symbol: "S$"),
        "CN": .init(code: "CNY", symbol: "¥")
    ]
}
