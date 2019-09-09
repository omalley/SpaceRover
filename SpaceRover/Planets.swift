//
//  Planets.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 6/24/18.
//  Copyright © 2018 Hazen O'Malley. All rights reserved.
//

import CoreData
import SpriteKit

enum GravityStrength: Int16 {
  case None=0, Half, Full
}

enum ObjectKind: Int16 {
  case Star=0, Planet, Moon, Asteroid
}

extension BoardObjectModel {

  var kind: ObjectKind? {
    get {
      return ObjectKind(rawValue: kindRaw)
    }
    set(value) {
      kindRaw = value!.rawValue
    }
  }

  var gravity: GravityStrength? {
    get {
      return GravityStrength(rawValue: gravityRaw)
    }
    set(value) {
      gravityRaw = value!.rawValue
    }
  }

  func toSlant() -> SlantPoint {
    return SlantPoint(x: Int(positionX), y: Int(positionY))
  }
}

let HEX_SIZE = 110.0

class Planet: SKSpriteNode {
  let model: BoardObjectModel

  init(model: BoardObjectModel, tiles: SKTileMapNode) {
    let name = model.name!
    let texture = SKTexture(imageNamed: name)
    self.model = model
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    let nameLabel = SKLabelNode(text: name)
    nameLabel.zPosition = 1
    nameLabel.position = CGPoint(x: 0, y: 25)
    nameLabel.fontSize = 20
    nameLabel.fontName = UiFontName
    addChild(nameLabel)
    self.name = name
    position = slantToView(model.toSlant(), tiles: tiles)
    zPosition = 10
    let gravity = model.gravity!
    if gravity != GravityStrength.None {
      for direction in HexDirection.all() {
        if direction != HexDirection.NoAcc {
          let posn = findRelativePosition(direction.invert(), tiles: tiles)
          addChild(GravityArrow(direction: direction, planet: self, position: posn,
                                strength: gravity))
        }
      }
    }
    physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(HEX_SIZE * model.radius))
    physicsBody?.categoryBitMask = planetContactMask
    physicsBody?.contactTestBitMask = shipContactMask | accelerationContactMask
    physicsBody?.collisionBitMask = 0
    physicsBody?.isDynamic = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class Asteroid: SKSpriteNode {

  static let textures = [SKTexture(imageNamed: "Asteroids1"),
                         SKTexture(imageNamed: "Asteroids2")]
  let model: BoardObjectModel

  init(model: BoardObjectModel, tiles: SKTileMapNode) {
    let slant = model.toSlant()
    let texture = Asteroid.textures[Int(arc4random_uniform(2))]
    self.model = model
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    name = "asteroid at \(slant.x), \(slant.y)"
    position = slantToView(slant, tiles: tiles)
    zPosition = 10
    physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(HEX_SIZE * model.radius))
    physicsBody?.categoryBitMask = asteroidsContactMask
    physicsBody?.contactTestBitMask = shipContactMask
    physicsBody?.collisionBitMask = 0
    physicsBody?.isDynamic = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class GravityArrow: SKSpriteNode {
  let direction: HexDirection
  let planet: Planet
  let strength: GravityStrength

  init(direction: HexDirection, planet: Planet, position: CGPoint,
       strength: GravityStrength) {
    self.direction = direction
    self.planet = planet
    self.strength = strength
    var textureName : String?;
    switch strength {
    case .None:
      break
    case .Full:
      textureName = "GravityArrow"
    case .Half:
      textureName = "HalfGravityArrow"
    }
    let texture = SKTexture(imageNamed: textureName!)

    // Create the hexagon with the additional wedge toward the planet
    let bodyShape = CGMutablePath()
    bodyShape.addLines(between: [CGPoint(x:111, y:0),
                                 CGPoint(x:0, y:-64),
                                 CGPoint(x:-55, y:-32),
                                 CGPoint(x:-55, y:32),
                                 CGPoint(x:0, y:64),
                                 CGPoint(x:111, y:0)])
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    self.name = "\(strength) gravity \(direction) toward \(planet.name!)"
    zPosition = 10
    alpha = 0.6
    self.position = position
    physicsBody = SKPhysicsBody(polygonFrom: bodyShape)
    physicsBody?.categoryBitMask = gravityContactMask
    physicsBody?.contactTestBitMask = shipContactMask
    physicsBody?.collisionBitMask = 0
    physicsBody?.isDynamic = false
    let sixtyDegree = Double.pi / 3
    run(SKAction.rotate(byAngle: CGFloat(sixtyDegree + direction.rotateAngle()), duration: 0))
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

