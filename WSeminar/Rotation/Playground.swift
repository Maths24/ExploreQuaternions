//
//  Playground.swift
//  ExploreQuaternions
//
//  Created by Matthias on 19.10.22.
//

import SwiftUI
import SceneKit
import QuartzCore
import simd

struct Playground: View {
    @State var gameView:SCNView!
    @State var gameScene:SCNScene!
    @State var cameraNode:SCNNode! //Nodes die Dinger die in Scene zu sehen sind
    
    @State var screenSize: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    @State var allowCameraControll = false
    @State var extendControlls = false
    @State var element = "Axis"
    @State var elements = ["Axis", "Point"]
    var sceneView: some View {
        SceneView(scene: {
            let scene = gameScene
            
            return scene
        }(), options: .allowsCameraControl)
    }
    var body: some View {
        ZStack {
            
            
              
            sceneView
            

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        print("camera control" + String(allowCameraControll))
                        extendControlls.toggle()
                        let image = sceneView.snapshot()
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

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
                        print("extend controlls" + String(extendControlls))
                    } label: {
                        Image(systemName: "plus.app.fill")
                            .resizable()
                            .foregroundColor(Color(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.75)))
                            
                            .frame(width: 60, height: 60)
                            .contentShape(Circle())

                    }
                    .offset(x: -20, y: -20)
                    .ignoresSafeArea()
                
                }
                
            }
            .ignoresSafeArea()
            
            if extendControlls {
                HStack {
                    Spacer()
                    VStack {
                        ZStack {
                            HStack(spacing: 0) {
                                Spacer()
                                VStack {
                                    Rectangle()
                                        .fill(Color(uiColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.7)))
                                        .frame(width: screenSize.width*0.3, height: screenSize.height*0.6)
                                        .cornerRadius(12)
                                        .offset(x: -20, y: 20)
                                    Spacer()
                                }
                            }
                            VStack(alignment: .center) {
                                HStack {
                                    Spacer()
                                    Picker("Select task", selection: $element) {
                                        ForEach(elements, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                    .offset(x: -20, y: 20)
                                    .padding(20)
                                    .pickerStyle(.segmented)
                                    .frame(width: 0.29*screenSize.width)
                                    Spacer()
                                    
                                   
                                }
                                if element == "Axis" {
                                    VStack {
                                        Text("Axis")
                                            .foregroundColor(.white)
                                            .fontWeight(.medium)
                                        Text("t = cos(0°) + sin(0°)\n(0.00i+0.00j+1.00k)")
                                            
                                    }
                                    
                                    
                                } else {
                                    Text("point")
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                        }
                        .frame(width: screenSize.width*0.3, height: screenSize.height*0.6)
                        Spacer()
                    }
                }
               
                
            }
            
            
        }
        .ignoresSafeArea()
        .onAppear() {
            initAll()
            screenSize = UIScreen.main.bounds
            
        }
        
        
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
        gameView.allowsCameraControl = allowCameraControll
        gameView.autoenablesDefaultLighting = true
    }
    
    func initScene() {
        gameScene = setupSceneKit()
        //gameView.scene = gameScene
        
        gameView.isPlaying = true
    }
    
    func setupSceneKit(shadows: Bool = true) ->SCNScene {
        gameView.allowsCameraControl=allowCameraControll
        let scene = SCNScene()
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
        cameraNode.position = SCNVector3(x: 4.0, y: 0.6, z: 3.0)
        
        let lookAt = SCNLookAtConstraint(target: lookAtNode)
        lookAt.isGimbalLockEnabled = true
        lookAt.target?.position = SCNVector3(0, 0, 0)
        cameraNode.constraints = [ lookAt ]
        
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        //lightNode.position = SCNVector3(x: -1.5, y: 2.0, z: 1.5)
        lightNode.position = SCNVector3(x: 4.0, y: 0.6, z: 3.0)
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
       
        
        let mainSphere = createSphere(radius: 0.5)
        scene.rootNode.addChildNode(mainSphere)
        mainSphere.simdPosition = simd_float3(0,-0.5, 0)

        //addAxisArrows(scene: scene)
        let axis = createAxis(color: .orange)
        scene.rootNode.addChildNode(axis)
        axis.simdPosition = simd_float3(0,-0.25, 0)
       

        return scene
    }
    
    func createPoint() -> SCNNode {
        return SCNNode()
    }
    
    func createAxis(color: UIColor) -> SCNNode{
        let cylinder = SCNCylinder(radius: 0.01, height: 0.46)
        cylinder.firstMaterial?.diffuse.contents = color
        cylinder.firstMaterial?.transparency = 1
        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.simdPosition = simd_float3(0, -0.02, 0)
        let spitze = SCNCone(topRadius: 0, bottomRadius: 0.03, height: 0.05)
        spitze.firstMaterial?.diffuse.contents = color
        spitze.firstMaterial?.transparency = 1
        let spitzeNode = SCNNode(geometry: spitze)
        spitzeNode.simdPosition = simd_float3(x: 0, y: 0.2265, z: 0)
        
        let returnNode = SCNNode()
        returnNode.addChildNode(cylinderNode)
        returnNode.addChildNode(spitzeNode)
        returnNode.position = SCNVector3(0, 0, 0)
        
        
        return returnNode
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
        labelYNode.simdPosition = simd_float3(x: 0.1, y: 1.6, z: 0.1)
        labelYNode.scale = SCNVector3(0.01, 0.01, 0.01)
        labelYNode.simdLocalRotate(by: simd_quatf(angle: .pi/4, axis: simd_float3(0, 1, 0)))
        returnNode.addChildNode(labelYNode)
        

        let labelZ = SCNText(string: "z", extrusionDepth: 0)
        labelZ.firstMaterial?.diffuse.contents = UIColor.white
        labelZ.firstMaterial?.transparency = 0.75
        labelZ.firstMaterial?.isDoubleSided = true
        
        let labelZNode = SCNNode(geometry: labelZ)
        labelZNode.simdPosition = simd_float3(x: 0.1, y: 0, z: 1.6)
        labelZNode.scale = SCNVector3(0.01, 0.01, 0.01)
        labelZNode.simdLocalRotate(by: simd_quatf(angle: .pi/2, axis: simd_float3(0, 1, 0)))
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
        spitze.firstMaterial?.transparency = 0.5
        let spitzeNode = SCNNode(geometry: spitze)
        spitzeNode.simdPosition = simd_float3(x: 0, y: 1.6, z: 0)
        
       
        
        let returnNode = SCNNode()
        returnNode.addChildNode(cylinderNode)
        returnNode.addChildNode(spitzeNode)
        returnNode.position = SCNVector3(0, 0, 0)
        
        return returnNode
    }
    
    
    func createSphere(radius: CGFloat) -> SCNNode {
        /*let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.transparency = 0.85
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 0.75, green: 0.5, blue: 0.5, alpha: 1)
        sphere.firstMaterial?.locksAmbientWithDiffuse = true

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdPosition = simd_float3(0, 0, 0)*/
        
        let sphereLines = SCNSphere(radius: radius)
        sphereLines.firstMaterial?.transparency = 1
        sphereLines.firstMaterial?.fillMode = .lines
        
        let sphereNodeLines = SCNNode(geometry: sphereLines)
        sphereNodeLines.simdPosition = simd_float3(0, 0, 0)
        
        let returnNode = SCNNode()
       // returnNode.addChildNode(sphereNode)
        returnNode.addChildNode(sphereNodeLines)
        return returnNode
    }
    
    func initCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
}
    

    
    
struct Playground_Previews: PreviewProvider {
    static var previews: some View {
        Playground()
    }
}
