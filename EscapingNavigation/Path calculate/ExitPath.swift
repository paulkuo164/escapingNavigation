//
//  ExitPath.swift
//  ARKitInteraction
//
//  Created by Iris on 2018/2/22.
//  Copyright © 2018年 Apple. All rights reserved.
//

import Foundation
import GameplayKit
import CoreLocation

class ExitPath:SKScene {
    
    var northAngle = CGFloat()
    var columnList = [Column()]
    var wallList = [Wall()]
    var doorList = [Door()]
    var endElementList = [EndElement()]
    var beaconList = [Beacon()]
    var regionList = [CLBeaconRegion(proximityUUID: UUID(uuidString: "9E9D4B72-E35F-40F7-9216-C12C865CBCD2")!, major: CLBeaconMajorValue("100")!, minor: CLBeaconMinorValue("100")!, identifier: "1"),CLBeaconRegion(proximityUUID: UUID(uuidString: "9E9D4B72-E35F-40F7-9216-C12C865CBCD2")!, major: CLBeaconMajorValue("400")!, minor: CLBeaconMinorValue("400")!, identifier: "2"),CLBeaconRegion(proximityUUID: UUID(uuidString: "9E9D4B72-E35F-40F7-9216-C12C865CBCD2")!, major: CLBeaconMajorValue("300")!, minor: CLBeaconMinorValue("300")!, identifier: "3"),CLBeaconRegion(proximityUUID: UUID(uuidString: "9E9D4B72-E35F-40F7-9216-C12C865CBCD2")!, major: CLBeaconMajorValue("500")!, minor: CLBeaconMinorValue("500")!, identifier: "4")]
    var graph = GKObstacleGraph()
    
    
    func read(){
        northAngle = CGFloat((34+90)*Float.pi/180)  //北邊的角度
        //transform = CGAffineTransform.init(rotationAngle: northAngle)
        var data = ""
        let coorURL = Bundle.main.path(forResource: "coorOutput", ofType: "txt")
        do {
            data = try String(contentsOfFile: coorURL!, encoding: String.Encoding.utf8)
        }catch let error as NSError{
            print("failed to read obstacles' coordinate")
            print(error)
        }
        let coors = data.components(separatedBy: .newlines)
        coors.forEach{coor in
            let temp = coor.components(separatedBy: " ")
            if (temp[0].contains("column")){
                let c = Column(coor:temp)
                columnList.append(c)
            }
            else if (temp[0].contains("wall")){
                let w = Wall(coor:temp)
                w.setId()
                w.setXY()
                wallList.append(w)
            }
            else if (temp[0].contains("hole")){
                let d = Door(coor:temp)
                d.setHost()
                doorList.append(d)
            }
            else if (temp[0].contains("endpoint")){
                let e = EndElement(coor:temp)
                e.setEndPoint()
                endElementList.append(e)
            }
            else if (temp[0].contains("beacon")){
                let b = Beacon(coor:temp)
                beaconList.append(b)
                regionList.append(registerBeaconRegionWithUUID(uuidString: b.uuid, identifier: NSStringFromCGPoint(b.position)))
            }
        }
        columnList.remove(at: 0)
        wallList.remove(at: 0)
        doorList.remove(at: 0)
        endElementList.remove(at: 0)
        beaconList.remove(at:0)
        
        //////////////////////加入現有Beacon
        let b1 = Beacon()
        b1.uuid = "9E9D4B72-E35F-40F7-9216-C12C865CBCD2"
        b1.major = "100"
        b1.minor = "100"
       // b1.position = CGPoint(x:-108.779136336392, y:38.3904228866082)   //Beacon在模型中的位置
       // b1.position = CGPoint(x:-89.4951796379005, y:26.1856984253297)
        //b1.position = CGPoint(x:-10.0245, y:18.5741)
        b1.position = CGPoint(x:-71.5074, y:20.1653)
        beaconList.append(b1)
        
        let b2 = Beacon()
        b2.uuid = "9E9D4B72-E35F-40F7-9216-C12C865CBCD2"
        b2.major = "400"
        b2.minor = "400"
        //b2.position = CGPoint(x:-56.4730354422094, y:25.1194255085707)
        //b2.position = CGPoint(x:-121.695638955485, y:47.084648608393)
        //b2.position = CGPoint(x:-17.244, y:30.48)
        b2.position = CGPoint(x:-87.2555, y:20.3622)
        beaconList.append(b2)
        
        let b3 = Beacon()
        b3.uuid = "9E9D4B72-E35F-40F7-9216-C12C865CBCD2"
        b3.major = "300"
        b3.minor = "300"
       //b3.position = CGPoint(x:-110.679072187616, y:21.5761184257893)
       // b3.position = CGPoint(x:-90.7332045722847, y:46.1409150125924)
        //b3.position = CGPoint(x:21.061, y:30.4835)
         b3.position = CGPoint(x:-71.7043, y:3.9744)

        beaconList.append(b3)
        
        let b4 = Beacon()
        b4.uuid = "9E9D4B72-E35F-40F7-9216-C12C865CBCD2"
        b4.major = "500"
        b4.minor = "500"
       // b4.position = CGPoint(x:-73.7958700878787, y:21.8385856135576)
       // b4.position = CGPoint(x:-123.566773400564, y:26.5880934384531)
        //b4.position = CGPoint(x:21.061, y:16.507)
        b4.position = CGPoint(x:-79.9064, y:13.2755)
        beaconList.append(b4)
    }
    
    
    
