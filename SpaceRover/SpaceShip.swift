//
//  SpaceShip.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 6/4/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

/**
 * Roll a six sided die.
 * Returns 1 to 6 inclusive
 */
func rollDie() -> Int {
  return nextRandom(min: 1, max: 6)
}

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
  case Landed = 0, // landed on a planet
       Orbit,      // in orbit around a planet
       Flight,     // normal flight
       Destroyed;
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

  var fullName: String {
    return "\(player!.name!)'s \(name!)"
  }

  var raceGoalSet: Set<BoardObjectModel> {
    return raceGoals! as! Set<BoardObjectModel>
  }

  func reset() {
    deathReason = nil
    disabledTurns = 0
    mutableSetValue(forKey: "raceGoals").removeAllObjects()
  }

  func move() {
    positionX += velocityX
    positionY += velocityY
  }

  func accelerate(_ acceleration: SlantPoint,
                  burn: Int) {
    velocityX += Int32(acceleration.x)
    velocityY += Int32(acceleration.y)
    fuel -= Int32(burn)
    if (fuel <= 0) {
      fuel = 0
    }
    state = .Flight
  }

  func handleGravity(direction: HexDirection,
                     planet: BoardObjectModel) {
    let acceleration = direction.toSlant()
    velocityX += Int32(acceleration.x)
    velocityY += Int32(acceleration.y)
    checkOrbit(planet: planet)
  }

  func getInformation() -> String {
    switch state! {
    case .Landed:
      return "\(name!)\nFuel: \(fuel)\nOn \(orbitAround!.name!)"
    case .Destroyed:
      return "\(name!)\ndestroyed"
    case .Orbit:
      return "\(name!)\nFuel: \(fuel)\n\(orbitAround!.name!) orbit"
    case .Flight:
      if (fuel == 0) {
        return "\(name!)\nOut of fuel"
      } else if (disabledTurns > 0) {
        return "\(name!)\nFuel: \(fuel)\nDisabled: \(disabledTurns)"
      } else {
        let format = NumberFormatter()
        format.maximumFractionDigits = 1
        let speed = format.string(for: velocity.magnitude())!
        return "\(name!)\nFuel: \(fuel)\nSpeed: \(speed)"
      }
    }
  }

  /**
   * Mark the ship as landed on the given planet.
   */
  func landOn(planet: BoardObjectModel) {
    state = .Landed
    fuel = fuelCapacity
    extraBurns = 1
    position = planet.position
    velocityX = 0
    velocityY = 0
    disabledTurns = 0
    orbitAround = planet
  }

  func isDisabled() -> Bool {
    return fuel == 0 || disabledTurns > 0
  }

  func crash(reason: String) {
    state = .Destroyed
    deathReason = reason
  }

  func launchFrom(planet: BoardObjectModel,
                  direction: HexDirection) {
    state = ShipState.Flight
    orbitAround = nil
    position = planet.position + direction.toSlant()
    velocity = direction.invert().toSlant()
    self.direction = direction
  }

  func checkOrbit(planet: BoardObjectModel) {
    let nextPosition = position + velocity
    // Are we flying at 1.0 hex from planet at a speed of 1.0
    if (state == .Flight &&
        (position - planet.position).isOne() &&
        velocity.isOne() &&
        (nextPosition - planet.position).isOne()) {
      state = .Orbit
      orbitAround = planet
    }
  }

  /**
   * Disable the ship for a given number of turns.
   */
  func disable(turns: Int)  {
    print("\(name!) is disabled for \(turns) turns.")
    if disabledTurns == 0 {
      disabledTurns = 1
    }
    disabledTurns += Int32(turns)
    if disabledTurns >= 6 {
      crash(reason: " Your ship,  \(name!), burned up in the Asteroid Fields!")
    }
  }

  /**
   * The ship entered an asteroid hex, check for damage.
   */
  func enterAsteroids() {
    if velocity.magnitude() > 1 {
      let die = rollDie()
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
  func startTurn(ship: SpaceShip)
  func shipMoving(ship: SpaceShip)
  func shipDoneMoving(ship: SpaceShip)
  func endGame(_ : GameScene)
}

let UiFontName = "Copperplate"

class SpaceShip: SKSpriteNode {
  let tileMap: SKTileMapNode
  let turnIndicator: SKSpriteNode
  var arrows : DirectionKeypad?
  var watcher: ShipInformationWatcher

  var model: ShipModel

  // We need to count how many half gravity wells this ship has hit this turn, because
  // every other half gravity is optional.
  var halfGravityHits = 0

  init (model: ShipModel,
        tiles: SKTileMapNode,
        watcher: ShipInformationWatcher) {
    tileMap = tiles
    self.model = model
    self.watcher = watcher
    let texture = model.player!.color!.image()
    let turnIndicatorTexture = SKTexture(imageNamed: "CurrentTurnIndicator")
    turnIndicator = SKSpriteNode(texture: turnIndicatorTexture)
    turnIndicator.isHidden = true
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    self.name = model.fullName
    self.xScale = 0.35
    self.yScale = 0.35
    position = slantToView(model.position, tiles: tileMap)
    isHidden = model.state == ShipState.Destroyed ||
      model.state == ShipState.Landed
    tileMap.addChild(self)
    arrows = DirectionKeypad(ship: self)
    arrows!.isHidden = true
    tileMap.addChild(arrows!)
    self.addChild(turnIndicator)
    zPosition = 20
    physicsBody = SKPhysicsBody(circleOfRadius: 5)
    physicsBody?.categoryBitMask = shipContactMask
    physicsBody?.contactTestBitMask =
      planetContactMask | gravityContactMask | asteroidsContactMask
    physicsBody?.collisionBitMask = 0
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateView() {
    position = slantToView(model.position, tiles: tileMap)
    arrows!.position = slantToView(model.position + model.velocity, tiles: tileMap)
    switch model.state! {
    case .Destroyed:
      arrows?.isHidden = true
      isHidden = true
    case .Orbit, .Flight:
      arrows?.isHidden = false
      isHidden = false
      if model.isDisabled() {
        arrows?.disable()
      } else {
        arrows?.reenable()
      }
      arrows?.detectOverlap()
    case .Landed:
      arrows?.isHidden = false
      isHidden = true
      arrows?.setLaunchButtons(planet: model.orbitAround!)
    }
  }

  func enterGravity(_ gravity: GravityArrow) {
    if model.state! != .Landed {
      print("\(self.name!) hit \(gravity.name!)")
      switch gravity.strength {
      case .Full:
        model.handleGravity(direction: gravity.direction,
                            planet: gravity.planet.model)
      case .Half:
        halfGravityHits += 1
        if halfGravityHits % 2 == 1 {
          model.handleGravity(direction: gravity.direction,
                              planet: gravity.planet.model)
        } else {
          watcher.optionalHalfGravity(ship: self, gravity: gravity)
        }
      case .None:
        break
      }
      moveAccArrows()
    }
  }

  func accelerateShip(direction: HexDirection, burn: Int) {
    model.accelerate(direction.toSlant(), burn: burn)
    moveAccArrows()
  }

  func rotateShip(_ newDirection : HexDirection) {
    let currentAngle = Double(zRotation)
    if newDirection != HexDirection.NoAcc &&
      newDirection.rotateAngle() != currentAngle {
      var rotateBy = newDirection.rotateAngle() - currentAngle
      if rotateBy >= 0 {
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

  func moveAccArrows() {
    let newPosition = model.position + model.velocity
    arrows?.removeAllActions()
    arrows?.run(
      SKAction.move(to: slantToView(newPosition, tiles: tileMap), duration: 1))
  }

  func move() {
    print("moving \(name!) by \(model.velocity)")
    halfGravityHits = 0
    if model.state != .Landed {
      arrows?.removeLandingButtons()
      model.move()
      watcher.shipMoving(ship: self)
      let view = slantToView(model.position, tiles: tileMap)
      run(SKAction.move(to: view, duration: 1))
      // if the player tries to hover over a planet, the gravity needs to pull them again
      if model.velocity.isZero() {
        for body in physicsBody!.allContactedBodies() {
          if let gravity = body.node as? GravityArrow {
            model.velocity = gravity.direction.toSlant()
          }
        }
      }
      moveAccArrows()
    }
  }

  func startTurn() {
    print("start turn for \(name!)")
    updateView()
    turnIndicator.isHidden = model.state == ShipState.Landed
    watcher.updateShipInformation(model.getInformation())
  }

  func endTurn() {
    watcher.shipDoneMoving(ship: self)
    turnIndicator.isHidden = true
    arrows?.isHidden = true
    if model.disabledTurns > 0 {
      model.disabledTurns -= 1
    }
    print("end turn for \(name!)")
  }

  func launch(planet: BoardObjectModel, direction: HexDirection) {
    print("Launching \(name!) from \(planet.name!)")
    model.launchFrom(planet: planet, direction: direction)
    isHidden = false
    position = slantToView(model.position, tiles: tileMap)
    zRotation = CGFloat(model.direction!.rotateAngle())
    arrows?.removeLandingButtons()
    arrows?.position = slantToView(model.position + model.velocity, tiles: tileMap)
    arrows?.detectOverlap()
    watcher.shipMoving(ship: self)
  }

  func landOn(planet: BoardObjectModel) {
    model.landOn(planet: planet)
    updateView()
    endTurn()
  }

  func crash(reason: String) {
    model.crash(reason: reason)
    isHidden = true
    arrows?.isHidden = true
    turnIndicator.isHidden = true
    watcher.crash(ship: self)
  }
}

class DirectionKeypad: SKNode {
  var isDisabled = false

  init(ship: SpaceShip) {
    super.init()
    name = "DirectionKeypad for \(ship.model.name!)"
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

  func setLaunchButtons(planet: BoardObjectModel) {
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
class DirectionArrow: SKSpriteNode {
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
      self.xScale = 0.2
      self.yScale = 0.2
    }
    name = "\(direction) arrow for \(ship.name!)"
    alpha = 0.4

    zRotation = CGFloat(direction.rotateAngle())
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
    if (ship.watcher.getTurnState() == TurnState.WAITING_FOR_DIRECTION) {
      if (direction != HexDirection.NoAcc) {
        ship.accelerateShip(direction: direction, burn: 1)
        ship.rotateShip(direction)
      }
      ship.move()
    }
  }

  func detectOverlap() {
    if let dirKeypad = parent as? DirectionKeypad {
      for body in physicsBody!.allContactedBodies() {
        if let planet = body.node as? Planet {
          if ship.model.orbitAround == planet.model && planet.model.isLandable {
            dirKeypad.addChild(LandButton(arrow: self, planet: planet.model))
          } else {
            dirKeypad.addChild(CrashButton(arrow: self, planet: planet.model))
          }
        }
      }
    }
  }
}

class MovementButton: SKLabelNode {
  let arrow: DirectionArrow
  let planet: BoardObjectModel
  
  init(msg: String, color: UIColor, arrow: DirectionArrow,
       planet: BoardObjectModel) {
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
  init(arrow: DirectionArrow, planet: BoardObjectModel) {
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
  init(arrow: DirectionArrow, planet: BoardObjectModel) {
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
  init(arrow: DirectionArrow, planet: BoardObjectModel) {
    super.init(msg: "Launch", color: UIColor.green, arrow: arrow, planet: planet)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    arrow.ship.launch(planet: planet, direction: arrow.direction)
  }
}
