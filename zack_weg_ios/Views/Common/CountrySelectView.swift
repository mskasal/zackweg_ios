import SwiftUI

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    
    static let germany = Country(name: "Deutschland", code: "DEU")
    
    static let allCountries = [germany]
}

struct CountrySelectView: View {
    @Binding var selectedCountry: Country?
    var label: String
    var placeholder: String = "common.select".localized
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(Country.allCountries) { country in
                    Button(action: {
                        selectedCountry = country
                    }) {
                        HStack {
                            Text(country.name)
                            Spacer()
                            if selectedCountry == country {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCountry?.name ?? placeholder)
                        .foregroundColor(selectedCountry == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct CountrySelectView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // With no selection
            CountrySelectView(
                selectedCountry: .constant(nil),
                label: "auth.country".localized
            )
            .padding()
            
            // With selection
            CountrySelectView(
                selectedCountry: .constant(Country.germany),
                label: "auth.country".localized
            )
            .padding()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 