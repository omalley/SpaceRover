//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

  var playerShip: SpaceShip?
  var tileMap:SKTileMapNode?
  
  override func didMove(to view: SKView) {
    /* Setup your scene here */
    for child in children {
      if child.name == "Tile Map" {
        tileMap = (child as! SKTileMapNode)
      }
    }
    tileMap?.isUserInteractionEnabled = true
    playerShip = SpaceShip(name: "player 1", slant: SlantPoint(x:50, y: 30), tiles: tileMap!)
    tileMap?.addChild(Planet(name: "Sol", slant: SlantPoint(x:39, y:23), tiles: tileMap!))
    tileMap?.addChild(Planet(name: "Venus", slant: SlantPoint(x:31, y:19), tiles: tileMap!))
    tileMap?.addChild(Planet(name: "Earth", slant: SlantPoint(x:51, y:29), tiles: tileMap!))
    tileMap?.addChild(Planet(name: "Luna", slant: SlantPoint(x:54, y:30), tiles: tileMap!))
    physicsWorld.contactDelegate = self
  }

  let PAN_SLOWDOWN: CGFloat = 20.0
  let MIN_SCALE: CGFloat = 1.5
  let MAX_SCALE: CGFloat = 6.0
  
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN, y: velocity.y/PAN_SLOWDOWN, duration: 0.5))
  }

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
   
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
  }

  func shipCrash(ship: SpaceShip, planet: Planet) {
    print("Ship \(ship.name!) crashed in to \(planet.name!)")
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    if let ship = contact.bodyA.node as? SpaceShip {
      if let planet = contact.bodyB.node as? Planet {
        shipCrash(ship: ship, planet: planet)
      } else if let gravity = contact.bodyB.node as? GravityArrow {
        ship.enterGravity(gravity)
      }
    } else if let ship = contact.bodyB.node as? SpaceShip {
      if let planet = contact.bodyA.node as? Planet {
        shipCrash(ship: ship, planet: planet)
      } else if let gravity = contact.bodyA.node as? GravityArrow {
        ship.enterGravity(gravity)
      }
    } else {
      print("contact between \(String(describing: contact.bodyA.node)) and \(String(describing: contact.bodyB.node))")
    }
  }
}
