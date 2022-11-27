//
//
//  Addition.swift
//  ExploreQuaternions
//
//  Created by Matthias on 19.10.22.
//

import SwiftUI

struct AddSub: View {
    var q1 = [0.0, 0.0, 0.0, 0.0]
    var q2 = [0.0, 0.0, 0.0, 0.0]
   @State  var numpad = false
    var body: some View {
        Text("x_0")
            .onTapGesture {
                numpad.toggle()
            }
        if numpad {
            Numpad(width: 120, height: 160)

        }
    }
    
    
}

struct Addition_Previews: PreviewProvider {
    static var previews: some View {
        AddSub()
    }
}
