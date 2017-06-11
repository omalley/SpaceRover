//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {

  var playerShip: SpaceShip?
  var tileMap:SKTileMapNode?
  var arrows = [DirectionArrow?](repeating: nil, count: 7)
  
  func findTileMap() -> SKTileMapNode? {
    for child in children {
      if child.name == "Tile Map Node" {
        return (child as! SKTileMapNode)
      }
    }
    return nil
  }
  
  func convertTileCoord(slanted: CGPoint) -> CGPoint {
    let staggered = slanted
    return staggered
  }
  
  override func didMove(to view: SKView) {
    /* Setup your scene here */
    let tileMap = findTileMap()
    playerShip = SpaceShip(map: tileMap!, x:36, y:25)
    playerShip?.accelerateShip(direction: HexDirection.NorthWest)
    for direction in HexDirection.all() {
      arrows[direction.rawValue] = DirectionArrow(direction: direction)
      tileMap?.addChild(arrows[direction.rawValue]!)
      arrows[direction.rawValue]!.position = playerShip!.getAccellerationPosition(direction: direction)
    }
  }

  let PAN_SLOWDOWN: CGFloat = 20.0
  
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN, y: velocity.y/PAN_SLOWDOWN, duration: 0.5))
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      playerShip?.move()
    }
  }
   
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
  }
}
