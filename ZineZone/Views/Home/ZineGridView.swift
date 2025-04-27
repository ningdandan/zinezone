import SwiftUI
import SDWebImageSwiftUI

struct ZineGridView: View {
    let zines: [Zine]
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(zines) { zine in
                NavigationLink(destination: ZineDetailView(zine: zine)) {
                    VStack(alignment: .leading, spacing: 4) {
                        WebImage(url: URL(string: zine.coverImageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(10)
                        
                        Text(zine.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("by \(zine.artistId)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(4)
                }
            }
        }
        .padding(.horizontal)
    }
}
