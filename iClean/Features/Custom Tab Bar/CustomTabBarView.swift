import SwiftUI

struct CustomTabBarView: View {
    @Binding var selectedTab: Tab
    let onSelect: (Tab) -> Void

    var body: some View {
        HStack (alignment: .center) {
            Button {
                onSelect(.sort)
            } label: {
                TabBarButtonView(buttonText: "Sort",
                                imageName: "photo.on.rectangle.angled",
                                isActive: selectedTab == .sort)
            }

            Button {
                onSelect(.duplicates)
            } label: {

                TabBarButtonView(buttonText: "Duplicates",
                                imageName: "magnifyingglass.circle",
                                isActive: selectedTab == .duplicates)
            }
        }
        .frame(height: 60)
        .font(.caption.bold())
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 30)      
                .fill(AppTheme.lavenderPurple)
        )
    }
}

struct CustomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBarView(selectedTab: .constant(.sort)) { _ in }
    }
}
