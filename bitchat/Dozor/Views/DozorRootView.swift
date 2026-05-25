import SwiftUI

struct DozorRootView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var dozorVM: DozorViewModel

    var body: some View {
        TabView {
            DozorMapView()
                .tabItem { Label("Радар", systemImage: "map.fill") }

            ContentView()
                .environmentObject(chatViewModel)
                .tabItem { Label("Чат", systemImage: "message.fill") }

            DozorShieldView()
                .tabItem { Label("Права", systemImage: "shield.fill") }

            DozorCalendarView()
                .tabItem { Label("Сроки", systemImage: "calendar") }
        }
        .accentColor(.red)
        .onAppear {
            dozorVM.setup(chatViewModel: chatViewModel)
        }
    }
}
