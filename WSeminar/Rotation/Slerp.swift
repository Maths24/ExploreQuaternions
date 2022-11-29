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





struct Slerp: View {
    // Motion Data
     let motionManager = CMMotionManager()
     @State var gyroQuad = simd_quatf(angle: 0,
                axis: simd_normalize(simd_float3(x: 0, y: 0, z: 0)))
    @State var gameView:SCNView!
    @State var cameraNode:SCNNode! //Nodes die Dinger die in Scene zu sehen sind
    @State var displaylink: CADisplayLink?
    @State var previousCube: SCNNode?
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    var sceneView: some View {
        SceneView(scene: {
            let scene = gameScene
            
            return scene
        }(), options: .allowsCameraControl)
    }
    
    
    @State var vertexRotations: [simd_quatf] = []
    @State var captureIndex = 0
    @State var performGyro = true
    let slerpExtension = SlerpExtension()
    var body: some View {
        ZStack {
            sceneView
                .background(Color("background"))
            VStack {
                List {
                    ForEach(vertexRotations) { v in
                        
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    Button {
                       print("Capture")
                        self.capture()
                    } label: {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .foregroundColor(Color(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.75)))
                            
                            .frame(width: 60, height: 60)
                            .contentShape(Circle())

                    }
                    .offset(x: -20, y: -20)
                    .ignoresSafeArea()
                    Button {
                       print("Run animation")
                        self.run()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .foregroundColor(Color(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.75)))
                            
                            .frame(width: 60, height: 60)
                            .contentShape(Circle())

                    }
                    .offset(x: -20, y: -20)
                    .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
        .onReceive(timer) {_ in
            if performGyro {
                update()
            }
          
        }
        .onAppear {
            gE.render = true
            gE.removeCube()
            motionManager.startDeviceMotionUpdates()
        }
        .onDisappear {
            print("disappear")
           slerpExtension.previousCube.removeFromParentNode()

        }
    }
    
    func capture() {
        vertexRotations.append(gyroQuad)

        captureIndex += 1
    }
    
    func run() {
        gE.render = false
        performGyro = false
        displaylink!.invalidate()

        slerpExtension.setpC(pC: gE.pC)
        slerpExtension.setCubeVertexOrigins(cbo: gE.getCube())
        slerpExtension.setVertexRotations(vertexRotations: vertexRotations)
        slerpExtension.vertexRotation()
        print("finish")
        slerpExtension.previousCube.removeFromParentNode()
        performGyro = true

    }
  
    

    
    
    func update() {
        if performGyro == false {
            return
        }
        if performGyro {
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
            
}

  
   func rotateCube() {
       if performGyro {
       
           gE.setGyroQuad(gyroQuad: gyroQuad)
           
           displaylink = CADisplayLink(target: gE, selector: #selector(gE.performRotation))
           displaylink?.add(to: .current,
                            forMode: .default)

       }
    }
    
    
    
}

struct Slerp_Previews: PreviewProvider {
    static var previews: some View {
        Slerp()
    }
}
