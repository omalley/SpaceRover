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
  
  func findTileMap() -> SKTileMapNode? {
    for child in children {
      if child.name == "Tile Map" {
        return (child as! SKTileMapNode)
      }
    }
    return nil
  }
  
  override func didMove(to view: SKView) {
    /* Setup your scene here */
    let tileMap = findTileMap()
    tileMap?.isUserInteractionEnabled = true
    playerShip = SpaceShip(map: tileMap!, x:36, y:25)
  }

  let PAN_SLOWDOWN: CGFloat = 20.0
  
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN, y: velocity.y/PAN_SLOWDOWN, duration: 0.5))
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      print("outside touch")
    }
  }
   
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
  }
}
