//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum HexDirection: Int {
  case NoAcc, NorthEast, East, SouthEast, SouthWest, West, NorthWest;
}

extension HexDirection {
  static func all() -> AnySequence<HexDirection> {
    return AnySequence {
      return HexDirectionGenerator()
    }
  }
  
  struct HexDirectionGenerator: IteratorProtocol {
    var currentSection = 0
    
    mutating func next() -> HexDirection? {
      guard let item = HexDirection(rawValue:currentSection) else {
        return nil
      }
      currentSection += 1
      return item
    }
  }
  
}

struct SlantPoint {
  var x: Int
  var y: Int
}

func rotateAngle(direction: HexDirection) -> CGFloat? {
  switch (direction) {
  case .NoAcc:
    return nil
  case .NorthEast:
    return 0
  case .East:
    return (CGFloat(Double.pi)/3)*5
  case .SouthEast:
    return (CGFloat(Double.pi)/3)*4
  case .SouthWest:
    return (CGFloat(Double.pi)/3)*3
  case .West:
    return (CGFloat(Double.pi)/3)*2
  case .NorthWest:
    return (CGFloat(Double.pi)/3)*1
  }
}

class SpaceShip: SKSpriteNode {

  let tileMap: SKTileMapNode
  var arrows = [DirectionArrow?](repeating: nil, count: 7)
  
  var slant: SlantPoint
  var velocity: SlantPoint
  
  init (map: SKTileMapNode, x: Int, y: Int) {
    tileMap = map
    slant = SlantPoint(x: x, y: y)
    velocity = SlantPoint(x: 0, y: 0)
    let texture = SKTexture(imageNamed: "SpaceshipUpRight")
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    position = slantToView(slant)
    tileMap.addChild(self)
    for direction in HexDirection.all() {
      arrows[direction.rawValue] = DirectionArrow(ship: self, direction: direction)
      tileMap.addChild(arrows[direction.rawValue]!)
      arrows[direction.rawValue]!.position = self.getAccellerationPosition(direction: direction)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func slantToView(_ pos: SlantPoint) -> CGPoint {
    return tileMap.centerOfTile(atColumn: pos.x - ((pos.y+1) / 2), row: pos.y)
  }
  
  func getAccellerationPosition(direction: HexDirection) -> CGPoint {
    let newVelocity = computeNewVelocity(direction: direction, velocity: velocity)
    let newPositionX = newVelocity.x + slant.x
    let newPositionY = newVelocity.y + slant.y
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
  
  func accelerateShip(direction: HexDirection) {
    velocity = computeNewVelocity(direction: direction, velocity: velocity)
    if let angle = rotateAngle(direction: direction) {
      self.run(SKAction.rotate(toAngle: angle, duration: 0))
    }
    move()
  }
  
  func move() {
    slant.x += velocity.x
    slant.y += velocity.y
    position = slantToView(slant)
    for direction in HexDirection.all() {
      arrows[direction.rawValue]!.position = self.getAccellerationPosition(direction: direction)
    }
  }
}

class DirectionArrow: SKSpriteNode{
  let direction: HexDirection
  let ship: SpaceShip
  init(ship: SpaceShip, direction: HexDirection) {
    self.ship = ship
    self.direction = direction
    
    //Change NoAcc to the NoAcceleration with if statement. Unsure of how it works. Please help. Also needs wrapping.
     
    if (direction == HexDirection.NoAcc) {
      let texture = SKTexture(imageNamed: "NoAccelerationSymbol")
    }
    else{
      let texture = SKTexture(imageNamed: "MovementArrow")
    }
    
    //end changes
    
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    if let angle = rotateAngle(direction: direction) {
      self.run(SKAction.rotate(toAngle: angle, duration: 0))
    }
    isUserInteractionEnabled = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      ship.accelerateShip(direction: direction)
    }
  }
}
