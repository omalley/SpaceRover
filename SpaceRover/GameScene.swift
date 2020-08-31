//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import CoreData
import SpriteKit

enum TurnState {
  case WAITING_FOR_DIRECTION, MOVING, TURN_DONE, GAME_OVER
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  let HEX_SIZE = CGSize(width: 111, height: 128)
  var model: GameModel?
  // What part of the turn are we in?
  var turnState = TurnState.WAITING_FOR_DIRECTION
  var ships: [SpaceShip] = []
  var tileMap: SKTileMapNode?
  var watcher: ShipInformationWatcher?
  var planets = [String: Planet]()

  lazy var context: NSManagedObjectContext = {
    let delegate = UIApplication.shared.delegate as? AppDelegate
    return delegate!.persistentContainer.viewContext
  }()

  func boardSize() -> (Int, Int) {
    return (100, 100)
  }

  override func didMove(to view: SKView) {
    let size = boardSize()
    let tileSet = SKTileSet(named: "RoverTiles")
    tileMap = SKTileMapNode(tileSet: tileSet!, columns: size.0,
                            rows: size.1, tileSize: HEX_SIZE,
                            fillWith: tileSet!.defaultTileGroup!)
    addChild(tileMap!)
    tileMap?.isUserInteractionEnabled = true

    if model?.state == GameState.NOT_STARTED {
      resetGameState()
    }

    ships.removeAll()
    for player in model!.playerList {
      for ship in player.shipList {
        ships.append(SpaceShip(model: ship, tiles: tileMap!, watcher: watcher!))
      }
    }

    // create the sprites for the board elements
    planets.removeAll()
    for obj in model?.board?.allObjects as! [BoardObjectModel] {
      switch obj.kind! {
      case .Asteroid:
        tileMap?.addChild(Asteroid(model: obj, tiles: tileMap!))
      case .Planet, .Moon, .Star:
        let planet = Planet(model: obj, tiles: tileMap!)
        tileMap?.addChild(planet)
        planets[obj.name!] = planet
      }
    }

    physicsWorld.contactDelegate = self
    turnState = TurnState.TURN_DONE
    readyCurrentShip()
  }

  func resetGameState() {
    let board = BoardFactory(width: tileMap!.numberOfColumns,
                             height: tileMap!.numberOfRows,
                             context: context,
                             system: SolDescription(),
                             game: model!)
    board.build()
    let earth = board.lookup(name: "Earth")
    for player in model!.playerList {
      player.state = PlayerState.Playing
      for ship in player.shipList {
        // the ships start landed on earth
        ship.reset();
        ship.landOn(planet: earth)
        // add all of the goals to each ship
        ship.addToRaceGoals(board.raceGoals as NSSet)
      }
    }
    model?.turnCount = 0
    model?.state = GameState.IN_PROGRESS
    save(context: context)
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
    print("outside touch")
  }

  func moveTo(_ object: SKSpriteNode) {
    camera?.run(SKAction.move(to: convert(object.position , from: tileMap!),
                              duration: 0.5))
  }

  func readyCurrentShip() {
    if turnState == TurnState.TURN_DONE {
      let ship = ships[model!.currentShip()]
      moveTo(ship)
      watcher?.startTurn(ship: ship)
      ship.startTurn()
      turnState = TurnState.WAITING_FOR_DIRECTION
      save(context: context)
    }
  }

  override func update(_ currentTime: TimeInterval) {
    switch turnState {
    case .WAITING_FOR_DIRECTION, .GAME_OVER:
      break
    case .MOVING:
      let ship = ships[model!.currentShip()]
      if !ship.arrows!.hasActions() && !ship.hasActions() &&
        (watcher == nil || !watcher!.handleNextNotification()) {
        ship.endTurn()
        if ship.model.raceGoalSet.count == 0 {
          print("\(ship.model.fullName) won")
          turnState = TurnState.GAME_OVER
          ship.model.player?.state = PlayerState.Won
          save(context: context)
          watcher?.endGame(self)
        } else {
          watcher?.shipDoneMoving(ship: ship)
        }
      }
    case .TURN_DONE:
      model?.nextShip()
      readyCurrentShip()
    }
  }

  func shipDeath(ship: SpaceShip) {
    print("Ship \(ship.model.fullName) died - \(ship.model.deathReason!)")
    ship.model.player!.state = .Lost
    if model!.liveShips() == 0 {
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
        ship.model.removeFromRaceGoals(gravity.planet.model)
        ship.enterGravity(gravity)
      } else if other is Asteroid {
        ship.model.enterAsteroids()
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

  override var description : String {
    return "\(type(of: self)) model:\(model!)"
  }
}
