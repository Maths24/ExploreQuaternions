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
        previousCube.removeFromParentNode()
        var newCube = cube
        for i in 0..<newCube.count {
            let q = gyroQuad.act(cube[i])
            //print("\(gyroQuad) +  + \(q)")
           // q = gyroQuad.conjugate.act(simd_float3(q.x, q.y, q.z))
            newCube[i] = q
        }
        previousCube = addCube(vertices: newCube,
                               inScene: gameScene)
       
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

struct Gyro: View {
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
    
    @State var vertexRotations: [simd_quatf] = [
        /*simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1)))*/
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
        let helper = Helper()
        performGyro = false
        helper.setGyroQuad(gyroQuad: gyroQuad)
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
    
    func setupSceneKit(shadows: Bool = true) ->SCNScene {
        gameView.allowsCameraControl=false
        let scene = gameScene
        gameView.scene = scene
        scene.background.contents = UIColor(red: 41 / 255,
                                            green: 42 / 255,
                                            blue: 48 / 255,
                                            alpha: 1)
        
        let lookAtNode = SCNNode()
        lookAtNode.position = SCNVector3(0, 0, 0)
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        cameraNode.camera = camera
        camera.fieldOfView = 35
        //camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.5
        //cameraNode.position = SCNVector3(x: 2.5, y: 2.0, z: 5.0)
        cameraNode.position = SCNVector3(x: 0, y: 0.6, z: 5.0)

        
        let lookAt = SCNLookAtConstraint(target: lookAtNode)
        lookAt.isGimbalLockEnabled = true
        lookAt.target?.position = SCNVector3(0, 0, 0)
        cameraNode.constraints = [ lookAt ]
        
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: -1.5, y: 2.0, z: 1.5)
        
        if shadows {
            light.type = .directional
            light.castsShadow = true
            light.shadowSampleCount = 8
            lightNode.constraints = [ lookAt ]
        }
        
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.5, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        
        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientNode)
       
        
        

