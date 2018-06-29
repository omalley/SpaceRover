//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

class Player {
  let ship: SpaceShip
  let info: PlayerInfo

  init(_ description: PlayerInfo, on: Planet) {
    info = description
    ship = SpaceShip(name: info.shipName, on: on, tiles: on.parent as! SKTileMapNode,
                     color: info.color, player: info)
  }
}

struct PlanetInformation {
  let name: String
  let width: Int
  let isLandable: Bool
  let gravity: GravityStrength
  let orbiting: String?
  let orbitDistance: Int
}

enum TurnState {
  case WAITING_FOR_DIRECTION, MOVING, TURN_DONE, GAME_OVER
}

func sin(degrees: Double) -> Double {
  return __sinpi(degrees/180.0)
}

func cos(degrees: Double) -> Double {
  return __cospi(degrees/180.0)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  // Where is each planet?
  var planetLocations = [String: SlantPoint]()
  // What part of the turn are we in?
  var turnState = TurnState.WAITING_FOR_DIRECTION
  var players: [Player] = []
  var nextPlayer: Int = 0
  var livePlayers: Int = 0
  var tileMap:SKTileMapNode?
  var watcher: ShipInformationWatcher?
  var planets = [String: Planet]()
  var turns = 0
  var winner: PlayerInfo?
  var randomMap = false

  // map from the player's name to the list of planets they still need to reach
  var remainingPlanets = [String: Set<Planet>]()

  func getRandom(min:Int,max:Int) -> Int {
    let loc = (Int(arc4random_uniform(UInt32(max)+1))+min);
    return loc;
  }
  
  func randomizeLocations(){
    planetLocations.removeAll()
    for planetInfo in planetInformation {
      var spLoc : SlantPoint?
      if let orbiting = planetInfo.orbiting {
        let parentLocation = slantToView(planetLocations[orbiting]!, tiles: tileMap!)
        while (spLoc == nil) {
          let theta = Double(getRandom(min: 0, max: 359))
          let numX = sin(degrees: theta) * Double(planetInfo.orbitDistance)
          let numY = cos(degrees: theta) * Double(planetInfo.orbitDistance)
          let cg = CGPoint(x:CGFloat(numX)+parentLocation.x, y:CGFloat(numY)+parentLocation.y)
          spLoc = viewToSlant(cg, tiles: tileMap!)
        }
      } else {
        spLoc = SlantPoint(x:39,y:23)
      }
      planetLocations[planetInfo.name] = spLoc;
    }
  }
  
  func setOriginalLocation() {
    planetLocations.removeAll()
    planetLocations["Sol"] = SlantPoint(x:39, y:23)
    planetLocations["Mercury"] = SlantPoint(x:40, y:20)
    planetLocations["Venus"] = SlantPoint(x:31, y:19)
    planetLocations["Earth"] = SlantPoint(x:51, y:29)
    planetLocations["Luna"] = SlantPoint(x:54, y:30)
    planetLocations["Mars"] = SlantPoint(x:40, y:43)
    planetLocations["Jupiter"] = SlantPoint(x:59, y:59)
    planetLocations["Callisto"] = SlantPoint(x:54, y:59)
    planetLocations["Ganymede"] = SlantPoint(x:63, y:61)
    planetLocations["Io"] = SlantPoint(x:59, y:57)
    planetLocations["Ceres"] = SlantPoint(x:47, y:50)
    printPlanetDistances()
  }
  
  func printPlanetDistances() {
    for planet in planetInformation {
      if let orbits = planet.orbiting {
        let parentLocation = slantToView(planetLocations[orbits]!, tiles: tileMap!)
        let ourLocation = slantToView(planetLocations[planet.name]!, tiles: tileMap!)
        let distance = hypotf(Float(parentLocation.x - ourLocation.x), Float(parentLocation.y - ourLocation.y))
        print("\(planet.name) = \(distance) ")
      } else {
        print("\(planet.name) = 0 ")
      }
    }
  }
  
  // the landable property is set for the race scenario
  let planetInformation = [
    PlanetInformation(name: "Sol", width:55, isLandable:false, gravity:.full, orbiting:nil,
                      orbitDistance:0),
    PlanetInformation(name: "Mercury", width:15, isLandable:false, gravity:.full, orbiting:"Sol",
                      orbitDistance:400),
    PlanetInformation(name: "Venus", width:25, isLandable:true, gravity:.full, orbiting:"Sol",
                      orbitDistance:768),
    PlanetInformation(name: "Earth", width:25, isLandable:true, gravity:.full, orbiting:"Sol",
                      orbitDistance:1152),
    PlanetInformation(name: "Luna", width:10, isLandable:false, gravity:.half, orbiting:"Earth",
                      orbitDistance:293),
    PlanetInformation(name: "Mars", width:20, isLandable:true, gravity:.full, orbiting:"Sol",
                      orbitDistance:2163),
    PlanetInformation(name: "Jupiter", width:45, isLandable:false, gravity:.full, orbiting:"Sol",
                      orbitDistance:3463),
    PlanetInformation(name: "Callisto", width:10, isLandable:true, gravity:.full,
                      orbiting:"Jupiter",orbitDistance:554),
    PlanetInformation(name: "Ganymede", width:10, isLandable:false, gravity:.full,
                      orbiting:"Jupiter", orbitDistance:384),
    PlanetInformation(name: "Io", width:10, isLandable:false, gravity:.half, orbiting:"Jupiter",
                      orbitDistance:222),
    PlanetInformation(name: "Ceres", width:12, isLandable:false, gravity:.none, orbiting:"Sol",
                      orbitDistance:2663)
  ]

  let asteroids = [
    SlantPoint(x: 47, y:41),
    SlantPoint(x: 49, y:41),
    SlantPoint(x: 46, y:42),
    SlantPoint(x: 50, y:42),
    SlantPoint(x: 53, y:42),
    SlantPoint(x: 55, y:42),
    SlantPoint(x: 56, y:42),
    SlantPoint(x: 48, y:43),
    SlantPoint(x: 50, y:43),
    SlantPoint(x: 53, y:43),
    SlantPoint(x: 56, y:43),
    SlantPoint(x: 59, y:43),
    SlantPoint(x: 65, y:43),
    SlantPoint(x: 46, y:44),
    SlantPoint(x: 50, y:44),
    SlantPoint(x: 51, y:44),
    SlantPoint(x: 54, y:44),
    SlantPoint(x: 57, y:44),
    SlantPoint(x: 59, y:44),
    SlantPoint(x: 61, y:44),
    SlantPoint(x: 65, y:44),
    SlantPoint(x: 66, y:44),
    SlantPoint(x: 37, y:45),
    SlantPoint(x: 48, y:45),
    SlantPoint(x: 51, y:45),
    SlantPoint(x: 52, y:45),
    SlantPoint(x: 53, y:45),
    SlantPoint(x: 55, y:45),
    SlantPoint(x: 65, y:45),
    SlantPoint(x: 68, y:45),
    SlantPoint(x: 69, y:45),
    SlantPoint(x: 36, y:46),
    SlantPoint(x: 37, y:46),
    SlantPoint(x: 38, y:46),
    SlantPoint(x: 47, y:46),
    SlantPoint(x: 49, y:46),
    SlantPoint(x: 59, y:46),
    SlantPoint(x: 62, y:46),
    SlantPoint(x: 67, y:46),
    SlantPoint(x: 38, y:47),
    SlantPoint(x: 52, y:47),
    SlantPoint(x: 55, y:47),
    SlantPoint(x: 57, y:47),
    SlantPoint(x: 59, y:47),
    SlantPoint(x: 60, y:47),
    SlantPoint(x: 62, y:47),
    SlantPoint(x: 63, y:47),
    SlantPoint(x: 65, y:47),
    SlantPoint(x: 39, y:48),
    SlantPoint(x: 41, y:48),
    SlantPoint(x: 42, y:48),
    SlantPoint(x: 57, y:48),
    SlantPoint(x: 62, y:48),
    SlantPoint(x: 64, y:48),
    SlantPoint(x: 65, y:48),
    SlantPoint(x: 68, y:48),
    SlantPoint(x: 68, y:48),
    SlantPoint(x: 69, y:48),
    SlantPoint(x: 70, y:48),
    SlantPoint(x: 43, y:49),
    SlantPoint(x: 45, y:49),
    SlantPoint(x: 48, y:49),
    SlantPoint(x: 60, y:49),
    SlantPoint(x: 63, y:49),
    SlantPoint(x: 64, y:49),
    SlantPoint(x: 67, y:49),
    SlantPoint(x: 38, y:50),
    SlantPoint(x: 39, y:50),
    SlantPoint(x: 41, y:50),
    SlantPoint(x: 59, y:50),
    SlantPoint(x: 40, y:51),
    SlantPoint(x: 39, y:52),
    SlantPoint(x: 40, y:52),
  ]

  override func didMove(to view: SKView) {
    /* Setup your scene here */
    for child in children {
      if child.name == "Tile Map" {
        tileMap = (child as! SKTileMapNode)
      }
    }
    tileMap?.isUserInteractionEnabled = true
    
    if randomMap {
      //RANDOM PLANETS
      randomizeLocations()
    } else {
      //ORDERED PLANETS
      setOriginalLocation()
    }
    
    //Adding Planets
    for planetInfo in planetInformation {
      var depth = 0
      var parent: Planet? = nil
      if let orbit = planetInfo.orbiting {
        parent = planets[orbit]
        depth = parent!.level + 1
      }
      let planet = Planet(name: planetInfo.name, slant: planetLocations[planetInfo.name]!,
                          tiles: tileMap!,
                          radius: planetInfo.width, landable: planetInfo.isLandable,
			                    gravity: planetInfo.gravity, orbiting: parent,
                          orbitDistance: planetInfo.orbitDistance, level: depth)
      tileMap?.addChild(planet)
      planets[planetInfo.name] = planet
    }

    // Adding asteroids
    for location in asteroids {
      tileMap?.addChild(Asteroid(slant: location, tiles: tileMap!))
    }
    moveTo(planets["Earth"]!)
    physicsWorld.contactDelegate = self
  }

  func startGame(watcher: ShipInformationWatcher?, names: [PlayerInfo]) {
    nextPlayer = 0
    self.watcher = watcher
    let earth = planets["Earth"]
    players.removeAll()
    remainingPlanets.removeAll()
    for name in names {
      let player = Player(name, on: earth!)
      player.ship.setWatcher(watcher)
      players.append(player)
      remainingPlanets[name.playerName] = Set<Planet>()
      for (_, planet) in planets {
        if planet.gravity == GravityStrength.full {
          remainingPlanets[name.playerName]?.insert(planet)
        }
      }
    }
    turnState = TurnState.WAITING_FOR_DIRECTION
    livePlayers = players.count
    players[nextPlayer].ship.startTurn()
    turns = 1
    watcher?.startTurn(player: players[nextPlayer].info.playerName)
  }
  
  let PAN_SLOWDOWN: CGFloat = 20.0
  let MIN_SCALE: CGFloat = 1.5
  let MAX_SCALE: CGFloat = 6.0

  //Pans around the screen
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN, y: velocity.y/PAN_SLOWDOWN, duration: 0.5))
  }

  //Moves in and out with the pinch gesture
  func doPinch(_ velocity: CGFloat) {
    let newScale = camera!.xScale - velocity
    if (newScale > MIN_SCALE && newScale < MAX_SCALE) {
      camera?.run(SKAction.scale(to: newScale, duration: 0.5))
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      print("outside touch")
    }
  }

  func moveTo(_ object: SKSpriteNode) {
    camera?.run(SKAction.move(to: convert(object.position , from: tileMap!),
                              duration: 0.5))
  }

  func getNextPlayer() {
    if turnState == TurnState.TURN_DONE {
      for i in 1 ... players.count {
        let candidate = (nextPlayer + i) % players.count
        if !players[candidate].ship.isDead {
          if candidate <= nextPlayer {
            turns += 1
          }
          nextPlayer = candidate
          moveTo(players[nextPlayer].ship)
          watcher?.startTurn(player: players[nextPlayer].info.playerName)
          players[nextPlayer].ship.startTurn()
          turnState = TurnState.WAITING_FOR_DIRECTION
          return
        }
      }
    }
  }

  override func update(_ currentTime: TimeInterval) {
    switch turnState {
    case .WAITING_FOR_DIRECTION, .GAME_OVER:
      break
    case .MOVING:
      let ship = players[nextPlayer].ship
      if !ship.arrows!.hasActions() && !ship.hasActions() &&
        (watcher == nil || !watcher!.handleNextNotification()) {
        ship.endTurn()
        if remainingPlanets[ship.player.playerName]?.count == 0 {
          print("\(ship.player.playerName) won")
          turnState = TurnState.GAME_OVER
          winner = ship.player
          watcher?.endGame(self)
        } else {
          watcher?.shipDoneMoving(ship: ship)
        }
      }
    case .TURN_DONE:
      getNextPlayer()
    }
  }

  func getGameState() -> String {
    if let win = winner {
      return "\(win.playerName) won in \(turns) turns"
    } else if turnState == TurnState.GAME_OVER {
      return "Everyone died."
    } else {
      return "In turn \(turns)"
    }
  }

  func shipDeath(ship: SpaceShip) {
    print("Player \(ship.player.playerName) died - \(ship.deathReason!)")
    livePlayers -= 1
    if livePlayers == 0 {
      turnState = TurnState.GAME_OVER
    } else {
      turnState = TurnState.TURN_DONE
    }
  }

  func shipCollision(ship: SpaceShip, other: SKNode) {
    if turnState == TurnState.MOVING && !ship.hasLanded {
      if let planet = other as? Planet {
        ship.crash(reason: "Ship \(ship.name!) crashed in to \(planet.name!)")
      } else if let gravity = other as? GravityArrow {
        remainingPlanets[ship.player.playerName]?.remove(gravity.planet)
        ship.enterGravity(gravity)
      } else if let asteroid = other as? Asteroid {
        ship.enterAsteroids(asteroid)
      } else {
        print("contact between ship and ufo \(other.name!)")
      }
    }
  }

  func directionArrowCollision(arrow: DirectionArrow, other: SKNode) {
    // We catch this later in DirectionArrow.detectOverlap
  }

  func didBegin(_ contact: SKPhysicsContact) {
    if let ship = contact.bodyA.node as? SpaceShip {
      shipCollision(ship: ship, other: contact.bodyB.node!)
    } else if let ship = contact.bodyB.node as? SpaceShip {
      shipCollision(ship: ship, other: contact.bodyA.node!)
    } else if let acceleration = contact.bodyA.node as? DirectionArrow {
      directionArrowCollision(arrow: acceleration, other: contact.bodyB.node!)
    } else if let acceleration = contact.bodyB.node as? DirectionArrow {
      directionArrowCollision(arrow: acceleration, other: contact.bodyA.node!)
    } else {
      print("contact between \(String(describing: contact.bodyA.node)) and \(String(describing: contact.bodyB.node))")
    }
  }
}
