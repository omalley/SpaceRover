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
  let location: SlantPoint
  let width: Int
  let isLandable: Bool
  let gravity: GravityStrength
  let orbiting: String?
  let orbitDistance: Int
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  
  func getRandom(min:Int,max:Int) -> Int {
    let loc = (Int(arc4random_uniform(UInt32(max)+1))+min);
    return loc;
  }
  
  func randomizeLocations(){
    planetLocations.removeAll()
    for (name,info) in originalPlanetLocations{
      let numX = getRandom(min: 35, max: 55)
      let numY = getRandom(min: 35, max: 55)
      let newPlanetLocations = PlanetInformation(location: SlantPoint(x:numX,y:numY), width:info.width,isLandable:info.isLandable,gravity:info.gravity,orbiting:info.orbiting,orbitDistance:info.orbitDistance)
      planetLocations[name]=newPlanetLocations
    }
  }
  
  func setOriginalLocation() {
    planetLocations.removeAll()
    for (name,info) in originalPlanetLocations {
      planetLocations[name] = info
    }
  }
  
  var planetLocations = [String: PlanetInformation]()
  
  // the landable property is set for the race scenario
  let originalPlanetLocations = [
    "Sol": PlanetInformation(location:SlantPoint(x:39, y:23), width:55, isLandable:false, gravity:.full,orbiting:nil,orbitDistance:0),
    "Mercury": PlanetInformation(location:SlantPoint(x:40, y:20), width:15, isLandable:false, gravity:.full,orbiting:"Sol",orbitDistance:4),
    "Venus": PlanetInformation(location:SlantPoint(x:31, y:19), width:25, isLandable:true, gravity:.full,orbiting:"Sol",orbitDistance:8),
    "Earth": PlanetInformation(location:SlantPoint(x:51, y:29), width:25, isLandable:true, gravity:.full,orbiting:"Sol",orbitDistance:12),
    "Luna": PlanetInformation(location:SlantPoint(x:54, y:30), width:10, isLandable:false, gravity:.half,orbiting:"Earth",orbitDistance:3),
    "Mars": PlanetInformation(location:SlantPoint(x:40, y:43), width:20, isLandable:true, gravity:.full,orbiting:"Sol",orbitDistance:21),
    "Jupiter": PlanetInformation(location:SlantPoint(x:59, y:59), width:45, isLandable:false, gravity:.full,orbiting:"Sol",orbitDistance:0),
    "Callisto": PlanetInformation(location:SlantPoint(x:54, y:59), width:10, isLandable:true, gravity:.full,orbiting:"Jupiter",orbitDistance:39),
    "Ganymede": PlanetInformation(location:SlantPoint(x:63, y:61), width:10, isLandable:false, gravity:.full,orbiting:"Jupiter",orbitDistance:0),
    "Io": PlanetInformation(location:SlantPoint(x:59, y:57), width:10, isLandable:false, gravity:.half,orbiting:"Jupiter",orbitDistance:0)

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

  var players: [Player] = []
  var nextPlayer: Int = 0
  var livePlayers: Int = 0
  var tileMap:SKTileMapNode?
  var watcher: ShipInformationWatcher?
  var planets = [String: Planet]()
  var turns = 0
  var isGameOver: Bool = true
  var winner: PlayerInfo?

  // map from the player's name to the list of planets they still need to reach
  var remainingPlanets = [String: Set<Planet>]()

  override func didMove(to view: SKView) {
    //RANDOM PLANETS
    //randomizeLocations()
    //ORDERED PLANETS
    setOriginalLocation()
    /* Setup your scene here */
    for child in children {
      if child.name == "Tile Map" {
        tileMap = (child as! SKTileMapNode)
      }
    }
    tileMap?.isUserInteractionEnabled = true

    //Adding Planets
    for (name, info) in planetLocations {
      let planet = Planet(name: name, slant: info.location, tiles: tileMap!, radius: info.width,
                          landable: info.isLandable, gravity: info.gravity, orbiting: info.orbiting, orbitDistance: info.orbitDistance)
      tileMap?.addChild(planet)
      planets[name] = planet
    }

    // Adding asteroids
    for location in asteroids {
      tileMap?.addChild(Asteroid(slant: location, tiles: tileMap!))
    }

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
    isGameOver = false
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

  func getNextPlayer() {
    if !isGameOver {
      for i in 1 ... players.count {
        let candidate = (nextPlayer + i) % players.count
        if !players[candidate].ship.isDead {
          if candidate <= nextPlayer {
            turns += 1
          }
          nextPlayer = candidate
          camera?.run(SKAction.move(to: convert(players[nextPlayer].ship.position , from: tileMap!),
                                    duration: 0.5))
          watcher?.startTurn(player: players[nextPlayer].info.playerName)
          players[nextPlayer].ship.startTurn()
          return
        }
      }
    }
  }

  override func update(_ currentTime: TimeInterval) {
    if !isGameOver && nextPlayer < players.count {
      let ship = players[nextPlayer].ship
      if ship.inMotion && !ship.arrows!.hasActions() && !ship.hasActions() {
        ship.endTurn()
        if remainingPlanets[ship.player.playerName]?.count == 0 {
          print("\(ship.player.playerName) won")
          isGameOver = true
          winner = ship.player
          watcher?.endGame(self)
        } else {
          getNextPlayer()
        }
      } else if ship.isDead {
        getNextPlayer()
      }
    }
  }

  func getGameState() -> String {
    if let win = winner {
      return "\(win.playerName) won in \(turns) turns"
    } else if isGameOver {
      return "Everyone died."
    } else {
      return "In turn \(turns)"
    }
  }

  func shipCollision(ship: SpaceShip, other: SKNode) {
    if ship.inMotion && !ship.hasLanded {
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
      if (ship.isDead) {
        print("Player \(ship.player.playerName) died - \(ship.deathReason!)")
        livePlayers -= 1
        if livePlayers == 0 {
          isGameOver = true
        }
        watcher?.crash(ship: ship)
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
