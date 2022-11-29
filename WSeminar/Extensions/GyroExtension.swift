//
//  GyroExtension.swift
//  ExploreQuaternions
//
//  Created by Matthias on 26.11.22.
//

import Foundation
import SceneKit
import simd

class GyroExtension: NSObject, ObservableObject {
    var pC: SCNNode = SCNNode()
    var gyroQuad: simd_quatf = simd_quatf()
    var vertexRotations: [simd_quatf] = [simd_quatf()]
    var displaylink: CADisplayLink = CADisplayLink()
    var newCube = [simd_float3]()
    var render = true
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
    
    func getCube() -> [simd_float3] {
        return newCube
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

    @objc func performRotation() {
        if render {
            //gameScene.rootNode.childNodes.filter({ $0.name == "x" }).forEach({ $0.removeFromParentNode() })
            removeCube()

            newCube = cube
            for i in 0..<newCube.count {
                let q = gyroQuad.act(cube[i])
              
                newCube[i] = q
            }
            
            pC = addCube(vertices: newCube)
            gameScene.rootNode.addChildNode(pC)
    //        print(newCube)
        }
        
    }
    
    func renderCube() -> SCNNode {
        print(pC)
        return pC
    }
    
    func removeCube() {
        pC.removeFromParentNode()
        //gameScene.rootNode.childNodes.filter({ $0.name == "x" }).forEach({ $0.removeFromParentNode() })
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
        geometry.firstMaterial?.transparency = 1
        let node = SCNNode(geometry: geometry)
        node.simdPosition = simd_float3(0, -0.5, 0)
        node.name = "x"

        return node
    }
}
