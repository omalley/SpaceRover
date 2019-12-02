//
//  BoardState.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 8/16/19.
//  Copyright © 2019 Hazen O'Malley. All rights reserved.
//

import CoreData
import Foundation

/**
 * Generate a random number between min and max inclusive.
 */
func nextRandom(min:Int, max:Int) -> Int {
  let loc = (Int(arc4random_uniform(UInt32(max-min)+1))+min);
  return loc;
}

struct PlanetInformation {
  let name: String
  let kind: ObjectKind
  let radius: Double
  let isLandable: Bool
  let gravity: GravityStrength
  let orbiting: String?
  let orbitDistance: Double
  // the location on the classic board
  let classicLocation: SlantPoint
}

/**
 * An interface to describe a solar system.
 */
protocol SolarSystemDescription {
  var sun: PlanetInformation {get}
  var planets: [PlanetInformation] {get}
  var classicAsteroids: [SlantPoint] {get}

  /**
   * What is the probability that a hex the given distance to the sun has an asteroid?
   * Returns a number from 0.0 to 1.0.
   */
  func asteroidProbability(_ distanceToSun: Double) -> Double;
}

class BoardFactory {
  private let system: SolarSystemDescription
  private let width: Int
  private let height: Int
  private let context: NSManagedObjectContext
  private let game: GameModel
  private var planets = [String: BoardObjectModel]()
  var raceGoals = Set<BoardObjectModel>()

  init(width: Int, height: Int,
       context: NSManagedObjectContext,
       system: SolarSystemDescription,
       game: GameModel) {
    self.width = width
    self.height = height
    self.context = context
    self.system = system
    self.game = game
  }

  func build() {
    clear()
    switch game.scenario! {
    case .RACE_CLASSIC:
      classicLocations()
    case .RACE_RANDOM:
      randomizeLocations()
    }
    save(context: context)
  }

  func clear() {
    for elem in game.board!.allObjects as! [BoardObjectModel] {
      context.delete(elem)
    }
  }

  func classicLocations() {
    for planet in system.planets {
      addPlanet(planet, location: planet.classicLocation)
    }
    for asteroid in system.classicAsteroids {
      addAsteroid(location: asteroid)
    }
  }

  func addPlanet(_ info: PlanetInformation, location: SlantPoint) {
    let planet = BoardObjectModel(context: context)
    planet.name = info.name
    planet.kind = info.kind
    planet.gravity = info.gravity
    planet.isLandable = info.isLandable
    planet.radius = info.radius
    planet.position = location
    planet.game = game
    planets[planet.name!] = planet
    if planet.gravity == GravityStrength.Full {
      raceGoals.insert(planet)
    }
  }

  func addAsteroid(location: SlantPoint) {
    let asteroid = BoardObjectModel(context: context)
    asteroid.kind = .Asteroid
    asteroid.position = location
    asteroid.gravity = .None
    asteroid.isLandable = false
    asteroid.game = game
  }

  func lookup(name: String) -> BoardObjectModel {
    return planets[name]!
  }

  func pickLocation(origin: SlantPoint, distance: Double) -> SlantPoint {
    while true {
      let theta = Double(nextRandom(min: 0, max: 3599)) / 10.0
      let point = origin.addPolar(degree: theta, distance: distance)

      // check whether the position is in the board
      let apple = point.toAppleHex()
      if apple.column >= 0 && apple.column < width &&
        apple.row >= 0 && apple.row < height {
        print("Pick polar of theta = \(theta) distance = \(distance)")
        print("Slant = \(point.x), \(point.y); Apple = \(apple.column), \(apple.row)")
        return point
      }
    }
  }

  func randomizeLocations(){
    let sunLocation = system.sun.classicLocation
    for planetInfo in system.planets {
      var spLoc = sunLocation
      if let orbiting = planetInfo.orbiting {
        let parent = planets[orbiting]!.position
        print("Pick location of \(planetInfo.name) relative to \(orbiting) at \(parent)")
        spLoc = pickLocation(origin: parent, distance: planetInfo.orbitDistance)
      }
      addPlanet(planetInfo, location: spLoc)
    }
    for row in 0 ... height {
      for column in 0 ... width {
        let slant = AppleHex(column: column, row: row).toSlantPoint()
        if Int(system.asteroidProbability(slant.distance(sunLocation)) * 1000)
            >=  nextRandom(min: 0, max: 999){
          addAsteroid(location: slant)
        }
      }
    }
  }
}

