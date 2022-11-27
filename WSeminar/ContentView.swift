//
//  ContentView.swift
//  WSeminar
//
//  Created by Matthias on 07.10.22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List{
                Section(header: Text("Grundrechenarten")){
                    NavigationLink(destination: AddSub()) {
                        Text("Addition & Subtraktion")
                    }
                    NavigationLink(destination: Multiplikation()) {
                        Text("Multiplikation")
                    }
                    NavigationLink(destination: Division()) {
                        Text("Division")
                    }
                }
                Section(header: Text("Rotation")) {
                    NavigationLink(destination: Playground()) {
                        Text("Spielwiese")
                    }
                    NavigationLink(destination: Slerp()) {
                        Text("slerp")
                    }
                    NavigationLink(destination: Spline()) {
                        Text("spline")
                    }
                    NavigationLink(destination: Gyro()) {
                        Text("Gyro")
                    }
                }
            }
            .navigationTitle(Text("Quaternionen"))
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
