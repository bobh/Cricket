import SwiftUI
import AppKit

struct SettingsView: View {
    @Binding var sensorSource: String
    @ObservedObject var bluetoothViewModel: BluetoothViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Path
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignColor.brandGreen)
                        Text("Your Current Path")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: sensorSource == "BLE" ? "hammer.fill" : "antenna.radiowaves.left.and.right")
                            .font(.title2)
                            .foregroundColor(sensorSource == "BLE" ? DesignColor.brandBlue : DesignColor.brandGreen)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sensorSource == "BLE" ? "Arduino DIY Builder" : "RuuviTag Explorer")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(sensorSource == "BLE" ? 
                                "Building sensors from Arduino Nano 33 Sense Rev 2" :
                                "Using commercial RuuviTag sensors")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(DesignColor.cardBackground)
                    .cornerRadius(12)
                }
                
                // Switch Path
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "arrow.triangle.swap")
                            .foregroundColor(DesignColor.brandPurple)
                        Text("Switch Your Path")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        // Arduino Option
                        Button(action: { sensorSource = "BLE" }) {
                            HStack(spacing: 16) {
                                Image(systemName: "hammer.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignColor.brandBlue)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Arduino DIY Builder")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Build from scratch using Arduino Nano 33 Sense Rev 2. Full control, maximum learning, complete customization.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sensorSource == "BLE" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignColor.brandBlue)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(sensorSource == "BLE" ? DesignColor.brandBlue.opacity(0.1) : DesignColor.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(sensorSource == "BLE" ? DesignColor.brandBlue : Color.clear, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // RuuviTag Option
                        Button(action: { sensorSource = "Ruuvi" }) {
                            HStack(spacing: 16) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.title2)
                                    .foregroundColor(DesignColor.brandGreen)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("RuuviTag Explorer")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Start monitoring immediately with commercial RuuviTag sensors. Reliable, instant, and a great entry into maker culture.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sensorSource == "Ruuvi" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignColor.brandGreen)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(sensorSource == "Ruuvi" ? DesignColor.brandGreen.opacity(0.1) : DesignColor.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(sensorSource == "Ruuvi" ? DesignColor.brandGreen : Color.clear, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Sensor Documentation
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text.badge.gearshape")
                            .foregroundColor(DesignColor.brandOrange)
                        Text("Sensor Documentation")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/bobh/Sensors") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "externaldrive.fill.badge.plus")
                                .font(.title2)
                                .foregroundColor(DesignColor.brandOrange)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Complete Sensor Setup Guide")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("github.com/bobh/Sensors")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Arduino building instructions • RuuviTag setup • Troubleshooting • Community contributions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(DesignColor.brandOrange)
                        }
                        .padding()
                        .background(DesignColor.brandOrange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignColor.brandOrange.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                
                // Maker Resources
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(DesignColor.brandPurple)
                        Text("Maker Resources")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ResourceButton(
                            title: "Arduino Guide",
                            icon: "doc.text.fill",
                            color: DesignColor.brandBlue,
                            description: "Build your own sensor"
                        )
                        
                        ResourceButton(
                            title: "RuuviTag Setup",
                            icon: "gear",
                            color: DesignColor.brandGreen,
                            description: "Configure commercial sensors"
                        )
                        
                        ResourceButton(
                            title: "Community",
                            icon: "person.3.fill",
                            color: DesignColor.brandPurple,
                            description: "Connect with makers"
                        )
                        
                        ResourceButton(
                            title: "Citizen Science",
                            icon: "globe.americas.fill",
                            color: DesignColor.brandOrange,
                            description: "Your hyperlocal impact"
                        )
                    }
                }
                
                // Developer Tools
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(DesignColor.brandBlue)
                        Text("Developer Tools")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    Button(action: {
                        bluetoothViewModel.clearBLECache()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                                .foregroundColor(DesignColor.brandOrange)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clear BLE Cache")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("Clear cached Bluetooth data and restart scanning. Useful after Arduino firmware updates.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(DesignColor.brandOrange)
                        }
                        .padding()
                        .background(DesignColor.brandOrange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignColor.brandOrange.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Hyperlocal Monitoring")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Modern devices can't provide truly local environmental data. Your phone generates heat that distorts readings, and weather apps rely on distant stations that don't reflect conditions in your room, workspace, or immediate outdoor area.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Demetor turns this limitation into an opportunity - build or buy your own sensor and collect data that's uniquely yours. When you invest effort in creating your monitoring system, you engage more deeply with the results.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(DesignColor.cardBackground)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ResourceButton: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        Button(action: {
            // These would open documentation/community links
            // For now, just a placeholder
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(DesignColor.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
