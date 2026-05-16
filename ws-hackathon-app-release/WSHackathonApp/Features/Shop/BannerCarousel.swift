//
//  BannerCarousel.swift
//  WSHackathonApp
//
//  Hero banner carousel with full-width cards.
//

import SwiftUI

struct WSHeroBannerSlide: Identifiable {
    let id: UUID = UUID()
    let imageName: String
    let tagline: String
    let title: String
    let subtitle: String
    let ctaLabel: String
    let destination: String
}

let heroBanners: [WSHeroBannerSlide] = [
    WSHeroBannerSlide(imageName: "banner_cookware", tagline: "NEW ARRIVALS", title: "Signature Cookware", subtitle: "Discover our finest Le Creuset & All-Clad", ctaLabel: "SHOP NOW", destination: "Cookware"),
    WSHeroBannerSlide(imageName: "banner_holiday", tagline: "SEASONAL", title: "Holiday Gifting", subtitle: "Thoughtfully curated for every occasion", ctaLabel: "EXPLORE", destination: "Gift Ideas"),
    WSHeroBannerSlide(imageName: "banner_knives", tagline: "BESTSELLERS", title: "Knife Collection", subtitle: "Precision-crafted for the home chef", ctaLabel: "SHOP NOW", destination: "Knives"),
    WSHeroBannerSlide(imageName: "banner_bakeware", tagline: "TRENDING", title: "Bakeware Edit", subtitle: "Everything you need to bake beautifully", ctaLabel: "SHOP NOW", destination: "Bakeware"),
    WSHeroBannerSlide(imageName: "banner_outdoor", tagline: "COLLECTION", title: "Outdoor Dining", subtitle: "Entertain with style, inside and out", ctaLabel: "EXPLORE", destination: "Outdoor"),
]

struct BannerCarousel: View {
    let allProducts: [WSProduct]
    @State private var currentBannerIndex: Int = 0
    @State private var bannerTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentBannerIndex) {
                ForEach(Array(heroBanners.enumerated()), id: \.element.id) { index, banner in
                    NavigationLink(destination: ProductListView(
                        title: banner.title,
                        products: allProducts.filter { $0.category == banner.destination || $0.occasions.contains(banner.destination) }
                    )) {
                        WSHeroBannerCard(banner: banner)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            
            HStack(spacing: 6) {
                ForEach(0..<heroBanners.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentBannerIndex ? Color.black : Color(uiColor: .tertiaryLabel))
                        .frame(width: i == currentBannerIndex ? 20 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentBannerIndex)
                }
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            startBannerTimer()
        }
        .onDisappear {
            bannerTimer?.invalidate()
            bannerTimer = nil
        }
    }
    
    private func startBannerTimer() {
        bannerTimer?.invalidate()
        bannerTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentBannerIndex = (currentBannerIndex + 1) % heroBanners.count
            }
        }
        if let timer = bannerTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}

struct WSHeroBannerCard: View {
    let banner: WSHeroBannerSlide

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))
            
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear],
                startPoint: .bottom,
                endPoint: .center
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(banner.tagline)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.8))

                Text(banner.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text(banner.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)

                Text(banner.ctaLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
