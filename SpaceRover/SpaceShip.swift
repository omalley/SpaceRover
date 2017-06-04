//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

class SpaceShip {
  let sprite = SKSpriteNode(imageNamed:"SpaceshipUpRight")
  let tileMap: SKTileMapNode
  
  var x: Int
  var y: Int
  var velocityX: Int
  var velocityY: Int
  
  init (map: SKTileMapNode, x: Int, y: Int) {
    tileMap = map
    self.x = x
    self.y = y
    velocityX = 0
    velocityY = 0
    sprite.position = tileMap.centerOfTile(atColumn: x, row: y)
    tileMap.addChild(sprite)
  }
}
