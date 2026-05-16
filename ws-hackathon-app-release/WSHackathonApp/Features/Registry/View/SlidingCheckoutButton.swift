import SwiftUI

struct SlidingCheckoutButton: View {
    @State private var offset: CGFloat = 0
    @State private var isPlacingOrder = false
    let action: () -> Void

    private let buttonWidth: CGFloat = UIScreen.main.bounds.width - 32
    private let handleSize: CGFloat = 56
    private let travelDistance: CGFloat = (UIScreen.main.bounds.width - 32) - 56 - 8

    var body: some View {
        ZStack {
            Capsule()
                .fill(AppColors.alwaysBlack)
                .frame(height: 64)
            
            Text("SLIDE TO CHECKOUT")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(1.2)
            
            HStack {
                ZStack {
                    Capsule()
                        .fill(.white)
                        .frame(width: handleSize + offset, height: handleSize)
                    
                    Image(systemName: isPlacingOrder ? "checkmark" : "chevron.right.2")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.alwaysBlack)
                        .offset(x: offset / 2)
                }
                .padding(4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 && value.translation.width <= travelDistance {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if offset > travelDistance * 0.8 {
                                withAnimation(.spring()) {
                                    offset = travelDistance
                                    isPlacingOrder = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    action()
                                    withAnimation {
                                        offset = 0
                                        isPlacingOrder = false
                                    }
                                }
                            } else {
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                        }
                )
                Spacer()
            }
        }
        .frame(width: buttonWidth, height: 64)
    }
}
