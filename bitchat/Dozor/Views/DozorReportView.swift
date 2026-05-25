import CoreLocation
import SwiftUI

private struct SightingOption {
    let type: SightingType
    let label: String
    let color: Color
}

private let sightingOptions: [SightingOption] = [
    SightingOption(type: .checkpoint, label: "Блокпост",  color: .red),
    SightingOption(type: .mobileUnit, label: "Машина",    color: .orange),
    SightingOption(type: .officer,    label: "Сотрудник", color: Color(red: 1, green: 0.84, blue: 0)),
    SightingOption(type: .clear,      label: "Чисто",     color: .green)
]

private struct SightingOptionButton: View {
    let option: SightingOption
    @Binding var selectedType: SightingType

    var body: some View {
        let isSelected = selectedType == option.type
        let label = option.type.emoji + "  " + option.label
        Button { selectedType = option.type } label: {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? option.color.opacity(0.25) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? option.color : Color.clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundColor(.white)
    }
}

struct DozorReportView: View {
    @EnvironmentObject var dozorVM: DozorViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var locator = OneTimeLocator()
    @State private var selectedType: SightingType = .checkpoint
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Что вы видели?")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sightingOptions, id: \.type.rawValue) { option in
                        SightingOptionButton(option: option, selectedType: $selectedType)
                    }
                }

                TextField("Уточните место (необязательно)", text: $note)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    guard let coord = locator.coordinate else { return }
                    dozorVM.report(
                        type: selectedType,
                        coordinate: coord,
                        note: note.isEmpty ? nil : note
                    )
                    dismiss()
                } label: {
                    Text(locator.coordinate == nil ? "Определяем геолокацию..." : "Отправить сигнал")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(locator.coordinate == nil ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(locator.coordinate == nil)
            }
            .padding(24)
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear { locator.start() }
    }
}
