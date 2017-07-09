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

  func rotateAngle() -> Double {
    switch (self) {
    case .NoAcc:
      return 0
    case .NorthEast:
      return 0
    case .East:
      return 5*Double.pi/3
    case .SouthEast:
      return 4*Double.pi/3
    case .SouthWest:
      return 3*Double.pi/3
    case .West:
      return 2*Double.pi/3
    case .NorthWest:
      return 1*Double.pi/3
    }
  }
}

struct SlantPoint {
  var x: Int
  var y: Int
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
  //Sing us a song, you're the piano man! Sing us a song, tonight! Cuz we're all in the mood for a melody, an you've got us feeling alright!
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
let gravityCollisionMask: UInt32 = 3

protocol ShipInformationWatcher {
  func updateShipInformation(_ msg: String)
}

class SpaceShip: SKSpriteNode {

  let tileMap: SKTileMapNode
  let fuelCapacity = 20
  var arrows : DirectionArrow?

  var slant: SlantPoint
  var velocity: SlantPoint
  var direction = HexDirection.NorthEast
  var fuel: Int
  var watcher: ShipInformationWatcher?
  
  init (name: String, slant: SlantPoint, tiles: SKTileMapNode) {
    tileMap = tiles
    self.slant = slant
    velocity = SlantPoint(x: 0, y: 0)
    let texture = SKTexture(imageNamed: "SpaceshipUpRight")
    fuel = fuelCapacity
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    self.name = name
    position = slantToView(slant, tiles: tileMap)
    tileMap.addChild(self)
    arrows = DirectionArrow(ship: self)
    arrows!.position = self.position
    tileMap.addChild(arrows!)
    zPosition = 20
    physicsBody = SKPhysicsBody(circleOfRadius: 5)
    physicsBody?.categoryBitMask = shipCollisionMask
    physicsBody?.contactTestBitMask = planetCollisionMask | gravityCollisionMask
    physicsBody?.collisionBitMask = 0
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setWatcher(_ newWatcher: ShipInformationWatcher?) {
    watcher = newWatcher
    watcher?.updateShipInformation(getInformation())
  }
  
  func getAccellerationPosition(direction: HexDirection) -> CGPoint {
    let newVelocity = computeNewVelocity(direction: direction, velocity: velocity)
    let newPositionX = newVelocity.x + slant.x
    let newPositionY = newVelocity.y + slant.y
    return slantToView(SlantPoint(x: newPositionX, y: newPositionY), tiles: tileMap)
  }

  func enterGravity(_ gravity: GravityArrow) {
    print("\(self.name!) hit \(gravity.name!)")
    accelerateShip(direction: gravity.direction)
  }

  func accelerateShip(direction: HexDirection) {
    velocity = computeNewVelocity(direction: direction, velocity: velocity)
    moveAccArrows()
  }

  func rotateShip (_ newDirection : HexDirection) {
    if newDirection != direction && newDirection != HexDirection.NoAcc {
      var rotateBy = (newDirection.rotateAngle() - direction.rotateAngle())
      if (rotateBy >= 0) {
        while (rotateBy > Double.pi) {
          rotateBy -= 2*Double.pi
        }
      } else {
        while (rotateBy < -Double.pi) {
          rotateBy += 2*Double.pi
        }
      }
      direction = newDirection
      self.run(SKAction.rotate(byAngle: CGFloat(rotateBy), duration: 0.5))
    }
  }

  func getInformation() -> String {
    return "\(name!)\nFuel: \(fuel)"
  }
  
  func useFuel(_ units: Int) {
    fuel -= units
    watcher?.updateShipInformation(getInformation())
    if (fuel == 0) {
      arrows?.hideAcceleration()
      //"We're outta rockets sir."
    }
  }
  
  func moveAccArrows(){
    arrows?.removeAllActions()
    arrows?.run(
        SKAction.move(to: getAccellerationPosition(direction: HexDirection.NoAcc), duration: 1))
  }
  
  func move() {
    print("moving \(name!) by \(velocity)")
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
      //vroom vroom
    }
  }
}

class Planet: SKSpriteNode{

  convenience init(name: String, slant: SlantPoint, tiles: SKTileMapNode) {
    self.init(name:name, image:name, slant:slant, tiles:tiles)
  }
  
  init(name: String, image: String, slant: SlantPoint, tiles: SKTileMapNode) {
    let texture = SKTexture(imageNamed: image)
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    let nameLabel = SKLabelNode(text: name)
    nameLabel.zPosition = 1
    nameLabel.position = CGPoint(x: 0, y: 25)
    nameLabel.fontSize = 20
    nameLabel.fontName = "Copperplate"
    addChild(nameLabel)
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
    physicsBody?.collisionBitMask = 0
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
    // Create the hexagon with the additional wedge toward the planet
    let bodyShape = CGMutablePath()
    bodyShape.addLines(between: [CGPoint(x:111, y:0),
                                 CGPoint(x:0, y:-64),
                                 CGPoint(x:-55, y:-32),
                                 CGPoint(x:-55, y:32),
                                 CGPoint(x:0, y:64),
                                 CGPoint(x:111, y:0)])
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    self.name = "Gravity \(direction) toward \(planet.name!)"
    zPosition = 10
    alpha = 0.6
    self.position = position
    physicsBody = SKPhysicsBody(polygonFrom: bodyShape)
    physicsBody?.categoryBitMask = gravityCollisionMask
    physicsBody?.contactTestBitMask = shipCollisionMask
    physicsBody?.collisionBitMask = 0
    physicsBody?.isDynamic = false
    let sixtyDegree = Double.pi / 3
    run(SKAction.rotate(byAngle: CGFloat(sixtyDegree + direction.rotateAngle()), duration: 0))
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

/**
 * The arrows that let the user pick the direction.
 */
class DirectionArrow: SKSpriteNode{
  let direction: HexDirection
  let ship: SpaceShip
  
  /**
   * Constructor for the parent arrow
   */
  init(ship: SpaceShip) {
    self.ship = ship
    self.direction = HexDirection.NoAcc
    let texture = SKTexture(imageNamed: "NoAccelerationSymbol")
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    name = "\(direction) arrow for \(ship.name!)"
    alpha = 0.4
    zPosition = 30
    isUserInteractionEnabled = true
    for childDir in HexDirection.all() {
      if (childDir != HexDirection.NoAcc) {
        addChild(DirectionArrow(ship: ship, direction: childDir))
      }
    }
  }
  
  /**
   * Constructor for the children arrows
   */
  init(ship: SpaceShip, direction: HexDirection) {
    self.ship = ship
    self.direction = direction

    let texture = SKTexture(imageNamed: "MovementArrow")
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    name = "\(direction) arrow for \(ship.name!)"

    self.run(SKAction.rotate(toAngle: CGFloat(direction.rotateAngle()), duration: 0))
    isUserInteractionEnabled = true
    position = findRelativePosition(direction, tiles: ship.tileMap)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func hideAcceleration() {
    for child in children {
      child.isHidden = true
    }
  }
  
  func unhideAcceleration() {
    for child in children {
      child.isHidden = false
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      if (direction != HexDirection.NoAcc) {
        ship.accelerateShip(direction: direction)
        ship.useFuel(1)
        ship.rotateShip(direction)
      }
      ship.move()
    }
  }
}
