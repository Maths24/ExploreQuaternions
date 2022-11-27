//
//  BasicSceneExtension.swift
//  ExploreQuaternions
//
//  Created by Matthias on 27.11.22.
//

import Foundation
import SwiftUI
import SceneKit

extension View {
    
    
    
    func setupSceneKit(shadows: Bool = true) ->SCNScene {
        let scene = gameScene
        scene.background.contents = UIColor(Color("background"))
        
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
       
        createCoordinatesystem()
        createArea()
        
        

        return scene
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
