//
//  Gyro.swift
//  ExploreQuaternions
//
//  Created by Matthias on 19.10.22.
//

import SwiftUI
import CoreMotion
import simd
import ModelIO
import SceneKit

var gameScene = SCNScene()
var gE = GyroExtension()



struct Gyro: View {
    // Motion Data
    let motionManager = CMMotionManager()
    @State var gyroQuad = simd_quatf(angle: 0,
                                     axis: simd_normalize(simd_float3(x: 0, y: 0, z: 0)))
    
    @State var gameView:SCNView!
    @State var cameraNode:SCNNode!
    
    @State var displaylink: CADisplayLink?
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    var sceneView: some View {
        SceneView(scene: {
            let scene = gameScene
            
            return scene
        }(), options: .allowsCameraControl)
    }
    
   // @State var gyroExtension = GyroExtension()
    
    
    var body: some View {
        ZStack {
            sceneView
                .background(Color("background"))

        }
        .ignoresSafeArea()
        .onReceive(timer) {_ in
            update()
        }
        .onAppear {
            gE.render = true
            motionManager.startDeviceMotionUpdates()
        }
        .onDisappear {
            gE.removeCube()

        }
    }

  
    
    
    func update() {
        if let data = motionManager.deviceMotion {
            var w = data.attitude.quaternion.w
            var x = data.attitude.quaternion.y
            var y = data.attitude.quaternion.z
            var z = data.attitude.quaternion.x
            let norm = sqrt(pow(x, 2)+pow(y, 2)+pow(z, 2)+pow(w, 2))
            w = w/norm
            x = x/norm
            y = y/norm
            z = z/norm
            let angelInput = 2*acos(w)
            let axisX = x/sqrt(1-pow(w, 2))
            let axisY = y/sqrt(1-pow(w, 2))
            let axisZ = z/sqrt(1-pow(w, 2))
            let tempQuad = simd_quatf(angle: Float(angelInput),
                                      axis: simd_normalize(simd_float3(x: Float(axisX), y: Float(axisY), z: Float(axisZ))))
            self.gyroQuad = tempQuad
            rotateCube()
        }
    }
    
    func rotateCube() {
 
        gE.setGyroQuad(gyroQuad: gyroQuad)
        
        displaylink = CADisplayLink(target: gE, selector: #selector(gE.performRotation))
        displaylink?.add(to: .current,
                         forMode: .default)
        
        
    }
  
}

struct Gyro_Previews: PreviewProvider {
    static var previews: some View {
        Gyro()
    }
}
