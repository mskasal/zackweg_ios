import SwiftUI

struct ReportView: View {
    @StateObject private var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(postId: String) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(postId: postId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title and instructions
                        Text("report.title".localized)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 10)
                        
                        Text("report.instructions".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Reason selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("report.reason".localized)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button(action: {
                                    viewModel.selectedReason = reason
                                }) {
                                    HStack {
                                        Text(reason.displayName)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if viewModel.selectedReason == reason {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(viewModel.selectedReason == reason ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    )
                                }
                            }
                        }
                        
                        if viewModel.selectedReason == .other {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("report.additional_details".localized)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                TextField("report.more_info_placeholder".localized, text: $viewModel.additionalComment)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }
                        
                        if let error = viewModel.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
                
                // Submit button area (fixed at bottom)
                VStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Button(action: {
                            Task {
                                await viewModel.submitReport()
                                if viewModel.isSuccess {
                                    dismiss()
                                }
                            }
                        }) {
                            Text("report.submit".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
}

#Preview {
    ReportView(postId: "post-123")
} 