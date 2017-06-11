//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum HexDirection {
  case NoAcc, NorthEast, East, SouthEast, SouthWest, West, NorthWest;
}

struct SlantPoint {
  var x: Int
  var y: Int
}

class SpaceShip {
  let sprite = SKSpriteNode(imageNamed:"SpaceshipUpRight")
  let tileMap: SKTileMapNode
  
  var position: SlantPoint
  var velocity: SlantPoint
  
  init (map: SKTileMapNode, x: Int, y: Int) {
    tileMap = map
    position = SlantPoint(x: x, y: y)
    velocity = SlantPoint(x: 0, y: 0)
    self.sprite.position = slantToView(position)
    tileMap.addChild(sprite)
  }
  
  func slantToView(_ pos: SlantPoint) -> CGPoint {
    return tileMap.centerOfTile(atColumn: pos.x - ((pos.y+1) / 2), row: pos.y)
  }
  
  func getCurrentPosition() -> CGPoint {
    return slantToView(position)
  }
  
  func getAccellerationPosition(direction: HexDirection) -> CGPoint {
    let newVelocity = computeNewVelocity(direction: direction, velocity: velocity)
    let newPositionX = newVelocity.x + position.x
    let newPositionY = newVelocity.y + position.y
    return slantToView(SlantPoint(x: newPositionX, y: newPositionY))
  }

  /**
   * Update velocity by accelation in the given direction
   */
  func computeNewVelocity(direction: HexDirection, velocity: SlantPoint) -> SlantPoint {
    var result = velocity
    switch (direction) {
    case .NoAcc:
      break
    case .NorthEast:
      result.x += 1
      result.y += 1
    case .East:
      result.x += 1
    case .SouthEast:
      result.y += -1
    case .SouthWest:
      result.x += -1
      result.y += -1
    case .West:
      result.x += -1
    case .NorthWest:
      result.y += 1
    }
    return result
  }
  
  func rotateAngle(direction: HexDirection) -> CGFloat? {
    switch (direction) {
    case .NoAcc:
      return nil
    case .NorthEast:
      return 0
    case .East:
      return (CGFloat(Double.pi)/3)*1
    case .SouthEast:
      return (CGFloat(Double.pi)/3)*2
    case .SouthWest:
      return (CGFloat(Double.pi)/3)*3
    case .West:
      return (CGFloat(Double.pi)/3)*4
    case .NorthWest:
      return (CGFloat(Double.pi)/3)*5
    }
  }
  
  func accelerateShip(direction: HexDirection) {
    velocity = computeNewVelocity(direction: direction, velocity: velocity)
    if let angle = rotateAngle(direction: direction) {
      sprite.run(SKAction.rotate(byAngle: angle, duration: 0))
    }
  }
  
  func move() {
    position.x += velocity.x
    position.y += velocity.y
    sprite.position = slantToView(position)
  }
}
