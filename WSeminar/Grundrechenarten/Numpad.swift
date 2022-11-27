//
//  Numpad.swift
//  ExploreQuaternions
//
//  Created by Matthias on 07.11.22.
//

import SwiftUI

struct Numpad: View {
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        VStack (spacing: 5){
            HStack (spacing: 5){
                Button {
                    print("1")
                    
                } label: {
                    Text("1")
                }
                .frame(width: 0.25*width, height: 0.25*height)
                .border(.orange)
                Button {
                    print("2")
                    
                } label: {
                    Text("2")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print("3")
                    
                } label: {
                    Text("3")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                
            }
            HStack (spacing: 5){
                Button {
                    print("4")
                    
                } label: {
                    Text("4")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print("5")
                    
                } label: {
                    Text("5")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print("6")
                    
                } label: {
                    Text("6")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                
            }
            HStack (spacing: 5){
                Button {
                    print("7")
                    
                } label: {
                    Text("7")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print("8")
                    
                } label: {
                    Text("8")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print("9")
                    
                } label: {
                    Text("9")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
            }
            HStack (spacing: 5){
                Button {
                    print("+/-")
                    
                } label: {
                    Text("+/-")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print("0")
                    
                } label: {
                    Text("0")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
                
                Button {
                    print(".")
                    
                } label: {
                    Text(".")
                }                .frame(width: 0.25*width, height: 0.25*height)                .border(.orange)
                
            }
            
        }.frame(width: width, height: height)
            .background(Color(uiColor: UIColor(red: 41 / 255,
                                               green: 42 / 255,
                                               blue: 48 / 255,
                                               alpha: 1)))
    }
}

struct Numpad_Previews: PreviewProvider {
    static var previews: some View {
        Numpad(width: 100, height: 160)
    }
}
