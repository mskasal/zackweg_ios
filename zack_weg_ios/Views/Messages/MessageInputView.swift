import SwiftUI

struct MessageInputView: View {
    @Binding var messageText: String
    var onSend: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                  if messageText.isEmpty {
                      Text("messages.type".localized)
                          .foregroundColor(Color.gray.opacity(0.7))
                          .padding(.horizontal, 12)
                          .padding(.vertical, 8)
                  }
                  
                  TextEditor(text: $messageText)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 2)
                      .frame(minHeight: 35, maxHeight: 35)
                      .scrollContentBackground(.hidden)
                      .background(Color.clear)
                      .submitLabel(.return)
              }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                )
                .focused($isFocused)
                .submitLabel(.return)
                .onSubmit {
                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
            
            Button(action: {
                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSend()
                    isFocused = false
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                        Color.gray.opacity(0.5) : Color.blue
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputView(messageText: .constant("Hello"), onSend: {})
    }
}
