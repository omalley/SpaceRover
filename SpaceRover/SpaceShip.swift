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

  func invert() -> HexDirection {
    switch (self) {
    case .NoAcc:
      return .NoAcc
    case .NorthEast:
      return .SouthWest
    case .NorthWest:
      return .SouthEast
    case .West:
      return .East
    case .East:
      return .West
    case .SouthWest:
      return .NorthEast
    case .SouthEast:
      return .NorthWest
    }
  }
}

struct SlantPoint {
  var x: Int
  var y: Int
}

func rotateAngle(_ direction: HexDirection) -> CGFloat? {
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

func slantToView(_ pos: SlantPoint, tiles: SKTileMapNode) -> CGPoint {
  return tiles.centerOfTile(atColumn: pos.x - ((pos.y+1) / 2), row: pos.y)
}

/**
 * Compute the relative position in the given direction.
 */
func findRelativePosition(_ direction: HexDirection, tiles: SKTileMapNode) -> CGPoint {
  // pick a point that won't cause the relative points to go out of bounds
  let originSlant = SlantPoint(x: 2, y: 2)
  // get the relative slant point
  let slant = computeNewVelocity(direction: direction, velocity: originSlant)
  let posn = slantToView(slant, tiles: tiles)
  // subtract off the origin
  let origin = slantToView(originSlant, tiles: tiles)
  return CGPoint(x: posn.x - origin.x, y: posn.y - origin.y)
}

let shipCollisionMask: UInt32 = 1
let planetCollisionMask: UInt32 = 2

class SpaceShip: SKSpriteNode {

  let tileMap: SKTileMapNode
  var arrows = [DirectionArrow?](repeating: nil, count: 7)

  var slant: SlantPoint
  var velocity: SlantPoint

  init (name: String, slant: SlantPoint, tiles: SKTileMapNode) {
    tileMap = tiles
    self.slant = slant
    velocity = SlantPoint(x: 0, y: 0)
    let texture = SKTexture(imageNamed: "SpaceshipUpRight")
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    self.name = name
    position = slantToView(slant, tiles: tileMap)
    tileMap.addChild(self)
    for direction in HexDirection.all() {
      arrows[direction.rawValue] = DirectionArrow(ship: self, direction: direction)
      tileMap.addChild(arrows[direction.rawValue]!)
      arrows[direction.rawValue]!.position = self.getAccellerationPosition(direction: direction)
    }
    zPosition = 20
    physicsBody = SKPhysicsBody(circleOfRadius: 1)
    physicsBody?.categoryBitMask = shipCollisionMask
    physicsBody?.contactTestBitMask = planetCollisionMask
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func getAccellerationPosition(direction: HexDirection) -> CGPoint {
    let newVelocity = computeNewVelocity(direction: direction, velocity: velocity)
    let newPositionX = newVelocity.x + slant.x
    let newPositionY = newVelocity.y + slant.y
    return slantToView(SlantPoint(x: newPositionX, y: newPositionY), tiles: tileMap)
  }

  func accelerateShip(direction: HexDirection) {
    velocity = computeNewVelocity(direction: direction, velocity: velocity)
    self.moveAccArrows()
  }

  func rotateShip (_ direction: HexDirection) {
    if let angle = rotateAngle(direction) {
      self.run(SKAction.rotate(toAngle: angle, duration: 0.5))
    }
  }

  func moveAccArrows(){
    for direction in HexDirection.all() {
      arrows[direction.rawValue]?.run(
        SKAction.move(to: getAccellerationPosition(direction: direction), duration: 1))
    }
  }

  func move() {
    if (velocity.x == 0 && velocity.y == 0){
      if let list = physicsBody?.allContactedBodies() {
        for body in list {
          if let node = body.node as? GravityArrow {
            accelerateShip(direction: node.direction)
          }
        }
      }
    } else {
      slant.x += velocity.x
      slant.y += velocity.y
      run(SKAction.move(to: slantToView(slant, tiles: tileMap), duration: 1))
      self.moveAccArrows()
    }
  }
}

class Planet: SKSpriteNode{

  init(name: String, slant: SlantPoint, tiles: SKTileMapNode) {
    let texture = SKTexture(imageNamed: name)
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    self.name = name
    position = slantToView(slant, tiles: tiles)
    zPosition = 10
    for direction in HexDirection.all() {
      if direction != HexDirection.NoAcc {
        let posn = findRelativePosition(direction.invert(), tiles: tiles)
        addChild(GravityArrow(direction: direction, planet: self, position: posn))
      }
    }
    physicsBody = SKPhysicsBody(circleOfRadius: 50)
    physicsBody?.categoryBitMask = planetCollisionMask
    physicsBody?.contactTestBitMask = shipCollisionMask
    physicsBody?.isDynamic = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class GravityArrow: SKSpriteNode {
  let direction: HexDirection

  init(direction: HexDirection, planet: Planet, position: CGPoint) {
    self.direction = direction
    let texture = SKTexture(imageNamed: "GravityArrow")
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    self.name = "Gravity \(direction) toward \(planet.name!)"
    zPosition = 10
    alpha = 0.6
    self.position = position
    let sixtyDegree = CGFloat(Double.pi) / 3
    run(SKAction.rotate(byAngle: sixtyDegree + rotateAngle(direction)!, duration: 0))
    physicsBody = SKPhysicsBody(circleOfRadius: 50)
    physicsBody?.categoryBitMask = planetCollisionMask
    physicsBody?.contactTestBitMask = shipCollisionMask
    physicsBody?.isDynamic = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
      super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    } else {
      let texture = SKTexture(imageNamed: "MovementArrow")
      super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    }
    alpha = 0.4
    zPosition = 30

    if let angle = rotateAngle(direction) {
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
      ship.rotateShip(direction)
      ship.move()
    }
  }
}
