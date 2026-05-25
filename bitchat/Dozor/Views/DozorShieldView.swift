import SwiftUI

private struct ShieldSection: Decodable {
    let title: String
    let icon: String
    let items: [String]
}

private struct ShieldData: Decodable {
    let version: Int
    let sections: [ShieldSection]
}

private func loadShieldData() -> [ShieldSection] {
    guard let url = Bundle.main.url(forResource: "shield_ru", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let decoded = try? JSONDecoder().decode(ShieldData.self, from: data)
    else { return [] }
    return decoded.sections
}

struct DozorShieldView: View {
    private let sections = loadShieldData()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(sections, id: \.title) { section in
                        ShieldSectionCard(section: section)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Ваши права")
            .navigationBarTitleDisplayMode(.large)
            .colorScheme(.dark)
        }
    }
}

private struct ShieldSectionCard: View {
    let section: ShieldSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .semibold))
                Text(section.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(section.items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .bold))
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
