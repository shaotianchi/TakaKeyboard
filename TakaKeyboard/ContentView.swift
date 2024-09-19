//
//  ContentView.swift
//  TakaKeyboard
//
//  Created by shaotianchi on 2024/09/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    let bluetoothController = BluetoothController()

    var body: some View {
        NavigationSplitView {
            Button(action: {
                bluetoothController.sendKeystroke(HIDService.KeyStroke.Z, HIDService.KeyState.Down)
                bluetoothController.sendKeystroke(HIDService.KeyStroke.Z, HIDService.KeyState.Up)
            }, label: {
                Text("Z")
            })
            Button(action: {
                
            }, label: {
                Text("?/")
            })
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
