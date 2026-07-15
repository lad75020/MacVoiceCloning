import SwiftUI

struct LevelMeterView: View {
    /// 0…1.
    let level: Float

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(level > 0.85 ? Color.orange : Color.green)
                    .frame(width: max(4, proxy.size.width * CGFloat(min(level, 1))))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
        .frame(height: 8)
    }
}
