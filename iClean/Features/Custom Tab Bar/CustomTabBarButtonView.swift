import SwiftUI

struct TabBarButtonView: View {

    var buttonText: String
    var imageName: String
    var isActive: Bool

    var body: some View {
        //Use this rather that ZStack because it allows the button to take up the full space
        GeometryReader { geo in 

            if isActive {
                Rectangle()
                    .frame(width: geo.size.width / 2, height: 4)
                    .padding(.leading, geo.size.width / 4)
                    .foregroundColor(AppTheme.indigoPurple)
            }

            VStack (alignment: .center, spacing: 4) {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(AppTheme.indigoPurple)
                Text(buttonText)
                    .foregroundStyle(AppTheme.indigoPurple)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct TabBarButtonView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarButtonView(buttonText: "Sort", imageName: "photo.on.rectangle.angled", isActive: true)
    }
}
