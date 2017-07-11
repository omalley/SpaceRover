//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
  
  let planets = [
    "Sol": SlantPoint(x:39, y:23),
    "Mercury": SlantPoint(x:40, y:20),
    "Venus": SlantPoint(x:31, y:19),
    "Earth": SlantPoint(x:51, y:29),
    "Luna": SlantPoint(x:54, y:30),
    "Mars": SlantPoint(x:40, y:43),
    "Jupiter": SlantPoint(x:59, y:59),
    "Callisto": SlantPoint(x:54, y:59),
  ]

  var playerShip: SpaceShip?
  var tileMap:SKTileMapNode?
  var watcher: ShipInformationWatcher?

  override func didMove(to view: SKView) {
    /* Setup your scene here */
    for child in children {
      if child.name == "Tile Map" {
        tileMap = (child as! SKTileMapNode)
      }
    }
    tileMap?.isUserInteractionEnabled = true
    //Adding Ships
    playerShip = SpaceShip(name: "Vanguard II", slant: SlantPoint(x:50, y: 30), tiles: tileMap!)
    playerShip!.setWatcher(watcher)
    
    playerShip = SpaceShip(name: "Hyperion", slant: SlantPoint(x:56, y: 30), tiles: tileMap!)
    playerShip!.setWatcher(watcher)
    
    //Adding Planets
    for (name, location) in planets {
      tileMap?.addChild(Planet(name: name, slant: location, tiles: tileMap!))
    }
    
    physicsWorld.contactDelegate = self
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
  
  //sets watcher for ship to recieve info for UI Board
  func setWatcher(_ newWatcher: ShipInformationWatcher?) {
    watcher = newWatcher
    playerShip?.setWatcher(newWatcher)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* Called when a touch begins */
    for _ in touches {
      print("outside touch")
    }
  }
   
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
  }

  func shipCrash(ship: SpaceShip, planet: Planet) {
    print("Ship \(ship.name!) crashed in to \(planet.name!)")
  }
  
  func shipCollision(ship: SpaceShip, other: SKNode) {
    if let planet = other as? Planet {
      shipCrash(ship: ship, planet: planet)
    } else if let gravity = other as? GravityArrow {
      ship.enterGravity(gravity)
    } else {
      print("contact between ship and ufo \(other.name!)")
    }
  }
  
  func directionArrowCollision(arrow: DirectionArrow, other: SKNode) {
    if let planet = other as? Planet {
      arrow.overPlanet(planet)
    } else {
      print("contact between direction arrow \(arrow.name!) and ufo \(other.name!)")
    }
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
