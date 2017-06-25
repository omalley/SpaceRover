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
  
  override func didMove(to view: SKView) {
    /* Setup your scene here */
    for child in children {
      if child.name == "Tile Map" {
        tileMap = (child as! SKTileMapNode)
      }
    }
    tileMap?.isUserInteractionEnabled = true
    playerShip = SpaceShip(map: tileMap!, x:50, y:30)
  }

  let PAN_SLOWDOWN: CGFloat = 20.0
  
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN, y: velocity.y/PAN_SLOWDOWN, duration: 0.5))
  }

  func doPinch(_ velocity: CGFloat) {
    let newScale = camera!.xScale - velocity
    if (newScale > 1.5 && newScale < 6) {
      camera?.run(SKAction.scale(to: newScale, duration: 0.5))
      print("Scaling by \(velocity) to \(newScale)")
    }
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
