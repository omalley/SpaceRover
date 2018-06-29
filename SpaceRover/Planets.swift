//
//  Planets.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 6/24/18.
//  Copyright © 2018 Hazen O'Malley. All rights reserved.
//

import SpriteKit

enum GravityStrength {
  case none, half, full
}

class Planet: SKSpriteNode {
  var slant: SlantPoint
  let level: Int
  let isLandable: Bool
  let gravity: GravityStrength
  let orbiting: Planet?
  let orbitDistance: Int?

  convenience init(name: String, slant: SlantPoint, tiles: SKTileMapNode, radius: Int,
                   landable: Bool, gravity: GravityStrength, orbiting: Planet?, orbitDistance: Int,
                   level: Int) {
    self.init(name:name, image:name, slant:slant, tiles:tiles, radius:radius, landable: landable,
              gravity: gravity, orbiting: orbiting, orbitDistance: orbitDistance, level: level)
  }

  init(name: String, image: String, slant: SlantPoint, tiles: SKTileMapNode, radius: Int,
       landable: Bool, gravity: GravityStrength, orbiting: Planet?, orbitDistance: Int,
       level: Int) {
    let texture = SKTexture(imageNamed: image)
    self.slant = slant
    isLandable = landable
    self.gravity = gravity
    self.orbiting = orbiting
    self.orbitDistance = orbitDistance
    self.level = level
    super.init(texture: texture, color: UIColor.clear, size: (texture.size()))
    let nameLabel = SKLabelNode(text: name)
    nameLabel.zPosition = 1
    nameLabel.position = CGPoint(x: 0, y: 25)
    nameLabel.fontSize = 20
    nameLabel.fontName = UiFontName
    addChild(nameLabel)
    self.name = name
    position = slantToView(slant, tiles: tiles)
    zPosition = 10
    if gravity != GravityStrength.none {
      for direction in HexDirection.all() {
        if direction != HexDirection.NoAcc {
          let posn = findRelativePosition(direction.invert(), tiles: tiles)
          addChild(GravityArrow(direction: direction, planet: self, position: posn,
                                strength: gravity))
        }
      }
    }
    physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(radius))
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

  static let textures = [SKTexture(imageNamed: "Asteroids1"), SKTexture(imageNamed: "Asteroids2")]

  init(slant: SlantPoint, tiles: SKTileMapNode) {
    let texture = Asteroid.textures[Int(arc4random_uniform(2))]
    super.init(texture: texture, color: UIColor.clear, size: texture.size())
    name = "asteroid at \(slant.x), \(slant.y)"
    position = slantToView(slant, tiles: tiles)
    zPosition = 10
    physicsBody = SKPhysicsBody(circleOfRadius: 55)
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

  init(direction: HexDirection, planet: Planet, position: CGPoint, strength: GravityStrength) {
    self.direction = direction
    self.planet = planet
    self.strength = strength
    var textureName : String?;
    switch strength {
    case .none:
      break
    case .full:
      textureName = "GravityArrow"
    case .half:
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

