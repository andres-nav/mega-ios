import SwiftUI

struct AppearanceListFooterWithLinkView: View {
    
    let message: String
    let linkMessage: String
    let linkUrl: URL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .foregroundColor(Color.sectionTitle)
            Link(destination: linkUrl) {
                Text(linkMessage)
                    .foregroundColor(Colors.Views.turquoise.swiftUIColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.footnote)
    }
}

struct AppearanceListFooterView_Preview: PreviewProvider {
    static var previews: some View {
        AppearanceListFooterWithLinkView(
            message: "Folders that contain only images and videos will open in media discovery view by default.",
            linkMessage: "Learn more about mega",
            linkUrl: URL(string: "https://www.mega.io")!)
        .previewDevice(.none)
    }
}