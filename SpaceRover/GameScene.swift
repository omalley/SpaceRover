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
    ship = SpaceShip(name: info.shipName!, on: on, tiles: on.parent as! SKTileMapNode,
                     color: info.color!, player: info)
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
    let loc = (Int(arc4random_uniform(UInt32(max-min)+1))+min);
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
          print("\(planetInfo.name) got \(String(describing: spLoc)) and \(numX),\(numY) with \(theta) degrees")
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
  }

  let originalAsteroids = [
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

  let asteroidDensity = [
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   2,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   2,   2,   0,   0,   5,   0,   0,   0,   0,   0,   0,
      0,   8,   8,   8,   8,   0,   0,  18,  18,   8,   8,  13,  15,  18,
     20,  18,  18,  28,  28,  28,  33,  23,  23,  31,  56,  38,  31,  31,
     56,  54,  54,  67,  62,  56,  56,  87,  97,  97, 110, 105, 105,  87,
     77,  77,  97, 141, 133, 121, 121, 136, 144, 144, 139, 157, 139, 139,
    128, 128, 149, 149, 144, 144, 172, 172, 169, 169, 200, 177, 177, 210,
    211, 218, 205, 205, 216, 216, 216, 216, 257, 234, 236, 236, 236, 244,
    231, 231, 236, 264, 264, 275, 287, 287, 272, 264, 264, 298, 311, 303,
    290, 290, 290, 357, 329, 329, 372, 372, 321, 321, 357, 357, 447, 401,
    401, 413, 413, 429, 470, 439, 329, 401, 449, 380, 380, 403, 383, 383,
    419, 380, 426, 372, 372, 470, 467, 413, 401, 401, 434, 475, 455, 455,
    519, 498, 493, 493, 537, 498, 498, 588, 601, 534, 534, 557, 560, 560,
    562, 562, 593, 609, 580, 506, 506, 604, 568, 537, 537, 485, 485, 521,
    565, 537, 537, 565, 565, 565, 557, 568, 560, 542, 542, 611, 514, 514,
    575, 609, 562, 516, 516, 580, 614, 616, 627, 568, 568, 624, 624, 604,
    596, 596, 557, 557, 586, 586, 601, 601, 609, 637, 637, 673, 609, 609,
    650, 650, 660, 622, 622, 663, 647, 611, 611, 670, 670, 678, 678, 678,
    686, 665, 657, 632, 632, 660, 632, 691, 622, 622, 593, 593, 678, 629,
    629, 676, 675, 786, 714, 714, 709, 709, 663, 663, 714, 724, 642, 642,
    699, 624, 624, 688, 663, 640, 627, 614, 614, 622, 570, 570, 575, 575,
    560, 547, 547, 485, 485, 542, 542, 568, 568, 586, 611, 578, 544, 472,
    472, 539, 537, 537, 532, 532, 503, 503, 524, 524, 434, 434, 478, 416,
    416, 429, 424, 424, 478, 439, 421, 393, 326, 326, 365, 249, 249, 331,
    331, 282, 282, 318, 323, 265, 244, 236, 236, 246, 226, 226, 241, 218,
    216, 205, 193, 159, 159, 190, 177, 177, 154, 154, 144, 144, 128, 118,
     90,  90,  95,  67,  67,  43,  20,  10,  10,   2,   2,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,  15,  23,  43,  61,  90, 108, 141,
    141, 162, 177, 205, 205, 249, 249, 287, 313, 326, 326, 380, 380, 349,
    349, 395, 447, 447, 465, 395, 395, 480, 480, 406, 406, 503, 508, 508,
    524, 524, 524, 550, 511, 511, 586, 575, 575, 580, 588, 544, 544, 591,
    591, 593, 573, 573, 593, 593, 573, 573, 647, 647, 652, 580, 580, 606,
    606, 591, 591, 611, 657, 627, 580, 580, 539, 539, 598, 604, 593, 593,
    604, 586, 598, 598, 596, 596, 539, 539, 539, 519, 519, 498, 562, 562,
    562, 560, 560, 514, 514, 526, 583, 542, 521, 521, 550, 550, 552, 490,
    490, 547, 526, 526, 521, 501, 472, 472, 493, 493, 493, 498, 475, 475,
    524, 519, 519, 521, 542, 475, 467, 467, 488, 472, 452, 452, 460, 408,
    408, 462, 506, 413, 413, 470, 439, 439, 437, 437, 475, 442, 498, 452,
    416, 416, 470, 416, 416, 388, 388, 452, 403, 403, 383, 383, 406, 426,
    442, 457, 437, 465, 480, 437, 395, 395, 393, 393, 457, 326, 326, 352,
    365, 285, 249, 249, 293, 308, 277, 290, 305, 370, 326, 326, 334, 305,
    305, 347, 390, 334, 334, 362, 434, 416, 411, 411, 437, 401, 403, 426,
    449, 447, 447, 444, 434, 434, 437, 437, 429, 416, 416, 413, 357, 357,
    403, 431, 339, 434, 367, 367, 426, 421, 421, 424, 408, 403, 385, 385,
    406, 406, 447, 457, 344, 344, 385, 401, 401, 357, 357, 367, 431, 398,
    398, 426, 388, 339, 339, 354, 375, 344, 344, 316, 316, 316, 316, 367,
    321, 295, 295, 349, 349, 380, 303, 262, 262, 254, 226, 226, 231, 195,
    157, 146, 128, 105,  97,  92,  64,  20,  13,   8,   0,   0,   0,   0,
      0,  10,  25,  25,  51,  59,  59,  87, 110, 110, 100, 100, 108, 108,
    100, 100, 136, 139, 115, 115, 128, 144, 146, 154, 128, 128, 151, 159,
    144, 144, 154, 139, 139, 167, 144, 144, 182, 187, 208, 144, 144, 113,
    113, 126, 105, 133, 154, 157, 121, 121, 115, 115, 108, 108, 115, 115,
    133, 110, 110, 113, 154, 133, 118, 126, 108, 108, 108, 139, 115, 115,
    115, 103, 103, 128, 128, 113, 113, 159, 146, 121, 121, 139, 139, 144,
    115, 105, 105, 108, 123, 136,  97,  98, 159, 141, 141, 164, 159, 100,
    100, 108, 108, 136, 123, 123, 133, 133, 167, 115, 115, 123, 123,  97,
     97,  87,  74,  69,   0,   0,   0,   0,  87,  87, 162, 185, 190, 203,
    298, 228, 213, 241, 254, 254, 254, 290, 290, 285, 285, 313, 303, 331,
    287, 272, 272, 285, 285, 295, 295, 306, 280, 280, 285, 323, 318, 318,
    323, 300, 282, 316, 295, 272, 272, 293, 262, 262, 262, 264, 277, 275,
    275, 269, 254, 254, 277, 262, 216, 216, 270, 244, 244, 259, 208, 208,
    167, 167, 193, 193, 182, 182, 203, 228, 244, 280, 246, 246, 264, 264,
    305, 303, 303, 262, 262, 329, 285, 285, 287, 336, 336, 298, 298, 323,
    323, 372, 341, 365, 344, 344, 357, 349, 349, 385, 380, 372, 357, 282,
    282, 303, 303, 344, 321, 321, 329, 329, 354, 354, 365, 365, 383, 383,
    339, 339, 359, 359, 383, 365, 365, 408, 372, 372, 349, 349, 383, 354,
    354, 370, 385, 401, 393, 357, 357, 385, 352, 385, 385, 377, 334, 334,
    318, 318, 367, 347, 341, 341, 354, 354, 321, 321, 318, 318, 334, 334,
    334, 349, 298, 298, 272, 272, 326, 336, 331, 305, 305, 352, 344, 326,
    326, 375, 321, 344, 344, 347, 347, 347, 388, 388, 411, 395, 375, 375,
    406, 352, 352, 390, 344, 344, 401, 388, 287, 287, 313, 282, 282, 293,
    280, 280, 290, 300, 264, 264, 213, 213, 280, 280, 246, 239, 239, 254,
    249, 226, 226, 241, 241, 272, 272, 239, 218, 218, 226, 244, 190, 190,
    177, 177, 159, 159, 187, 187, 180, 180, 175, 139, 139, 159, 146, 146,
    121, 121,  97,  97, 121, 118,  72,  72,  74,  97,  90,  90,  79,  59,
     59,  72,  61,  51,  51,  59,  51,  41,  41,  20,  20,  28,  13,  13,
      8,   2,   2,  10,   2,   2,  13,   2,   2,   5,   2,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   2,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
      2,   2,   2,   0,   0,   0,   0,   0,   0,   0,   0,   2,   2,   2,
      0,   0,   2,   5,   2,   0,   0,   0,   0,   0,   5,   0,   0,   2,
      2,   2,   2,   2,   2,   0,   0,   0,   2,   5,   5,   2,   0,   0,
      0,   0,   8,   0,   0,   2,  13,   2,   2,   5,   2,   2,   2,   5,
      0,   0,   2,   5,   0,   0,   0,   0,   8,   8,   5,   5,   5,   5,
      5,   5,   2,   2,  15,   5,   5,   0,   8,   5,   5,   8,   8,   8,
      8,   8,   5,   2,   2,   5,   0,   0,   2,   0,   0,   8,  10,  10,
      8,   2,   2,  10,   0,   0,   2,   2,   2,   2,   2,   2,   5,   5,
     13,   5,   5,   5,   0,   0,   0,   2,   2,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,   2,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   2,   2,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   2,   2,   0,   0,   0,   0,   2,   0,   0,
      5,   2,   0,   0,   0]

  // the earth orbit radius in points
  let AuDistance = 930.0
  let sunLocation = SlantPoint(x:39, y:23)

  func hasAsteroids(point: SlantPoint) -> Bool {
    let distance = viewDistance(point, sunLocation, tiles: tileMap!) / AuDistance
    if distance < 2.0 || distance >= 3.5 {
      return false
    }
    let density = asteroidDensity[Int((distance - 2.0) * Double(asteroidDensity.count) / 1.5)]
    return getRandom(min: 0, max: 800) < density
  }

  func createRandomAsteroids() {
    for row in 0 ... tileMap!.numberOfRows {
      for column in 0 ... tileMap!.numberOfColumns {
        let slant = AppleHex(column: column, row: row).toSlantPoint()
        if hasAsteroids(point: slant) {
          tileMap?.addChild(Asteroid(slant: slant, tiles: tileMap!))
        }
      }
    }
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

  /**
   * The primary information for the planets.
   * The landable property is set for the race scenario
   * orbitDistance is the number of points (110 per hex) for the orbit. This represents 1 point per
   * 100,000 miles of the real planet. Moon orbits are set 1 point per 1,000 miles so that they
   * aren't in the same hex as the planet. *smile*
   */
  let planetInformation = [
    PlanetInformation(name: "Sol", width:55, isLandable:false, gravity:.full, orbiting:nil,
                      orbitDistance:0),
    PlanetInformation(name: "Mercury", width:15, isLandable:false, gravity:.full, orbiting:"Sol",
                      orbitDistance:368),
    PlanetInformation(name: "Venus", width:25, isLandable:true, gravity:.full, orbiting:"Sol",
                      orbitDistance:672),
    PlanetInformation(name: "Earth", width:25, isLandable:true, gravity:.full, orbiting:"Sol",
                      orbitDistance: 930),
    PlanetInformation(name: "Luna", width:10, isLandable:false, gravity:.half, orbiting:"Earth",
                      orbitDistance:239), // 239,000 mi
    PlanetInformation(name: "Mars", width:20, isLandable:true, gravity:.full, orbiting:"Sol",
                      orbitDistance:1416),
    PlanetInformation(name: "Jupiter", width:45, isLandable:false, gravity:.full, orbiting:"Sol",
                      orbitDistance:4836),
    PlanetInformation(name: "Io", width:10, isLandable:false, gravity:.half, orbiting:"Jupiter",
                      orbitDistance:262), // 262,219 mi
    PlanetInformation(name: "Ganymede", width:10, isLandable:false, gravity:.full,
                      orbiting:"Jupiter", orbitDistance: 665), // 664,867 mi
    PlanetInformation(name: "Callisto", width:10, isLandable:true, gravity:.full,
                      orbiting:"Jupiter", orbitDistance: 1170), // 1,170,042 miles
    PlanetInformation(name: "Ceres", width:12, isLandable:false, gravity:.none, orbiting:"Sol",
                      orbitDistance:2574)
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
      createRandomAsteroids()
    } else {
      //ORDERED PLANETS
      setOriginalLocation()
      // Adding asteroids
      for location in originalAsteroids {
        tileMap?.addChild(Asteroid(slant: location, tiles: tileMap!))
      }
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
      remainingPlanets[name.name!] = Set<Planet>()
      for (_, planet) in planets {
        if planet.gravity == GravityStrength.full {
          remainingPlanets[name.name!]?.insert(planet)
        }
      }
    }
    turnState = TurnState.WAITING_FOR_DIRECTION
    livePlayers = players.count
    players[nextPlayer].ship.startTurn()
    turns = 1
    watcher?.startTurn(player: players[nextPlayer].info.name!)
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
          watcher?.startTurn(player: players[nextPlayer].info.name!)
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
    print("Player \(ship.player.name!) died - \(ship.deathReason!)")
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
        remainingPlanets[ship.player.name!]?.remove(gravity.planet)
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