    func buildModel()-> [SKShapeNode]{      //gamekit創建模型
        var obstacleShapeNodes:[SKShapeNode] = []
        wallList.forEach{wall in
            var hostDoors = [Door()]
            hostDoors.remove(at: 0)
            doorList.forEach{door in
                if (wall.id.contains(door.host)){
                    hostDoors.append(door)
                }
            }
            if (hostDoors.count>0){
                if (wall.XY){
                    hostDoors.sort(by: {abs(wall.point1.x-$0.point1.x)<abs(wall.point1.x-$1.point1.x)})
                    var position1 = wall.point1
                    var position2 = CGPoint(x:hostDoors[0].point1.x,y:wall.point2.y)
                    var obstacle = obstacleNode(position1: position1, position2: position2)  //使用下面的function
                    obstacleShapeNodes.append(obstacle)
                    if (hostDoors.count>1){
                        for i in 1..<hostDoors.count{
                            position1 = CGPoint(x:hostDoors[i-1].point2.x,y:wall.point1.y)
                            position2 = CGPoint(x:hostDoors[i].point1.x,y:wall.point2.y)
                            obstacle = obstacleNode(position1: position1, position2: position2)
                            obstacleShapeNodes.append(obstacle)
                        }
                    }
                    position1 = CGPoint(x:hostDoors[hostDoors.count-1].point2.x,y:wall.point1.y)
                    position2 = wall.point2
                    obstacle = obstacleNode(position1: position1, position2: position2)
                    obstacleShapeNodes.append(obstacle)
                }
                else{
                    hostDoors.sort(by: {abs(wall.point1.y-$0.point1.y)<abs(wall.point1.y-$1.point1.y)})
                    var position1 = wall.point1
                    var position2 = CGPoint(x:wall.point2.x,y:hostDoors[0].point1.y)
                    var obstacle = obstacleNode(position1: position1, position2: position2)
                    obstacleShapeNodes.append(obstacle)
                    if (hostDoors.count>1){
                        for i in 1..<hostDoors.count{
                            position1 = CGPoint(x:wall.point1.x,y:hostDoors[i-1].point2.y)
                            position2 = CGPoint(x:wall.point2.x,y:hostDoors[i].point1.y)
                            obstacle = obstacleNode(position1: position1, position2: position2)
                            obstacleShapeNodes.append(obstacle)
                        }
                    }
                    position1 = CGPoint(x:wall.point1.x,y:hostDoors[hostDoors.count-1].point2.y)
                    position2 = wall.point2
                    obstacle = obstacleNode(position1: position1, position2: position2)
                    obstacleShapeNodes.append(obstacle)
                }
            }
            else{
                let obstacle = obstacleNode(position1: wall.point1, position2: wall.point2)
                obstacleShapeNodes.append(obstacle)
            }
        }
        obstacleShapeNodes.forEach{obstacle in
            obstacle.fillColor = UIColor.black
            obstacle.strokeColor = UIColor.black
        }
        columnList.forEach{column in
            let obstacle = obstacleNode(position1: column.point1, position2: column.point2)
            obstacle.fillColor = UIColor.blue
            obstacle.strokeColor = UIColor.blue
            obstacleShapeNodes.append(obstacle)
        }
        let polygonObstacles = SKNode.obstacles(fromNodeBounds: obstacleShapeNodes)
        graph = GKObstacleGraph(obstacles: polygonObstacles, bufferRadius: 0)
        print("built!")
        return obstacleShapeNodes
    }
    
    
    
    
    func obstacleNode(position1:CGPoint, position2:CGPoint) -> SKShapeNode{
        let width = fabs(position1.x - position2.x)
        let height = fabs(position1.y - position2.y)
        let rect = CGRect(x: position1.x, y: position1.y, width: width, height: height)
        let rectNode = SKShapeNode(rect: rect)
        return rectNode
    }
    
