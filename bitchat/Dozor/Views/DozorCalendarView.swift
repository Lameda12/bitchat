import SwiftUI

private struct CallUpWindow: Decodable {
    let name: String
    let start_month: Int
    let start_day: Int
    let end_month: Int
    let end_day: Int
    let risk_level: String
    let notes: String
}

private struct CalendarData: Decodable {
    let call_up_windows: [CallUpWindow]
    let age_range: AgeRange
    let service_duration_months: Int

    struct AgeRange: Decodable {
        let min: Int
        let max: Int
    }
}

private func loadCalendarData() -> CalendarData? {
    guard let url = Bundle.main.url(forResource: "calendar_kz", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let decoded = try? JSONDecoder().decode(CalendarData.self, from: data)
    else { return nil }
    return decoded
}

private func currentRiskLevel(windows: [CallUpWindow]) -> String {
    let now = Calendar.current.dateComponents([.month, .day], from: Date())
    guard let month = now.month, let day = now.day else { return "low" }
    for w in windows {
        let afterStart = (month > w.start_month) || (month == w.start_month && day >= w.start_day)
        let beforeEnd  = (month < w.end_month)   || (month == w.end_month   && day <= w.end_day)
        if afterStart && beforeEnd { return w.risk_level }
    }
    return "low"
}

private func daysUntilNextWindow(windows: [CallUpWindow]) -> (name: String, days: Int)? {
    let cal = Calendar.current
    let now = Date()
    var year = cal.component(.year, from: now)
    var closest: (name: String, days: Int)?

    for w in windows {
        for y in [year, year + 1] {
            var comps = DateComponents()
            comps.year = y; comps.month = w.start_month; comps.day = w.start_day
            guard let start = cal.date(from: comps) else { continue }
            let diff = cal.dateComponents([.day], from: now, to: start).day ?? 0
            if diff >= 0 {
                if closest == nil || diff < closest!.days {
                    closest = (w.name, diff)
                }
            }
        }
    }
    return closest
}

struct DozorCalendarView: View {
    private let data = loadCalendarData()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let data {
                        let risk = currentRiskLevel(windows: data.call_up_windows)
                        RiskBanner(risk: risk)

                        if let next = daysUntilNextWindow(windows: data.call_up_windows) {
                            NextWindowCard(name: next.name, days: next.days)
                        }

                        ForEach(data.call_up_windows, id: \.name) { w in
                            WindowCard(window: w)
                        }

                        AgeCard(min: data.age_range.min, max: data.age_range.max,
                                duration: data.service_duration_months)
                    } else {
                        Text("Данные недоступны")
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Призывные сроки")
            .navigationBarTitleDisplayMode(.large)
            .colorScheme(.dark)
        }
    }
}

private struct RiskBanner: View {
    let risk: String

    private var color: Color { risk == "high" ? .red : .green }
    private var label: String { risk == "high" ? "🔴 Призывной сезон — высокий риск" : "✅ Вне призывного сезона" }

    var body: some View {
        Text(label)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(color.opacity(0.2))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct NextWindowCard: View {
    let name: String
    let days: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(days == 0 ? "Идёт сейчас" : "До \(name)")
                .font(.system(size: 13)).foregroundColor(.gray)
            Text(days == 0 ? name : "\(days) дн.")
                .font(.system(size: 36, weight: .bold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct WindowCard: View {
    let window: CallUpWindow

    private let monthNames = ["", "январь","февраль","март","апрель","май","июнь",
                               "июль","август","сентябрь","октябрь","ноябрь","декабрь"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(window.name)
                .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            Text("\(window.start_day) \(monthNames[window.start_month]) — \(window.end_day) \(monthNames[window.end_month])")
                .font(.system(size: 14)).foregroundColor(Color.white.opacity(0.7))
            Text(window.notes)
                .font(.system(size: 13)).foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct AgeCard: View {
    let min: Int
    let max: Int
    let duration: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Призывной возраст: \(min)–\(max) лет")
                .font(.system(size: 14)).foregroundColor(Color.white.opacity(0.8))
            Text("Срок службы: \(duration) месяцев")
                .font(.system(size: 14)).foregroundColor(Color.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
