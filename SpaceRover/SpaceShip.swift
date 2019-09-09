//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum SpaceshipColor: Int16 {
  case blue = 0,red,green,purple,orange,yellow;
}

extension SpaceshipColor {

  static func count() -> Int {
    return Int(SpaceshipColor.yellow.rawValue + 1)
  }

  func image() -> SKTexture {
    switch (self) {
    case .blue:
      return SKTexture(imageNamed: "SpaceshipBlue")
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

enum ShipState: Int16 {
  case Landed = 0, Orbit, Flight, Destroyed;
}

/**
 * Adding accessors to the CoreData class.
 */
extension ShipModel {
  var direction: HexDirection? {
    get {
      return HexDirection(rawValue: directionRaw)
    }
    set(value) {
      directionRaw = value!.rawValue
    }
  }

  var state: ShipState? {
    get {
      return ShipState(rawValue: stateRaw)
    }
    set(value) {
      stateRaw = value!.rawValue
    }
  }

  var position: SlantPoint {
    get {
      return SlantPoint(x: Int(positionX), y: Int(positionY))
    }
    set(value) {
      positionX = Int32(value.x)
      positionY = Int32(value.y)
    }
  }

  var velocity: SlantPoint {
    get {
      return SlantPoint(x: Int(velocityX), y: Int(velocityY))
    }
    set(value) {
      velocityX = Int32(value.x)
      velocityY = Int32(value.y)
    }
  }

  func move() {
    positionX += velocityX
    positionY += velocityY
  }

  func accelerate(_ acceleration: SlantPoint) {
    velocityX += Int32(acceleration.x)
    velocityY += Int32(acceleration.y)
  }

  func getInformation() -> String {
    switch state! {
    case .Landed:
      return "\(name!)\nFuel: \(fuel)\nOn \(orbitAround!)"
    case .Destroyed:
      return "\(name!)\ndestroyed"
    case .Orbit:
      return "\(name!)\nFuel: \(fuel)\n\(orbitAround!) orbit"
    case .Flight:
      if (disabledTurns > 0) {
        return "\(name!)\nFuel: \(fuel)\nDisabled: \(disabledTurns)"
      } else {
        return "\(name!)\nFuel: \(fuel)\nSpeed: \(velocity.magnitude())"
      }
    }
  }

  /**
   * Mark the ship as landed on the given planet.
   */
  func landOn(planet: BoardObjectModel) {
    state = .Landed
    fuel = fuelCapacity
    positionX = planet.positionX
    positionY = planet.positionY
    velocityX = 0
    velocityY = 0
    orbitAround = planet
  }

  func crash(reason: String) {
    state = .Destroyed
    deathReason = reason
  }

  func launchFrom(planet: BoardObjectModel,
                  direction: HexDirection) {
    state = .Flight
    orbitAround = nil
    position = planet.toSlant() + direction.toSlant()
    velocity = direction.invert().toSlant()
  }
}

let shipContactMask: UInt32 = 1
let planetContactMask: UInt32 = 2
let gravityContactMask: UInt32 = 4
let accelerationContactMask: UInt32 = 8
let asteroidsContactMask: UInt32 = 16

protocol ShipInformationWatcher {
  /**
   * Process notifications and return true if there are still notifications
   */
  func handleNextNotification() -> Bool
  func getTurnState() -> TurnState
  func updateShipInformation(_ msg: String)
  func optionalHalfGravity(ship: SpaceShip, gravity: GravityArrow)
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
  return nextRandom(min: 1, max: 6)
}

class SpaceShip: SKSpriteNode {
  let tileMap: SKTileMapNode
  let player: Player
  let turnIndicator: SKSpriteNode
  var arrows : DirectionKeypad?
  var watcher: ShipInformationWatcher?

  var model: ShipModel
  var orbitAround: Planet?

  // We need to count how many half gravity wells this ship has hit this turn, because
  // every other half gravity is optional.
  var halfGravityHits = 0

  init (model: ShipModel, player: Player, tiles: SKTileMapNode) {
    tileMap = tiles
    self.model = model
    self.player = player
    let texture = player.model.color!.image()
    let turnIndicatorTexture = SKTexture(imageNamed: "CurrentTurnIndicator")
    turnIndicator = SKSpriteNode(texture: turnIndicatorTexture)
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    self.name = name
    position = slantToView(model.position, tiles: tileMap)
    tileMap.addChild(self)
    arrows = DirectionKeypad(ship: self)
    arrows!.position = self.position
    arrows!.isHidden = true
    tileMap.addChild(arrows!)
    self.addChild(turnIndicator)
    zPosition = 20
    physicsBody = SKPhysicsBody(circleOfRadius: 5)
    physicsBody?.categoryBitMask = shipContactMask
    physicsBody?.contactTestBitMask =
      planetContactMask | gravityContactMask | asteroidsContactMask
    physicsBody?.collisionBitMask = 0
    arrows?.detectOverlap()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setWatcher(_ newWatcher: ShipInformationWatcher?) {
    watcher = newWatcher
    watcher?.updateShipInformation(model.getInformation())
  }

  func getAccellerationPosition(direction: HexDirection) -> CGPoint {
    let newVelocity = model.velocity + direction.toSlant()
    let newPosition = model.position + newVelocity
    return slantToView(newPosition, tiles: tileMap)
  }

  func enterGravity(_ gravity: GravityArrow) {
    if (model.state! != .Landed) {
      print("\(self.name!) hit \(gravity.name!)")
      switch gravity.strength {
      case .Full:
        accelerateShip(direction: gravity.direction)
      case .Half:
        halfGravityHits += 1
        if halfGravityHits % 2 == 1 {
          accelerateShip(direction: gravity.direction)
        } else {
          watcher?.optionalHalfGravity(ship: self, gravity: gravity)
        }
      case .None:
        break
      }
    }
  }

  func accelerateShip(direction: HexDirection) {
    model.accelerate(direction.toSlant())
    moveAccArrows()
  }

  func calculateOrbit() {
    for body in physicsBody!.allContactedBodies() {
      if let gravity = body.node as? GravityArrow {
        // Is the velocity 60 degrees from the gravity?
        let clockwise = gravity.direction.clockwise(turns: 1).toSlant()
        let counterClockwise = gravity.direction.clockwise(turns: -1).toSlant()
        let velocity = model.velocity
        if velocity == clockwise || velocity == counterClockwise {
          orbitAround = gravity.planet
          return
        }
      }
    }
    orbitAround = nil
  }

  func rotateShip (_ newDirection : HexDirection) {
    if newDirection != HexDirection.NoAcc && newDirection != model.direction {
      var rotateBy = (newDirection.rotateAngle() - model.direction!.rotateAngle())
      if (rotateBy >= 0) {
        while (rotateBy > Double.pi) {
          rotateBy -= 2*Double.pi
        }
      } else {
        while (rotateBy < -Double.pi) {
          rotateBy += 2*Double.pi
        }
      }
      model.direction = newDirection
      self.run(SKAction.rotate(byAngle: CGFloat(rotateBy), duration: 0.5))
    }
  }


  func useFuel(_ units: Int) {
    model.fuel -= Int32(units)
    calculateOrbit()
    if (model.fuel == 0) {
      arrows?.disable()
      //"We're outta gas sir."
    }
  }

  func moveAccArrows(){
    arrows?.removeAllActions()
    arrows?.run(
        SKAction.move(to: getAccellerationPosition(direction: HexDirection.NoAcc),
                      duration: 1))
  }

  func move() {
    print("moving \(name!) by \(model.velocity)")
    halfGravityHits = 0
    if model.state != .Landed {
      arrows?.removeLandingButtons()
      watcher?.shipMoving(ship: self)
      model.move()
      let slant = model.position
      run(SKAction.move(to: slantToView(slant, tiles: tileMap), duration: 1))
      // if the player tries to hover over a planet, the gravity needs to pull them again
      let velocity = model.velocity
      if velocity.x == 0 && velocity.y == 0 {
        for body in physicsBody!.allContactedBodies() {
          if let gravity = body.node as? GravityArrow {
            model.velocity = gravity.direction.toSlant()
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
    watcher?.updateShipInformation(model.getInformation())
  }

  func endTurn() {
    watcher?.shipDoneMoving(ship: self)
    if model.state != .Landed {
      arrows?.detectOverlap()
    }
    arrows?.isHidden = true
    turnIndicator.isHidden = true
    if (model.disabledTurns > 0) {
      model.disabledTurns -= 1
      if(model.disabledTurns == 0) {
        arrows?.reenable()
      }
    }
    print("end turn for \(name!)")
  }
  
  func landOn(planet: Planet) {
    print("Land \(name!) on \(planet.name!)")
    arrows?.removeLandingButtons()
    model.landOn(planet: planet.model)
    watcher?.updateShipInformation(model.getInformation())
    moveAccArrows()
    arrows?.setLaunchButtons(planet: planet)
    watcher?.shipMoving(ship: self)
  }

  func launch(planet: Planet, direction: HexDirection) {
    print("Launching \(name!) from \(planet.name!)")
    model.launchFrom(planet: planet.model, direction: direction)
    position = slantToView(model.position, tiles: tileMap)
    arrows?.removeLandingButtons()
    arrows?.position = slantToView(model.position + model.velocity, tiles: tileMap)
    arrows?.detectOverlap()
    watcher?.shipMoving(ship: self)
  }
  
  func crash(reason: String) {
    model.crash(reason: reason)
    arrows?.isHidden = true
    watcher?.crash(ship: self)
  }

  /**
   * Disable the ship for a given number of turns.
   */
  func disable(turns: Int)  {
    print("Disabled for \(turns) turns")
    if model.disabledTurns == 0 {
      arrows?.disable()
      model.disabledTurns = 1
    }
    model.disabledTurns += Int32(turns)
    if model.disabledTurns >= 6 {
      self.crash(reason: " Your ship,  \(name!), burned up in the Asteroid Fields!")
    }
  }

  func enterAsteroids(_ asteroid: Asteroid) {
    if model.velocity.magnitude() > 1 {
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
          if ship.orbitAround == planet && planet.model.isLandable {
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
