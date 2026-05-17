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
    WSHeroBannerSlide(imageName: "1_fathersday", tagline: "OCCASION", title: "Celebrate dad.", subtitle: "Father’s day is June 21.", ctaLabel: "SHOP GIFTS", destination: "Gifts"),
    WSHeroBannerSlide(imageName: "2_summerdining", tagline: "COLLECTION", title: "Summer Dining", subtitle: "Make the most of life outdoors and pieces designed for open-air dining and easy entertaining.", ctaLabel: "EXPLORE", destination: "Outdoor"),
    WSHeroBannerSlide(imageName: "3_luccilambrusco", tagline: "INTRODUCING", title: "Lucci Lambrusco", subtitle: "Raise a glass to Lucci Lambrusco, Ashley Graham's fresh, modern take on Italy's original sparkling red.", ctaLabel: "SHOP NOW", destination: "Wine"),
    WSHeroBannerSlide(imageName: "4_oakvile", tagline: "NEW ARRIVAL", title: "The Taste of Oakville", subtitle: "Created in collaboration with Oakville Grocery, this collection brings the flavors of the Napa Valley to your table.", ctaLabel: "SHOP NOW", destination: "Food"),
    WSHeroBannerSlide(imageName: "5_stanleytucci", tagline: "COLLECTION", title: "GreenPan Stanley Tucci Collection", subtitle: "From ceramic nonstick cookware to pizza-night essentials, Stanley's collection brings his Italian American style to your kitchen.", ctaLabel: "SHOP NOW", destination: "Cookware")
]

@available(iOS 18.0, *)
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
            .clipShape(RoundedRectangle(cornerRadius: 25))
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
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Image(banner.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                LinearGradient(
                    colors: [Color.black.opacity(0.8), Color.clear],
                    startPoint: .bottom,
                    endPoint: .top
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
                .frame(width: geo.size.width, alignment: .bottomLeading)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}
