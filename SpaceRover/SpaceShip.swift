//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum SpaceshipColor: Int {
  case blue,red,green,purple,orange,yellow;
}

extension SpaceshipColor {

  static func count() -> Int {
    return SpaceshipColor.yellow.rawValue + 1
  }

  func image() -> SKTexture {
    switch (self) {
    case .blue:
      return SKTexture(imageNamed: "SpaceshipUpRight")
    case .red:
      return SKTexture(imageNamed: "SpaceshipRed")
    case .green:
      return SKTexture(imageNamed: "SpaceshipGreen")
    case .purple:
      return SKTexture(imageNamed: "SpaceshipPurple")
    case .orange:
      return SKTexture(imageNamed: "SpaceshipOrange")
    case .yellow:
      return SKTexture(imageNamed: "SpaceshipYellow")
    }
  }

  func toString() -> String {
    switch self {
    case .blue:
      return "Blue"
    case .red:
      return "Red"
    case .green:
      return "Green"
    case .purple:
      return "Purple"
    case .orange:
      return "Orange"
    case .yellow:
      return "Yellow"
    }
  }
}

let shipContactMask: UInt32 = 1
let planetContactMask: UInt32 = 2
let gravityContactMask: UInt32 = 4
let accelerationContactMask: UInt32 = 8
let asteroidsContactMask: UInt32 = 16

protocol ShipInformationWatcher {
  func getTurnState() -> TurnState
  func updateShipInformation(_ msg: String)
  func crash(ship:SpaceShip)
  func startTurn(player: String)
  func shipMoving(ship: SpaceShip)
  func shipDoneMoving(ship: SpaceShip)
  func endGame(_ : GameScene)
}

let UiFontName = "Copperplate"

/**
 * Roll a six sided die.
 * Returns 1 to 6 inclusive
 */
func rollDie() -> Int {
  return 1 + Int(arc4random_uniform(6))
}

class SpaceShip: SKSpriteNode {

  let tileMap: SKTileMapNode
  let player: PlayerInfo
  let fuelCapacity = 20
  let turnIndicator: SKSpriteNode
  var arrows : DirectionKeypad?

  var slant: SlantPoint
  var velocity: SlantPoint
  var direction = HexDirection.NorthEast
  var fuel: Int
  var watcher: ShipInformationWatcher?
  var orbitAround: Planet?
  var hasLanded = false
  var isDead = false
  var turnsDisabled = 0
  var deathReason: String?

  convenience init(name: String, on: Planet, tiles: SKTileMapNode, color: SpaceshipColor,
                   player: PlayerInfo) {
    self.init(name: name, slant: on.slant, tiles: tiles, color: color, player: player)
    orbitAround = on
    hasLanded = true
    arrows?.setLaunchButtons(planet: on)
  }

