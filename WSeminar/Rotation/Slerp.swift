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



class Helper: NSObject, ObservableObject {
    var pC: SCNNode = SCNNode()
    var gyroQuad: simd_quatf = simd_quatf()
    var vertexRotations: [simd_quatf] = [simd_quatf()]
    var displaylink: CADisplayLink = CADisplayLink()
    override init() {
        print("helper runs")
    }
    
    func setpC (pC: SCNNode) {
        self.pC = pC
    }
    
    func setGyroQuad(gyroQuad: simd_quatf) {
        self.gyroQuad = gyroQuad
    }
    
    func setVertexRotations (vertexRotations: [simd_quatf]) {
        self.vertexRotations = vertexRotations
    }
    
    func setDisplaylink(displayLink: CADisplayLink) {
        self.displaylink = displayLink
    }
    
    var cube: [simd_float3] = [
        simd_float3(x: -0.5, y: -0.5, z: 0.5),
        simd_float3(x: 0.5, y: -0.5, z: 0.5),
        simd_float3(x: -0.5, y: -0.5, z: -0.5),
        simd_float3(x: 0.5, y: -0.5, z: -0.5),
        simd_float3(x: -0.5, y: 0.5, z: 0.5),
        simd_float3(x: 0.5, y: 0.5, z: 0.5),
        simd_float3(x: -0.5, y: 0.5, z: -0.5),
        simd_float3(x: 0.5, y: 0.5, z: -0.5)
        ]
    let cubeVertexOrigins: [simd_float3] = [
        simd_float3(x: -0.5, y: -0.5, z: 0.5),
        simd_float3(x: 0.5, y: -0.5, z: 0.5),
        simd_float3(x: -0.5, y: -0.5, z: -0.5),
        simd_float3(x: 0.5, y: -0.5, z: -0.5),
        simd_float3(x: -0.5, y: 0.5, z: 0.5),
        simd_float3(x: 0.5, y: 0.5, z: 0.5),
        simd_float3(x: -0.5, y: 0.5, z: -0.5),
        simd_float3(x: 0.5, y: 0.5, z: -0.5)
        ]
    
    var vertexRotationIndex = 0
    var vertexRotationTime: Float = 0
    var previousCube: SCNNode?
    var previousVertexMarker: SCNNode?
    
   
    func vertexRotation() {
        print("vertex")
     

        vertexRotationTime = 0
        vertexRotationIndex = 1

        previousCube = addCube(vertices: cubeVertexOrigins,
                               inScene: gameScene)
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(vertexRotationStep))

