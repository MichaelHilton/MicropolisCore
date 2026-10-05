import SwiftUI

struct MessageBar: View {
    @Environment(GameModel.self) var model

    var body: some View {
        if let message = model.currentMessage {
            HStack(spacing: 12) {
                Text(message)
                    .font(.system(.body, design: .default))
                    .lineLimit(2)

                Spacer()

                if let goTo = model.importantMessageGoTo {
                    Button("Go to") {
                        // Signal the MapView to scroll to this location
                        // This will be implemented by the MapView observing model changes
                    }
                    .font(.system(.caption, design: .default))
                }
            }
            .padding(8)
            .background(Color.yellow.opacity(0.2))
            .border(Color.orange, width: 1)
        }
    }
}
