
import SwiftUI

struct ProfileModalView: View {
    @Environment(UserManager.self) private var userManager
    @Environment(NavigationManager.self) private var navManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    menuSection
                    footerSection
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: Bindable(navManager).showOrders) {
                OrdersView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 44, height: 36)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Done")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 72, height: 72)
                Text(userManager.currentUser?.initials ?? "WS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(userManager.currentUser?.fullName ?? "Guest")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)

            Text(userManager.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            if userManager.currentUser?.isKeyRewardsMember == true {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("KEY REWARDS MEMBER")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                    if let points = userManager.currentUser?.rewardPoints {
                        Text("•")
                        Text("\(points) pts")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(uiColor: .tertiarySystemBackground))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "shippingbox", title: "My Orders", showsDivider: false) {
                navManager.showOrders = true
            }
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func menuRow(
        icon: String,
        title: String,
        showsDivider: Bool = true,
        action: @escaping () -> Void = { }
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.primary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .overlay(alignment: .bottom) {
            if showsDivider {
                Divider().padding(.leading, 54)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            Button {
                userManager.signOut()
                dismiss()
            } label: {
                Text("Sign Out")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black)
            }
            Text("Williams Sonoma v1.0.0")
                .font(.caption)
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .padding(.vertical, 28)
    }
}
