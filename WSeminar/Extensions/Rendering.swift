//
//  Rendering.swift
//  ExploreQuaternions
//
//  Created by Matthias on 09.11.22.
//

import Foundation
import SceneKit


class Renderer: NSObject, ObservableObject {
    var pC: SCNNode = SCNNode()
    var gyroQuad: simd_quatf = simd_quatf()
    var vertexRotations: [simd_quatf] = [simd_quatf()]
    var displaylink: CADisplayLink = CADisplayLink()
    var gameScene = SCNScene()
    
    override init() {
        print("helper runs")
    }
    
    func setGameScene(gameScene: SCNScene) {
        self.gameScene = gameScene
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