        return scene
    }
    func addCube(vertices: [simd_float3]) -> SCNNode {
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
        //gameScene.rootNode.addChildNode(node)

        return node
    }
    
    func update() {
    
            
            
            print("updating")
            if let data = motionManager.deviceMotion {
                print("Läuft!!")
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
    
    let cube: [simd_float3] = [
        simd_float3(x: -0.5, y: -0.5, z: 0.5),
        simd_float3(x: 0.5, y: -0.5, z: 0.5),
        simd_float3(x: -0.5, y: -0.5, z: -0.5),
        simd_float3(x: 0.5, y: -0.5, z: -0.5),
        simd_float3(x: -0.5, y: 0.5, z: 0.5),
        simd_float3(x: 0.5, y: 0.5, z: 0.5),
        simd_float3(x: -0.5, y: 0.5, z: -0.5),
        simd_float3(x: 0.5, y: 0.5, z: -0.5)
        ]
    
    lazy var cubeV = cubeVertexOrigins

    let sky1 = MDLSkyCubeTexture(name: "sky",
                                channelEncoding: MDLTextureChannelEncoding.float16,
                                textureDimensions: simd_int2(x: 128, y: 128),
                                turbidity: 0.5,
                                sunElevation: 0.5,
                                sunAzimuth: 0.5,
                                upperAtmosphereScattering: 0.5,
                                groundAlbedo: 0.5)
    
  
   func rotateCube() {
       if performGyro {
           
           
           print("rotate cube")
           // gameScene.lightingEnvironment.contents = sky1
           //  gameScene.rootNode.childNode(withName: "cameraNode",
           //                         recursively: false)?.camera?.usesOrthographicProjection = false
           print("first helper")
           
           previousCube = addCube(vertices: cubeVertexOrigins)
           
           //gameScene.rootNode.addChildNode(previousCube!)
           
           let helper = Helper()
           helper.setGyroQuad(gyroQuad: gyroQuad)
           helper.setpC(pC: previousCube!)
           print("second helper")
           print(Unmanaged.passUnretained(helper).toOpaque())
           
           displaylink = CADisplayLink(target: helper, selector: #selector(helper.performRotation))
           previousCube!.removeFromParentNode()
           
           displaylink?.add(to: .current,
                            forMode: .default)
           print("cube rotated")
       }
    }
    
    func createCoordinatesystem() {
        let arrowx =  createArrow(color: .gray)
        arrowx.simdLocalRotate(by: simd_quatf(angle: -.pi/2, axis: simd_float3(0, 0, 1)))
        let arrowy =  createArrow(color: .gray)
        let arrowz = createArrow(color: .gray)
        arrowz.simdLocalRotate(by: simd_quatf(angle: .pi/2, axis: simd_float3(1, 0, 0)))
        
        
        let coornode = SCNNode()
        coornode.addChildNode(arrowx)
        coornode.addChildNode(arrowy)
        coornode.addChildNode(arrowz)
        coornode.simdPosition = simd_float3(0,-0.5, 0)
        
        gameScene.rootNode.addChildNode(coornode)
        let areaNode = createArea()
        areaNode.simdPosition = simd_float3(0,-0.5, 0)

        gameScene.rootNode.addChildNode(areaNode)
        
        let labelNode = createLabelsForCoordinateAxis()
        labelNode.simdPosition = simd_float3(0, -0.5, 0)
       
        gameScene.rootNode.addChildNode(labelNode)
    }
    
    func createArea() -> SCNNode {
        let returnNode = SCNNode()
        for i in 1...13 {
            let cylinder = SCNCylinder(radius: 0.001, height: 5)
            cylinder.firstMaterial?.diffuse.contents = UIColor(red: 213, green: 213, blue: 213, alpha: 1)
            cylinder.firstMaterial?.transparency = 0.5
            let cylinderNode = SCNNode(geometry: cylinder)
            cylinderNode.simdPosition = simd_float3(0, 0, Float(i)*0.4-2.8)
            cylinderNode.simdLocalRotate(by: simd_quatf(angle: -.pi/2, axis: simd_float3(0, 0, 1)))
            returnNode.addChildNode(cylinderNode)
        }
        for i in 1...13 {
            let cylinder = SCNCylinder(radius: 0.001, height: 5)
            cylinder.firstMaterial?.diffuse.contents = UIColor(red: 213, green: 213, blue: 213, alpha: 1)
            cylinder.firstMaterial?.transparency = 0.5

            let cylinderNode = SCNNode(geometry: cylinder)
            cylinderNode.simdPosition = simd_float3(Float(i)*0.4-2.8, 0, 0)
            cylinderNode.simdLocalRotate(by: simd_quatf(angle: -.pi/2, axis: simd_float3(1, 0, 0)))
            returnNode.addChildNode(cylinderNode)
        }
        
        return returnNode
    }
    
    func createLabelsForCoordinateAxis() -> SCNNode {
        let returnNode = SCNNode()

        let labelX = SCNText(string: "x", extrusionDepth: 0)
        labelX.firstMaterial?.diffuse.contents = UIColor.white
        labelX.firstMaterial?.transparency = 0.75
        labelX.firstMaterial?.isDoubleSided = true
        
        let labelXNode = SCNNode(geometry: labelX)
        labelXNode.simdPosition = simd_float3(x: 1.6, y: 0, z: 0)
        labelXNode.scale = SCNVector3(0.01, 0.01, 0.01)
        returnNode.addChildNode(labelXNode)
        

        let labelY = SCNText(string: "y", extrusionDepth: 0)
        labelY.firstMaterial?.diffuse.contents = UIColor.white
        labelY.firstMaterial?.transparency = 0.75
        labelY.firstMaterial?.isDoubleSided = true
        
        let labelYNode = SCNNode(geometry: labelY)
        labelYNode.simdPosition = simd_float3(x: 0, y: 1.6, z: 0.05)
        labelYNode.scale = SCNVector3(0.01, 0.01, 0.01)
        labelYNode.simdLocalRotate(by: simd_quatf(angle: 0, axis: simd_float3(0, 1, 0)))
        returnNode.addChildNode(labelYNode)
        

        let labelZ = SCNText(string: "z", extrusionDepth: 0)
        labelZ.firstMaterial?.diffuse.contents = UIColor.white
        labelZ.firstMaterial?.transparency = 0.75
        labelZ.firstMaterial?.isDoubleSided = true
        
        let labelZNode = SCNNode(geometry: labelZ)
        labelZNode.simdPosition = simd_float3(x: 0, y: 0, z: 1.6)
        labelZNode.scale = SCNVector3(0.01, 0.01, 0.01)
        labelZNode.simdLocalRotate(by: simd_quatf(angle: 0, axis: simd_float3(0, 1, 0)))
        returnNode.addChildNode(labelZNode)
        
        
        
        return returnNode
    }
    
    func createArrow(color: UIColor) -> SCNNode{
        let cylinder = SCNCylinder(radius: 0.0075, height: 5.1)
        cylinder.firstMaterial?.diffuse.contents = color
        cylinder.firstMaterial?.transparency = 0.75
        let cylinderNode = SCNNode(geometry: cylinder)
        
        let spitze = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.1)
        spitze.firstMaterial?.diffuse.contents = color
        spitze.firstMaterial?.transparency = 1
        let spitzeNode = SCNNode(geometry: spitze)
        spitzeNode.simdPosition = simd_float3(x: 0, y: 1.6, z: 0)
        
       
        
        let returnNode = SCNNode()
        returnNode.addChildNode(cylinderNode)
        returnNode.addChildNode(spitzeNode)
        returnNode.position = SCNVector3(0, 0, 0)
        
        return returnNode
    }
    
    
    
}

struct Gyro_Previews: PreviewProvider {
    static var previews: some View {
        Gyro()
    }
}
