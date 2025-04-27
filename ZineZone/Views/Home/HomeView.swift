import SwiftUI
import FirebaseFirestore
import Foundation

struct HomeView: View {
    @State private var zines: [Zine] = []
    @State private var savedZines: [Zine] = []
    @State private var showSavedOnly = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 顶部筛选器
                Picker("", selection: $showSavedOnly) {
                    Text("ALL").tag(false)
                    Text("SAVED").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // zine列表
                ScrollView {
                    ZineGridView(zines: showSavedOnly ? savedZines : zines)
                }
            }
            .navigationTitle("Zine Zone")
        }
        .onAppear {
            fetchAllZines()
            fetchSavedZines()
            NotificationCenter.default.addObserver(forName: .savedZinesUpdated, object: nil, queue: .main) { _ in
                    fetchSavedZines()
                }
        }
    }
    
    private func fetchAllZines() {
        ZineService.fetchAllZines { zines in
            self.zines = zines
        }
    }
    
    private func fetchSavedZines() {
        ZineService.fetchSavedZines { zines in
            self.savedZines = zines
        }
    }
}