  init (name: String, slant: SlantPoint, tiles: SKTileMapNode, color: SpaceshipColor,
        player: PlayerInfo) {
    tileMap = tiles
    self.slant = slant
    self.player = player
    velocity = SlantPoint(x: 0, y: 0)
    let texture = color.image()
    fuel = fuelCapacity
    let turnIndicatorTexture = SKTexture(imageNamed: "CurrentTurnIndicator")
    turnIndicator = SKSpriteNode(texture: turnIndicatorTexture)
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    self.name = name
    position = slantToView(slant, tiles: tileMap)
    tileMap.addChild(self)
    arrows = DirectionKeypad(ship: self)
    arrows!.position = self.position
    arrows!.isHidden = true
    tileMap.addChild(arrows!)
    self.addChild(turnIndicator)
    zPosition = 20
    physicsBody = SKPhysicsBody(circleOfRadius: 5)
    physicsBody?.categoryBitMask = shipContactMask
    physicsBody?.contactTestBitMask = planetContactMask | gravityContactMask | asteroidsContactMask
    physicsBody?.collisionBitMask = 0
    arrows?.detectOverlap()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setWatcher(_ newWatcher: ShipInformationWatcher?) {
    watcher = newWatcher
    watcher?.updateShipInformation(getInformation())
  }

  func getAccellerationPosition(direction: HexDirection) -> CGPoint {
    let newVelocity = velocity + direction.toSlant()
    let newPosition = slant + newVelocity
    return slantToView(newPosition, tiles: tileMap)
  }

  func enterGravity(_ gravity: GravityArrow) {
    if (!hasLanded) {
      print("\(self.name!) hit \(gravity.name!)")
      accelerateShip(direction: gravity.direction)
    }
  }

  func accelerateShip(direction: HexDirection) {
    velocity = velocity + direction.toSlant()
    moveAccArrows()
  }

  func calculateOrbit() {
    for body in physicsBody!.allContactedBodies() {
      if let gravity = body.node as? GravityArrow {
        // Is the velocity 60 degrees from the gravity?
        let clockwise = gravity.direction.clockwise(turns: 1).toSlant()
        let counterClockwise = gravity.direction.clockwise(turns: -1).toSlant()
        if velocity == clockwise || velocity == counterClockwise {
          orbitAround = gravity.planet
          return
        }
      }
    }
    orbitAround = nil
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
    if let planet = orbitAround {
      if hasLanded {
        return "\(name!)\nFuel: \(fuel)\nOn \(planet.name!)"
      } else {
        return "\(name!)\nFuel: \(fuel)\n\(planet.name!) orbit"
      }
    } else if turnsDisabled != 0 {
      return "\(name!)\nFuel: \(fuel)\nDisabled: \(turnsDisabled)"
    } else {
      return "\(name!)\nFuel: \(fuel)\nSpeed: \(computeDistance(velocity))"
    }
  }

  func useFuel(_ units: Int) {
    fuel -= units
    calculateOrbit()
    if (fuel == 0) {
      arrows?.disable()
      //"We're outta gas sir."
    }
  }

  func moveAccArrows(){
    arrows?.removeAllActions()
    arrows?.run(
        SKAction.move(to: getAccellerationPosition(direction: HexDirection.NoAcc), duration: 1))
  }

  func move() {
    print("moving \(name!) by \(velocity)")
    if !hasLanded {
      arrows?.removeLandingButtons()
      watcher?.shipMoving(ship: self)
      slant = slant + velocity
      run(SKAction.move(to: slantToView(slant, tiles: tileMap), duration: 1))
      // if the player tries to hover over a planet, the gravity needs to pull them again
      if velocity.x == 0 && velocity.y == 0 {
        for body in physicsBody!.allContactedBodies() {
          if let gravity = body.node as? GravityArrow {
            velocity = gravity.direction.toSlant()
          }
        }
      }
      self.moveAccArrows()
      //vroom vroom
    }
  }

  func startTurn() {
    print("start turn for \(name!)")
    arrows?.isHidden = false
    turnIndicator.isHidden = false
    watcher?.updateShipInformation(getInformation())
  }

  func endTurn() {
    watcher?.shipDoneMoving(ship: self)
    if !hasLanded {
      arrows?.detectOverlap()
    }
    arrows?.isHidden = true
    turnIndicator.isHidden = true
    if (turnsDisabled > 0) {
      turnsDisabled -= 1
      if(turnsDisabled == 0) {
        arrows?.reenable()
      }
    }
    print("end turn for \(name!)")
  }
  
  func landOn(planet: Planet) {
    print("Land \(name!) on \(planet.name!)")
    hasLanded = true
    fuel = fuelCapacity
    slant = planet.slant
    position = planet.position
    velocity = SlantPoint(x: 0, y: 0)
    arrows?.removeLandingButtons()
    watcher?.updateShipInformation(getInformation())
    moveAccArrows()
    arrows?.setLaunchButtons(planet: planet)
    watcher?.shipMoving(ship: self)
  }

  func launch(planet: Planet, direction: HexDirection) {
    print("Launching \(name!) from \(planet.name!)")
    hasLanded = false
    orbitAround = nil
    slant = slant + direction.toSlant()
    velocity = direction.invert().toSlant()
    position = slantToView(slant, tiles: tileMap)
    arrows?.removeLandingButtons()
    arrows?.position = slantToView(slant + velocity, tiles: tileMap)
    arrows?.detectOverlap()
    watcher?.shipMoving(ship: self)
  }
  
  func crash(reason: String) {
    isDead = true
    isHidden = true
    arrows?.isHidden = true
    deathReason = reason
    watcher?.crash(ship: self)
  }

  /**
   * Disable the ship for a given number of turns.
   */
  func disable(turns: Int)  {
    print("Disabled for \(turns) turns")
    if turnsDisabled == 0 {
      arrows?.disable()
      turnsDisabled = 1
    }
    turnsDisabled += turns
    if turnsDisabled == 6 {
      self.crash(reason: " Your ship,  \(name!), burned up in the Asteroid Fields!")
    }
  }

  func enterAsteroids(_ asteroid: Asteroid) {
    if computeDistance(velocity) > 1 {
      print("\(name!) entered \(asteroid.name!)")
      let die = rollDie()
      print("Rolled a \(die)")
      switch die {
      case 5:
        disable(turns: 1)
      case 6:
        disable(turns: 2)
      default:
        break
      }
    }
  }
}

class DirectionKeypad: SKNode {
  var isDisabled = false

