/// A one-shot welcome card shown before the page picker, over the same graph-paper background.


import SwiftUI
    
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 75))
                .foregroundColor(AppTheme.yellowOrange)
                .retroCircle(fill: AppTheme.indigoPurple)
                .padding(.bottom, 5)

            Text("Welcome to iClean!")
                .font(.title.bold())
                .foregroundColor(AppTheme.ink)

            Text("Let's clean up that camera roll.")
                .font(.headline)
                .foregroundColor(AppTheme.ink.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .retroPanel(fill: AppTheme.tangerineOrange, cornerRadius: 12)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .retroPanel(fill: AppTheme.lavenderPurple, cornerRadius: 20)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(onContinue: { })
    }
}