    func findPath(start: float2, planeY:Float, faceAngle:Double)->([CGPoint],[SCNNode])?{    //Gamekit算完之後才變成ar的路線,那個路徑只是座標(回傳一堆數字)
        print(start)
        if (start != nil){
            let startNode = connectedNode(point: start, graph: graph)
           // let endShapeNode = SKShapeNode(circleOfRadius: 0.5)   //看不出有什麼用
          //  endShapeNode.strokeColor = UIColor.red
            var pathNode = [GKGraphNode2D]()
            endElementList.forEach{EndElement in
                let end = float2(Float(EndElement.endPoint.x),Float(EndElement.endPoint.y))
              //  endShapeNode.position = CGPoint(x:EndElement.endPoint.x,y:EndElement.endPoint.y)
                let endNode = connectedNode(point: end, graph: graph)
                let newPathNode = graph.findPath(from: startNode!, to: endNode!) as! [GKGraphNode2D]  //apple內建的路徑套件
                if (pathNode.count != 0){
                    var distance:Float = 0
                    var newDistance:Float = 0
                    let pathPoint = pathNodesToPoints(pathNode: pathNode)
                    let newPathPoint = pathNodesToPoints(pathNode: newPathNode)
                    for i in 1..<pathPoint.count{
                        distance = distance+pathPoint[i-1].distanceTo(point: pathPoint[i])
                    }
                    for i in 1..<newPathPoint.count{
                        newDistance = newDistance+newPathPoint[i-1].distanceTo(point: newPathPoint[i])
                    }
                    if (newDistance<distance){
                        pathNode = newPathNode
                    }
                }
                else{
                    pathNode = newPathNode
                }
                graph.remove([endNode!])
            }
            
            graph.remove([startNode!])
            var pathRectNodes = [SCNNode()]
            pathRectNodes.remove(at: 0)
            if (pathNode.count<=2){
                print("no path")
                return ([],pathRectNodes)
            }
            else{
                let pathPointsFloat = pathNode.map{$0.position}
                var pathPoints = [CGPoint]()
                pathPointsFloat.forEach{point in
                    pathPoints.append(CGPoint(x:Double(point.x),y:Double(point.y)))
                }
                let yellow = SCNMaterial()             //路徑顏色
                yellow.diffuse.contents = UIColor.yellow
                yellow.transparency = 0.5              //透明度
                yellow.locksAmbientWithDiffuse = true
                var rotatedPathPoints = [CGPoint]()
                let faceTransform = CGAffineTransform.init(rotationAngle: northAngle+CGFloat(Float(faceAngle)*Float.pi/180))
                pathPoints.forEach{point in
                    rotatedPathPoints.append(point.applying(faceTransform))
                }
                for i in 1..<pathNode.count{
                    let pathRect = SCNPlane(width: 0.4, height: CGFloat(rotatedPathPoints[i-1].distanceTo(point: rotatedPathPoints[i]))*0.3048)
                    pathRect.materials = [yellow]
                    let pathRectNode = SCNNode(geometry:pathRect)
                    /*var cameratran = SCNMatrix4Identity
                     cameratran = SCNMatrix4Translate(cameratran, Float((pathPoints[i-1].x+pathPoints[i].x)/2)-start.x, 0.0, Float((pathPoints[i-1].y+pathPoints[i].y)/2)-start.y)
                     pathRectNode.transform = cameratran*/
                    let rotation = SCNMatrix4Mult(SCNMatrix4MakeRotation(-Float(Double.pi)/2.0, 1.0, 0.0, 0.0), SCNMatrix4MakeRotation(angleBetweenPoints(point1: rotatedPathPoints[i-1], point2: rotatedPathPoints[i])-Float(Double.pi)/2.0, 0.0, 1.0, 0.0))
                    pathRectNode.transform = rotation
                    let rotatedStart = CGPoint(x:Double((start.x)),y:Double((start.y))).applying(faceTransform)
                    let position = SCNVector3(x:-(Float((rotatedPathPoints[i-1].x+rotatedPathPoints[i].x)/2-rotatedStart.x)*0.3048),y:planeY,z:Float((rotatedPathPoints[i-1].y+rotatedPathPoints[i].y)/2-rotatedStart.y)*0.3048)
                    pathRectNode.position = position
                    pathRectNodes.append(pathRectNode)
                }
                return (pathPoints,pathRectNodes)
            }
        }
        else{
            print("fail to position")
            return nil
        }
    }
    