  init(ship: SpaceShip) {
    super.init()
    name = "DirectionKeypad for \(ship.name!)"
    alpha = 1
    zPosition = 50
    isUserInteractionEnabled = true
    for childDir in HexDirection.all() {
      addChild(DirectionArrow(ship: ship, direction: childDir))
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func disable() {
    isDisabled = true
    for child in children {
      if let arrow = child as? DirectionArrow {
        if arrow.direction != .NoAcc {
          arrow.isHidden = true
        }
      }
    }
  }

  func reenable() {
    isDisabled = false
    for child in children {
      if let arrow = child as? DirectionArrow {
        if arrow.direction != .NoAcc {
          arrow.isHidden = false
        }
      }
    }
  }
  
  func detectOverlap() {
    if !isDisabled {
      for child in children {
        if let arrow = child as? DirectionArrow {
          arrow.detectOverlap()
        }
      }
    }
  }

  func removeLandingButtons() {
    for child in children {
      if let button = child as? MovementButton {
        button.removeSelf()
      }
    }
  }

  func setLaunchButtons(planet: Planet) {
    for child in children {
      if let arrow = child as? DirectionArrow {
        if arrow.direction != .NoAcc {
          addChild(LaunchButton(arrow: arrow, planet: planet))
        }
      }
    }
  }
}

/**
 * The arrows that let the user pick the direction.
 */
class DirectionArrow: SKSpriteNode{
  let direction: HexDirection
  let ship: SpaceShip

  /**
   * Constructor for the children arrows
   */
  init(ship: SpaceShip, direction: HexDirection) {
    self.ship = ship
    self.direction = direction
    if (direction == HexDirection.NoAcc) {
      let texture = SKTexture(imageNamed: "NoAccelerationSymbol")
      super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    } else {
      let texture = SKTexture(imageNamed: "MovementArrow")
      super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    }
    name = "\(direction) arrow for \(ship.name!)"
    alpha = 0.4

    self.run(SKAction.rotate(toAngle: CGFloat(direction.rotateAngle()), duration: 0))
    isUserInteractionEnabled = true
    position = findRelativePosition(direction, tiles: ship.tileMap)
    physicsBody = createPhysics()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func createPhysics() -> SKPhysicsBody {
    let newPhysicsBody = SKPhysicsBody(circleOfRadius: 10)
    newPhysicsBody.categoryBitMask = accelerationContactMask
    newPhysicsBody.contactTestBitMask = planetContactMask
    newPhysicsBody.collisionBitMask = 0
    newPhysicsBody.isDynamic = true
    return newPhysicsBody
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      if (ship.watcher!.getTurnState() == TurnState.WAITING_FOR_DIRECTION) {
        if (direction != HexDirection.NoAcc) {
          ship.accelerateShip(direction: direction)
          ship.useFuel(1)
          ship.rotateShip(direction)
        }
        ship.move()
      }
    }
  }

  func detectOverlap() {
    if let dirKeypad = parent as? DirectionKeypad {
      for body in physicsBody!.allContactedBodies() {
        if let planet = body.node as? Planet {
          if ship.orbitAround == planet && planet.isLandable {
            dirKeypad.addChild(LandButton(arrow: self, planet: planet))
          } else {
            dirKeypad.addChild(CrashButton(arrow: self, planet: planet))
          }
        }
      }
    }
  }
}

class MovementButton: SKLabelNode {
  let arrow: DirectionArrow
  let planet: Planet
  
  init(msg: String, color: UIColor, arrow: DirectionArrow, planet: Planet) {
    self.arrow = arrow
    self.planet = planet
    super.init()
    text = msg
    fontName = UiFontName
    fontSize = 20
    fontColor = color
    position = arrow.position
    isUserInteractionEnabled = true
    arrow.isHidden = true
    // Put a shape under the button so that it is easier to push
    let shape = SKShapeNode(circleOfRadius: 50)
    shape.alpha = 0.0000001
    addChild(shape)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func removeSelf() {
    if let pad = parent as? DirectionKeypad {
      removeFromParent()
      if !pad.isDisabled {
        arrow.isHidden = false
      }
    }
  }
}

class CrashButton: MovementButton {
  init(arrow: DirectionArrow, planet: Planet) {
    super.init(msg: "Crash", color: UIColor.red, arrow: arrow, planet: planet)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    arrow.touchesBegan(touches, with: event)
  }
}

class LandButton: MovementButton {
  init(arrow: DirectionArrow, planet: Planet) {
    super.init(msg: "Land", color: UIColor.green, arrow: arrow, planet: planet)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    arrow.ship.landOn(planet: planet)
  }
}

class LaunchButton: MovementButton {
  init(arrow: DirectionArrow, planet: Planet) {
    super.init(msg: "Launch", color: UIColor.green, arrow: arrow, planet: planet)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    arrow.ship.launch(planet: planet, direction: arrow.direction)
  }
}
