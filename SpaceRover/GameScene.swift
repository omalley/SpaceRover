//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum TurnState {
  case WAITING_FOR_DIRECTION, MOVING, TURN_DONE, GAME_OVER
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  // What part of the turn are we in?
  var turnState = TurnState.WAITING_FOR_DIRECTION
  var players: [Player] = []
  var nextPlayer: Int = 0
  var livePlayers: Int = 0
  var tileMap:SKTileMapNode?
  var watcher: ShipInformationWatcher?
  var planets = [String: Planet]()
  var turns = 0
  var winner: PlayerModel?
  var randomMap = false

  // map from the player's name to the list of planets they still need to reach
  var remainingPlanets = [String: Set<Planet>]()

  lazy var board: BoardState = {
    let delegate = UIApplication.shared.delegate as? AppDelegate
    return BoardState(width: tileMap!.numberOfColumns,
                      height: tileMap!.numberOfRows,
                      context: delegate!.persistentContainer.viewContext,
                      system: SystemDescription())
  }()

  override func didMove(to view: SKView) {
    /* Setup your scene here */
    for child in children {
      if child.name == "Tile Map" {
        tileMap = (child as! SKTileMapNode)
      }
    }
    tileMap?.isUserInteractionEnabled = true

    if randomMap {
      board.randomizeLocations()
    } else {
      board.classicLocations()
    }

    // create the sprites for the board elements
    for obj in board.elements {
      switch obj.kind! {
      case .Asteroid:
        tileMap?.addChild(Asteroid(model: obj, tiles: tileMap!))
      case .Planet, .Moon, .Star:
        let planet = Planet(model: obj, tiles: tileMap!)
        tileMap?.addChild(planet)
        planets[obj.name!] = planet
      }
    }

    moveTo(planets["Earth"]!)
    physicsWorld.contactDelegate = self
  }

  func startGame(watcher: ShipInformationWatcher?, names: [PlayerModel]) {
    nextPlayer = 0
    self.watcher = watcher
    let earth = planets["Earth"]
    players.removeAll()
    remainingPlanets.removeAll()
    for name in names {
      let player = Player(name, on: earth!)
      player.ship.setWatcher(watcher)
      players.append(player)
      remainingPlanets[name.name!] = Set<Planet>()
      for (_, planet) in planets {
        if planet.model.gravity == GravityStrength.Full {
          remainingPlanets[name.name!]?.insert(planet)
        }
      }
    }
    turnState = TurnState.WAITING_FOR_DIRECTION
    livePlayers = players.count
    players[nextPlayer].ship.startTurn()
    turns = 1
    watcher?.startTurn(player: players[nextPlayer].model.name!)
  }

  let PAN_SLOWDOWN: CGFloat = 20.0
  let MIN_SCALE: CGFloat = 1.5
  let MAX_SCALE: CGFloat = 6.0

  //Pans around the screen
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN,
                                y: velocity.y/PAN_SLOWDOWN, duration: 0.5))
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
        if !players[candidate].model.hasLost {
          if candidate <= nextPlayer {
            turns += 1
          }
          nextPlayer = candidate
          moveTo(players[nextPlayer].ship)
          watcher?.startTurn(player: players[nextPlayer].model.name!)
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
        if remainingPlanets[ship.player.name!]?.count == 0 {
          print("\(ship.player.name!) won")
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
      return "\(win.name!) won in \(turns) turns"
    } else if turnState == TurnState.GAME_OVER {
      return "Everyone died."
    } else {
      return "In turn \(turns)"
    }
  }

  func shipDeath(ship: SpaceShip) {
    print("Player \(ship.player.model.name!) died - \(ship.model.deathReason!)")
    livePlayers -= 1
    if livePlayers == 0 {
      turnState = TurnState.GAME_OVER
    } else {
      turnState = TurnState.TURN_DONE
    }
  }

  func shipCollision(ship: SpaceShip, other: SKNode) {
    if turnState == TurnState.MOVING && ship.model.state != .Landed {
      if let planet = other as? Planet {
        ship.crash(reason: "Ship \(ship.name!) crashed in to \(planet.name!)")
      } else if let gravity = other as? GravityArrow {
        remainingPlanets[ship.player.model.name!]?.remove(gravity.planet)
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
