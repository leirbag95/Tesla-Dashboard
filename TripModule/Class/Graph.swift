//
//  Graph.swift
//  Mapped
//
//  Created by Gabriel Elfassi on 17/04/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import Foundation
import UIKit

class Graph {
    var order:Int = 0
    var adjMatrix:[[Double]] = []
    var shortestPath:[Int] = []
    
    init(order:Int = 0, adjMatrix:[[Double]] = []) {
        self.order = order
        self.adjMatrix = adjMatrix
    }
    
    // MARK: Détermine le plus court chemin entre tous les couples de sommet (x,y) du graph.
    public func GetShortestPath() -> [Int]{
        var M:[Bool] = [] // Vecteur marque
        for _ in 0..<adjMatrix.count {
            M.append(false)
        }
        shortestPath = RecGetShortestPath(M: &M, i: 0)
        return shortestPath
    }
    
    private func RecGetShortestPath(M: inout [Bool], i:Int) -> [Int] {
        if M[i] {
            return shortestPath
        }
        M[i] = true
        shortestPath.append(i)
        let index = GetIndexShortestDistance(matrix: adjMatrix[i], M: M)
        return RecGetShortestPath(M: &M, i: index)
    }
    
    // MARK: Détermine l'indice de la plus petite distance
    private func GetIndexShortestDistance(matrix:[Double], M :[Bool]) -> Int {
        var mini = Double.infinity
        var index = 0
        for i in 0..<matrix.count {
            if mini > matrix[i] && !M[i] {
                mini = matrix[i]
                index = i
            }
        }
        return index
    }
}
