//
//  Element.swift
//  EscapingNavigation
//
//  Created by Iris on 2018/4/13.
//  Copyright © 2018年 Apple. All rights reserved.
//

import Foundation
import GameplayKit

class Element {
    var category:String = ""
    var point1: CGPoint = CGPoint()
    var point2: CGPoint = CGPoint()
    init(){
        
    }
    init(coor:[String]) {
        category = coor[0]
        point1 = CGPoint(x:Double(coor[1])!,y:Double(coor[2])!)
        point2 = CGPoint(x:Double(coor[4])!,y:Double(coor[5])!)
    }
}
class Column:Element{
    
}
class Wall:Element{
    var id:String = ""
    var XY = true
    func setId(){
        let start = category.index(category.endIndex, offsetBy: -8)
        let end = category.index(category.endIndex, offsetBy: -2)
        id = String(category[start..<end])
    }
    func setXY(){
        if (abs(point1.x-point2.x)<abs(point1.y-point2.y)){
            XY = false
        }
        else{
            XY=true
        }
    }
}
class Door:Element{
    var host:String = ""
    func setHost(){
        let start = category.index(category.endIndex, offsetBy: -8)
        let end = category.index(category.endIndex, offsetBy: -2)
        host = String(category[start..<end])
    }
}
class EndElement:Element{
    var endPoint: CGPoint = CGPoint()
    func setEndPoint(){
        endPoint = CGPoint(x:(point1.x+point2.x)/2,y:(point1.y+point2.y)/2)
    }
}