/**
 * This class describes how the solar system is laid out for generating
 * random boards.
 */
class SolDescription: SolarSystemDescription {
  private static let SOL = "Sol"
  private static let EARTH = "Earth"
  private static let JUPITER = "Jupiter"
  private static let AU_DISTANCE = 10.0

  /**
   * The primary information for the planets.
   * The landable property is set for the race scenario and all of the
   * distances are measured in hexes (center to center of adjacent hexes).
   *
   * We've used 1 hex = 15 million km for the planet orbit radiuses. The moon
   * orbits are modelled at 100x the planet orbits so that they aren't in the
   * same hex as their primary.
   */
  let planets: [PlanetInformation] = [
    PlanetInformation(name: SOL, kind: .Star, radius:0.5, isLandable: false,
                      gravity: .Full, orbiting: nil, orbitDistance: 0,
                      classicLocation: SlantPoint(x:39, y:23)),

    // Planets
    PlanetInformation(name: "Mercury", kind: .Planet, radius: 0.14,
                      isLandable: false, gravity: .Full, orbiting: SOL,
                      orbitDistance: 3.9,  // 57.91 million km
                      classicLocation: SlantPoint(x:40, y:20)),
    PlanetInformation(name: "Venus", kind: .Planet, radius: 0.24,
                      isLandable: true, gravity: .Full, orbiting: SOL,
                      orbitDistance: 7.2, // 108.2 million km
                      classicLocation: SlantPoint(x:31, y:19)),
    PlanetInformation(name: EARTH, kind: .Planet, radius: 0.25,
                      isLandable: true, gravity:.Full, orbiting: SOL,
                      orbitDistance: AU_DISTANCE, // 149.6 million km
                      classicLocation: SlantPoint(x:51, y:29)),
    PlanetInformation(name: "Mars", kind: .Planet, radius: 0.20,
                      isLandable: true, gravity: .Full, orbiting: SOL,
                      orbitDistance:15.2, // 227.9 million km
                      classicLocation: SlantPoint(x:40, y:43)),
    PlanetInformation(name: JUPITER, kind: .Planet, radius: 0.45,
                      isLandable: false, gravity:.Full, orbiting: SOL,
                      orbitDistance: 51.9, // 778.5 million km
                      classicLocation: SlantPoint(x:59, y:59)),
    PlanetInformation(name: "Ceres", kind: .Planet, radius: 0.12,
                      isLandable: false, gravity: .None, orbiting: SOL,
                      orbitDistance: 27.5, // 413 million km
                      classicLocation: SlantPoint(x:47, y:50)),

    // Earth moon
    PlanetInformation(name: "Luna", kind: .Moon, radius: 0.1, isLandable:false,
                      gravity: .Half, orbiting: EARTH,
                      orbitDistance: 2.56, //  0.384 million km
                      classicLocation: SlantPoint(x:54, y:30)),

    // Jupiter moons
    PlanetInformation(name: "Io", kind: .Moon, radius: 0.1, isLandable: false,
                      gravity: .Half, orbiting: JUPITER,
                      orbitDistance: 2.81, // 0.422 million km
                      classicLocation: SlantPoint(x:59, y:57)),
    PlanetInformation(name: "Ganymede", kind: .Moon, radius: 0.1,
                      isLandable: false, gravity: .Full, orbiting: JUPITER,
                      orbitDistance: 7.13, // 1.070 million km
                      classicLocation: SlantPoint(x:63, y:61)),
    PlanetInformation(name: "Callisto", kind: .Moon, radius: 0.1,
                      isLandable: true, gravity: .Full, orbiting: JUPITER,
                      orbitDistance: 12.55, // 1.883 million km
                      classicLocation: SlantPoint(x:54, y:59))
  ]

  lazy var sun: PlanetInformation = { planets[0] }()

  var classicAsteroids: [SlantPoint] = [
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

  /**
   * The density of asteroids by distance from the sun between 2.0 to 3.5 AU.
   * The probability is the entry divided by 800.
   */
  private static let asteroidDensity = [
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

  func asteroidProbability(_ distanceToSun: Double) -> Double {
    let au = distanceToSun / SolDescription.AU_DISTANCE
    if au < 2.0 || au >= 3.5 {
      return 0.0
    }
    let density = SolDescription.asteroidDensity[Int((au - 2.0) *
      Double(SolDescription.asteroidDensity.count) / 1.5)]
    return Double(density) / 800.0
  }
}