    func connectedNode(point:float2,graph:GKObstacleGraph<GKGraphNode2D>)->GKGraphNode?{
        let pointNode = GKGraphNode2D(point: point)
        graph.connectUsingObstacles(node: pointNode)  //加node
        if pointNode.connectedNodes.isEmpty {
            graph.remove([pointNode])
            print("failed to connected node")
            return nil
        }
        return pointNode
    }
    
    func angleBetweenPoints(point1:CGPoint,point2:CGPoint)->Float{
        return Float(atan2(point2.y-point1.y, point2.x-point1.x))
    }
    func pathNodesToPoints(pathNode:[GKGraphNode2D])->[CGPoint]{
        let pathPointsFloat = pathNode.map{$0.position}
        var pathPoints = [CGPoint]()
        pathPointsFloat.forEach{point in
            pathPoints.append(CGPoint(x:Double(point.x),y:Double(point.y)))
        }
        return pathPoints
    }
    
    
    
    //beacon
    func registerBeaconRegionWithUUID(uuidString: String, identifier: String)->CLBeaconRegion{
        let region = CLBeaconRegion(proximityUUID: UUID(uuidString: uuidString)!, identifier: identifier)
        region.notifyOnEntry = true //預設就是true
        region.notifyOnExit = true //預設就是true
        return region
    }
    func  startBeaconMonitoring(regions: [CLBeaconRegion], isMonitor: Bool, locationManager: CLLocationManager){
        if isMonitor{
            regions.forEach{region in
                locationManager.startMonitoring(for: region)//建立region後，開始monitor region
                print(region.proximityUUID)
                locationManager.startRangingBeacons(in: region)
            }
        }else{
            regions.forEach{region in
                locationManager.stopMonitoring(for: region)
                locationManager.stopRangingBeacons(in: region)
            }
   
        }
    }
    func positioning()->float2?{
        var newBeaconList = beaconList
        newBeaconList.sort(by: {$0.accuracy<$1.accuracy})
        for i in 0..<newBeaconList.count{
            if (newBeaconList[i].accuracy != 0){
                newBeaconList.removeSubrange(0..<i)
                break
            }
        }
        print(newBeaconList)
        if (newBeaconList[0].accuracy<(0.5/0.3048) || newBeaconList.count == 1){
            return float2(x:Float(newBeaconList[0].position.x),y:Float(newBeaconList[0].position.y))
        }
        else if (newBeaconList.count == 2){
            let i1 = intersectionOfTwoCircle(b1: newBeaconList[0], b2: newBeaconList[1])
            if (i1 != nil){
                let position = intersectionOfTwoLine(p1: i1![0], p2: i1![1], p3: newBeaconList[0].position, p4: newBeaconList[1].position)
                return float2(x:Float(position!.x),y:Float(position!.y))}
            else{
                return float2(x:Float(newBeaconList[0].position.x),y:Float(newBeaconList[0].position.y))
            }
        }
        else if (newBeaconList.count > 2){
            let i1 = intersectionOfTwoCircle(b1: newBeaconList[0], b2: newBeaconList[1])
            let i2 = intersectionOfTwoCircle(b1: newBeaconList[0], b2: newBeaconList[2])
            let i3 = intersectionOfTwoCircle(b1: newBeaconList[1], b2: newBeaconList[2])
            if (i1 != nil && i2 != nil && i3 != nil){
                let position = intersectionOfTwoLine(p1: i1![0], p2: i1![1], p3: i2![0], p4: i2![1])
                return float2(x:Float(position!.x),y:Float(position!.y))
            }
            else if (i1 != nil){
                let position = intersectionOfTwoLine(p1: i1![0], p2: i1![1], p3: newBeaconList[0].position, p4: newBeaconList[1].position)
                return float2(x:Float(position!.x),y:Float(position!.y))
            }
            else{
                return float2(x:Float(newBeaconList[0].position.x),y:Float(newBeaconList[0].position.y))
            }
        }
        return nil
    }
}
extension CGPoint{
    func distanceTo(point:CGPoint)->Float{
        return Float(hypot(self.x - point.x, self.y - point.y))
    }
}
precedencegroup HighPrecedence { higherThan: BitwiseShiftPrecedence }
infix operator **: HighPrecedence
extension CGFloat {
    public static func **(base: CGFloat, exp: CGFloat) -> CGFloat {
        return CGFloat(pow(Double(base), Double(exp)))
    }
    public static var pi = CGFloat(Double.pi)
    public static var tau = CGFloat(Double.pi * 2.0)
}

