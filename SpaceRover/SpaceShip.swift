//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum HexDirection {
  case NorthEast, East, SouthEast, SouthWest, West, NorthWest;
}

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
    setPosition(x: x, y: y)
    tileMap.addChild(sprite)
  }
  
  func setPosition(x: Int, y: Int) {
    sprite.position = tileMap.centerOfTile(atColumn: x - ((y+1) / 2), row: y)
  }
  
  func accellerate(direction: HexDirection) {
    switch (direction) {
    case .NorthEast:
      velocityX += 1
      velocityY += 1
      sprite.run(SKAction.rotate(byAngle: 0, duration: 0))
    case .East:
      velocityX += 1
      sprite.run(SKAction.rotate(byAngle: (CGFloat(Double.pi)/3)*1, duration: 0))
    case .SouthEast:
      velocityY += -1
      sprite.run(SKAction.rotate(byAngle: (CGFloat(Double.pi)/3)*2, duration: 0))
    case .SouthWest:
      velocityX += -1
      velocityY += -1
      sprite.run(SKAction.rotate(byAngle: (CGFloat(Double.pi)/3)*3, duration: 0))
    case .West:
      velocityX += -1
      sprite.run(SKAction.rotate(byAngle: (CGFloat(Double.pi)/3)*4, duration: 0))
    case .NorthWest:
      velocityY += 1
      sprite.run(SKAction.rotate(byAngle: (CGFloat(Double.pi)/3)*5, duration: 0))
    }
  }
  
  func move() {
    x += velocityX
    y += velocityY
    setPosition(x: x, y: y)
  }
}
