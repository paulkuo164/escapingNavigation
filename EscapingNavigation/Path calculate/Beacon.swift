//
//  Beacon.swift
//  EscapingNavigation
//
//  Created by Iris on 2018/4/13.
//  Copyright © 2018年 Apple. All rights reserved.
//

import Foundation
import GameplayKit

class Beacon{
    var uuid = ""
    var major = ""
    var minor = ""
    var accuracy = CGFloat()
    var position = CGPoint()
    init(){
        
    }
    init(coor:[String]){
        uuid = coor[1]
        position = CGPoint(x:Double(coor[2])!,y:Double(coor[3])!)
    }
    func getBeaconNode()->SKShapeNode{
        let beaconNode = SKShapeNode(circleOfRadius: accuracy)
        beaconNode.position = position
        beaconNode.fillColor = UIColor.green
        beaconNode.strokeColor = UIColor.blue
        beaconNode.alpha = 0.5
        return beaconNode
    }
}


func intersectionOfTwoCircle(b1:Beacon, b2:Beacon)->[CGPoint]?{
    let (x1,y1,r1) = (b1.position.x,b1.position.y,b1.accuracy)
    let (x2,y2,r2) = (b2.position.x,b2.position.y,b2.accuracy)
    let r = sqrt((b2.position.x-b1.position.x)**2+(b2.position.y-b1.position.y)**2)
    guard abs(r2-r1) <= r, r <= (r1+r2)
        else{return nil}
    let dSquares = r1**2-r2**2
    let a = dSquares/(r*r*2)
    let c = sqrt(2*(r1*r1+r2*r2)/r**2-dSquares*dSquares/r**4-1)
    let (fx, fy) = ((x1 + x2) / 2 + a * (x2 - x1), (y1 + y2) / 2 + a * (y2 - y1))
    let (gx, gy) = (c * (y2 - y1) / 2, c * (x1 - x2) / 2)
    return [CGPoint(x: fx + gx, y: fy + gy),CGPoint(x: fx - gx, y: fy - gy)]
}
func intersectionOfTwoLine(p1:CGPoint,p2:CGPoint,p3:CGPoint,p4:CGPoint)->CGPoint?{
    let k = (p1.x-p2.x)*(p3.y-p4.y)-(p1.y-p2.y)*(p3.x-p4.x)
    guard k != 0
        else{return nil}
    let x = ((p1.x*p2.y-p1.y*p2.x)*(p3.x-p4.x)-(p1.x-p2.x)*(p3.x*p4.y-p3.y*p4.x))/k
    let y = ((p1.x*p2.y-p1.y*p2.x)*(p3.y-p4.y)-(p1.y-p2.y)*(p3.x*p4.y-p3.y*p4.x))/k
    return CGPoint(x:x,y:y)
}
