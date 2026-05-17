//
//  OccasionCollectionCarousel.swift
//  WSHackathonApp
//
//  Merged carousel interleaving Occasions and Collections.
//

import SwiftUI
import Combine

// MARK: - Carousel Slide
enum CarouselSlide: Identifiable {
    case occasion(WSOccasion)
    case collection(WSCollection)

    var id: String {
        switch self {
        case .occasion(let o): return "occ-\(o.id)"
        case .collection(let c): return "col-\(c.id)"
        }
    }
}

// MARK: - Carousel View
@available(iOS 18.0, *)
struct OccasionCollectionCarousel: View {
    let occasions: [WSOccasion]
    let collections: [WSCollection]
    let allProducts: [WSProduct]

    @State private var currentPage = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    private var slides: [CarouselSlide] {
        var result: [CarouselSlide] = []
        let maxCount = max(occasions.count, collections.count)
        for i in 0..<maxCount {
            if i < occasions.count {
                result.append(.occasion(occasions[i]))
            }
            if i < collections.count {
                result.append(.collection(collections[i]))
            }
        }
        return result
    }

    var body: some View {
        if slides.isEmpty { EmptyView() }
        else {
            TabView(selection: $currentPage) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    slideCard(slide)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 216)
            .onReceive(timer) { _ in
                guard !slides.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPage = (currentPage + 1) % slides.count
                }
            }
        }
    }

    @ViewBuilder
    private func slideCard(_ slide: CarouselSlide) -> some View {
        switch slide {
        case .occasion(let occasion):
            NavigationLink(destination: ProductListView(
                title: occasion.name,
                products: allProducts.filter { $0.occasions.contains(occasion.name) }
            )) {
                occasionCardContent(occasion)
            }
            .buttonStyle(.plain)

        case .collection(let collection):
            NavigationLink(destination: ProductListView(
                title: collection.name,
                products: allProducts.filter { $0.collectionName == collection.name || $0.brand == collection.brand }
            )) {
                collectionCardContent(collection)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Occasion Card
    private func occasionCardContent(_ occasion: WSOccasion) -> some View {
        VStack(alignment: .leading) {
            Text(occasion.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)

            Text(occasion.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            Spacer()

            HStack {
                Spacer()
                Text("Shop →")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.black)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Collection Card
    private func collectionCardContent(_ collection: WSCollection) -> some View {
        VStack(alignment: .leading) {
            Text("COLLECTION")
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(1.5)
                .foregroundStyle(Color.secondary)

            Text(collection.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)

            Text(collection.tagline)
                .font(.footnote)
                .foregroundStyle(Color.secondary)

            Spacer()

            HStack {
                Spacer()
                Text("Explore →")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.black)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