        displaylink.add(to: .current,
                         forMode: .default)
    }
    
    @objc
    func vertexRotationStep(displaylink: CADisplayLink) {
        print("rotation")

        previousCube?.removeFromParentNode()
        let increment: Float = 0.02
        vertexRotationTime += increment

        let q: simd_quatf
       
            q = simd_slerp(vertexRotations[vertexRotationIndex],
                           vertexRotations[vertexRotationIndex + 1],
                           vertexRotationTime)
        

        previousVertexMarker?.removeFromParentNode()
        let vertex = cube[5]
        cube = cubeVertexOrigins.map {
            return q.act($0)
        }

        previousVertexMarker = addSphereAt(position: cube[5],
                                           radius: 0.01,
                                           color: .red,
                                           scene: gameScene)

        addLineBetweenVertices(vertexA: vertex,
                               vertexB: cube[5],
                               inScene: gameScene,
                               color: .white)

        previousCube = addCube(vertices: cube, inScene: gameScene)
        if vertexRotationTime >= 1 {
            vertexRotationIndex += 1
            vertexRotationTime = 0

            if vertexRotationIndex > vertexRotations.count - 3 {
                displaylink.invalidate()
            }
        }
    }
    
    
    func addLineBetweenVertices(vertexA: simd_float3,
                                vertexB: simd_float3,
                                inScene scene: SCNScene,
                                useSpheres: Bool = false,
                                color: UIColor = .yellow) {
        if useSpheres {
            addSphereAt(position: vertexB,
                        radius: 0.01,
                        color: .red,
                        scene: scene)
        } else {
            let geometrySource = SCNGeometrySource(vertices: [SCNVector3(x: vertexA.x,
                                                                         y: vertexA.y,
                                                                         z: vertexA.z),
                                                              SCNVector3(x: vertexB.x,
                                                                         y: vertexB.y,
                                                                         z: vertexB.z)])
            let indices: [Int8] = [0, 1]
            let indexData = Data(bytes: indices, count: 2)
            let element = SCNGeometryElement(data: indexData,
                                             primitiveType: .line,
                                             primitiveCount: 1,
                                             bytesPerIndex: MemoryLayout<Int8>.size)

            let geometry = SCNGeometry(sources: [geometrySource],
                                       elements: [element])

            geometry.firstMaterial?.isDoubleSided = true
            geometry.firstMaterial?.emission.contents = color

            let node = SCNNode(geometry: geometry)

            scene.rootNode.addChildNode(node)
        }
    }
    
    func addSphereAt(position: simd_float3, radius: CGFloat = 0.1, color: UIColor, scene: SCNScene) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdPosition = position
        scene.rootNode.addChildNode(sphereNode)

        return sphereNode
    }
    
    @objc func performRotation() {
        var previousCube = pC
        gameScene.rootNode.childNodes.filter({ $0.name == "x" }).forEach({ $0.removeFromParentNode() })
       // previousCube.removeFromParentNode()
        var newCube = cube
        for i in 0..<newCube.count {
            let q = gyroQuad.act(cube[i])
            //print("\(gyroQuad) +  + \(q)")
           // q = gyroQuad.conjugate.act(simd_float3(q.x, q.y, q.z))
            newCube[i] = q
        }
        previousCube = addCube(vertices: newCube,
                               inScene: gameScene)
        pC = previousCube
//        print(newCube)
    }
    
    func addCube(vertices: [simd_float3], inScene scene: SCNScene) -> SCNNode {
        assert(vertices.count == 8, "vertices count must be 3")

        let sceneKitVertices = vertices.map {
            return SCNVector3(x: $0.x, y: $0.y, z: $0.z)
        }
        let geometrySource = SCNGeometrySource(vertices: sceneKitVertices)

        let indices: [Int8] = [
            // bottom
            0, 2, 1,
            1, 2, 3,
            // back
            2, 6, 3,
            3, 6, 7,
            // left
            0, 4, 2,
            2, 4, 6,
            // right
            1, 3, 5,
            3, 7, 5,
            // front
            0, 1, 4,
            1, 5, 4,
            // top
            4, 5, 6,
            5, 7, 6 ]

        let indexData = Data(bytes: indices, count: indices.count)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: 12,
                                         bytesPerIndex: MemoryLayout<Int8>.size)

        let geometry = SCNGeometry(sources: [geometrySource],
                                   elements: [element])

        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.diffuse.contents = UIColor.orange
        //geometry.firstMaterial?.lightingModel = .physicallyBased
        geometry.firstMaterial?.transparency = 0.8
        let node = SCNNode(geometry: geometry)
        node.simdPosition = simd_float3(0, -0.5, 0)
        node.name = "x"
        gameScene.rootNode.addChildNode(node)

        return node
    }
}

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
    
    @State var gE = GyroExtension()
    
    @State var vertexRotations: [simd_quatf] = [
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: 90,
                   axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))),
        simd_quatf(angle: 90,
                   axis: simd_normalize(simd_float3(x: 1, y: 0, z: 0))),
        simd_quatf(angle: 90,
                   axis: simd_normalize(simd_float3(x: 1, y: 0, z: 0)))
    ]
    @State var captureIndex = 2
    @State var performGyro = true
    
    var body: some View {
        ZStack {
            sceneView
            VStack {
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
            update()
        }
        .onAppear {
            initAll()
            print("init all")
            motionManager.startDeviceMotionUpdates()
            print("motionManager")
        }
    }
    
    func capture() {
        //vertexRotations.insert(gyroQuad, at: captureIndex)
        vertexRotations.append(gyroQuad)

        captureIndex += 1
    }
    
    func run() {
        gameScene.rootNode.childNodes.filter({ $0.name == "x" }).forEach({ $0.removeFromParentNode() })
        gE.removeCube()
        let helper = Helper()
        performGyro = false
        //helper.setGyroQuad(gyroQuad: gyroQuad)
        helper.setVertexRotations(vertexRotations: vertexRotations)
        helper.vertexRotation()
    }
  
    
    func initAll() {
        initView()
        initScene()
        initCamera()
        createCoordinatesystem()
        print("init finished")
        
    }
    
    func initView() {
        gameView = SCNView()
        gameView.allowsCameraControl = false
        gameView.autoenablesDefaultLighting = true
    }
    
    func initScene() {
        gameScene = setupSceneKit()
        //gameView.scene = gameScene
        
        gameView.isPlaying = true
    }
    
    func initCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        
        gameScene.rootNode.addChildNode(cameraNode)
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
       if performGyro {
       
           gE.setGyroQuad(gyroQuad: gyroQuad)
           
          // displaylink = CADisplayLink(target: gE, selector: #selector(gyorExtension.performRotation))
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
