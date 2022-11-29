//
//  SlerpExtension.swift
//  ExploreQuaternions
//
//  Created by Matthias on 27.11.22.
//

import Foundation
import SceneKit
import simd

class SlerpExtension: NSObject, ObservableObject {
    //var pC: SCNNode = SCNNode()
    var vertexRotations: [simd_quatf] = [simd_quatf()]
    var displaylink: CADisplayLink = CADisplayLink()
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
    
    var cubeVertexOrigins: [simd_float3] = [
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
    var previousCube: SCNNode = SCNNode()
    var previousVertexMarker: SCNNode?
    
    func setpC (pC: SCNNode) {
        self.previousCube = pC
    }
    

    
    func setVertexRotations (vertexRotations: [simd_quatf]) {
        self.vertexRotations = vertexRotations
    }
    
    func setDisplaylink(displayLink: CADisplayLink) {
        self.displaylink = displayLink
    }
    
    func setCubeVertexOrigins(cbo: [simd_float3]) {
        cubeVertexOrigins = cbo
    }
    
  
    
   
    func vertexRotation() {
        vertexRotations.insert(vertexRotations[0], at: 0)
        vertexRotations.insert(vertexRotations[vertexRotations.count-1], at: vertexRotations.count-1)
        previousCube.removeFromParentNode()
        gameScene.rootNode.childNodes.filter({ $0.name == "x" }).forEach({ $0.removeFromParentNode() })

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

        previousCube.removeFromParentNode()
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

        let c = UIColor(red: CGFloat(vertexRotations[vertexRotationIndex].axis.x), green: CGFloat(vertexRotations[vertexRotationIndex].axis.y), blue: CGFloat(vertexRotations[vertexRotationIndex].axis.z), alpha: 1)
        addLineBetweenVertices(vertexA: vertex,
                               vertexB: cube[5],
                               inScene: gameScene,
                               color: c)

        previousCube = addCube(vertices: cube, inScene: gameScene)
        if vertexRotationTime >= 1 {
            vertexRotationIndex += 1
            vertexRotationTime = 0

            if vertexRotationIndex > vertexRotations.count - 3 {
                displaylink.invalidate()
                previousCube.removeFromParentNode()
                gE.render = true
            }
        }
    }
    
    
    func addLineBetweenVertices(vertexA: simd_float3,
                                vertexB: simd_float3,
                                inScene scene: SCNScene,
                                useSpheres: Bool = false,
                                color: UIColor = .yellow) {
        if useSpheres {
            gameScene.rootNode.addChildNode(addSphereAt(position: vertexB,
                        radius: 0.01,
                        color: .red,
                        scene: scene))
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
            node.simdPosition = simd_float3(0,-0.5, 0)
            scene.rootNode.addChildNode(node)
        }
    }
    
    func addSphereAt(position: simd_float3, radius: CGFloat = 0.1, color: UIColor, scene: SCNScene) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdPosition = position
        sphereNode.simdPosition = simd_float3(0,-0.5, 0)
        scene.rootNode.addChildNode(sphereNode)

        return sphereNode
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
        geometry.firstMaterial?.transparency = 1
        let node = SCNNode(geometry: geometry)
        node.simdPosition = simd_float3(0, -0.5, 0)
        node.name = "x"
        gameScene.rootNode.addChildNode(node)

        return node
    }
}
