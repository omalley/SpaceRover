//
//  SlantPoint.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 6/24/18.
//  Copyright © 2018 Hazen O'Malley. All rights reserved.
//

import SpriteKit

/*
 * Apple hex coordinates
 * (-2,2)  (-1,2)  (0,2)   (1,2)
 *     (-2,1)  (-1,1)  (0,1)   (1,1)
 *         (-1,0)  (0,0)   (1,0)   (2,0)
 *             (-1,-1) (0,-1)  (1,-1)  (2,-1)
 *                 (0,-2)  (1,-2)  (2,-2)  (3,-2)
 *
 * SlantPoint hex coordinates
 * (-1,2)  (0,2)   (1,2)   (2,2)
 *     (-1,1)  (0,1)   (1,1)   (2,1)
 *         (-1,0)  (0,0)   (1,0)   (2,0)
 *             (-1,-1) (0,-1)  (1,-1)  (2,-1)
 *                 (-1,-2) (0,-2)  (1,-2)  (2,-2)
 *
 */

/**
 * A point in the Apple SpriteKit hex coordinates. The columns zigzag
 * back and forth, but generally a range of x and y define a box.
 */
struct AppleHex {
  var x: Int
  var y: Int

  func toSlantPoint() -> SlantPoint {
    return SlantPoint(x: x + ((y+1) / 2), y: y)
  }
}

let RootThreeHalf = sqrt(3.0)/2.0

/**
 * Slant points instead are set up so that the axes match two of the
 * natural directions of a hex board (northeast and east). Thus, slant
 * points are easy to add together, which is handy for games with acceleration
 * and velocity.
 */
struct SlantPoint: Equatable {
  var x: Int
  var y: Int

  static func ==(lhs: SlantPoint, rhs: SlantPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }

  static func +(lhs: SlantPoint, rhs: SlantPoint) -> SlantPoint {
    return SlantPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  static func -(lhs: SlantPoint, rhs: SlantPoint) -> SlantPoint {
    return SlantPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  func toAppleHex() -> AppleHex {
    return AppleHex(x: x - ((y+1) / 2), y: y)
  }

  /**
   * Measure the distance between two slant points in hexes.
   * A "hex" is the distance between the centers of two adjacent hexes.
   */
  func distance(_ point: SlantPoint) -> Double {
    return hypot(Double(x - point.x) - Double(y - point.y) / 2.0,
                 RootThreeHalf * Double(y - point.y))
  }

  /**
   * Get the length of a vector in hexes.
   * This is mostly used on accelerations or velocities.
   */
  func magnitude() -> Double {
    let zero = SlantPoint(x: 0, y:0)
    return distance(zero)
  }

  func isZero() -> Bool {
    return x == 0 && y == 0
  }

  func isOne() -> Bool {
    if (x == 0) {
      return abs(y) == 1
    } else if (y == 0) {
      return abs(x) == 1
    }
    return x == y && abs(x) == 1
  }
  
  /**
   * Calculate the point that is the given angle and distance from this one.
   * degree: 0 to 360
   * distance: measured in hexes
   */
  func addPolar(degree: Double, distance: Double) -> SlantPoint {
    let xOffset = sin(degrees: degree) * distance
    let yOffset = cos(degrees: degree) * distance
    let ySlant = yOffset / RootThreeHalf
    let xSlant = xOffset + ySlant / 2.0
    let offset = SlantPoint(x: Int(round(xSlant)), y: Int(round(ySlant)))
    print("slant = \(xSlant), \(ySlant) -> \(offset)")
    return self + offset
  }
}

enum HexDirection: Int16 {
  case NoAcc, West, NorthWest, NorthEast, East, SouthEast, SouthWest;
}

extension HexDirection {
  static func all() -> AnySequence<HexDirection> {
    return AnySequence {
      return HexDirectionGenerator()
    }
  }

  struct HexDirectionGenerator: IteratorProtocol {
    var currentSection: Int16 = 0

    mutating func next() -> HexDirection? {
      guard let item = HexDirection(rawValue:currentSection) else {
        return nil
      }
      currentSection += 1
      return item
    }
  }

  func invert() -> HexDirection {
    switch (self) {
    case .NoAcc:
      return .NoAcc
    case .NorthEast:
      return .SouthWest
    case .NorthWest:
      return .SouthEast
    case .West:
      return .East
    case .East:
      return .West
    case .SouthWest:
      return .NorthEast
    case .SouthEast:
      return .NorthWest
    }
  }

  func clockwise(turns: Int) -> HexDirection {
    if (self == .NoAcc) {
      return .NoAcc
    } else {
      var newValue = Int16(((Int(self.rawValue) - 1) + turns) % 6)
      if (newValue < 0) {
        newValue += 6
      }
      return HexDirection(rawValue: newValue + 1)!
    }
  }

  func rotateAngle() -> Double {
    switch (self) {
    case .NoAcc:
      return 0
    case .West:
      return 0
    case .NorthWest:
      return 5*Double.pi/3
    case .NorthEast:
      return 4*Double.pi/3
    case .East:
      return 3*Double.pi/3
    case .SouthEast:
      return 2*Double.pi/3
    case .SouthWest:
      return 1*Double.pi/3
    }
  }

  /**
   * Get the SlantPoint vector going in this direction
   */
  func toSlant() -> SlantPoint {
    switch (self) {
    case .NoAcc:
      return SlantPoint(x: 0, y: 0)
    case .NorthEast:
      return SlantPoint(x: 1, y: 1)
    case .East:
      return SlantPoint(x: 1, y: 0)
    case .SouthEast:
      return SlantPoint(x: 0, y: -1)
    case .SouthWest:
      return SlantPoint(x: -1, y: -1)
    case .West:
      return SlantPoint(x: -1, y: 0)
    case .NorthWest:
      return SlantPoint(x: 0, y: 1)
    }
  }
}

func slantToView(_ pos: SlantPoint, tiles: SKTileMapNode) -> CGPoint {
  return tiles.centerOfTile(atColumn: pos.x - ((pos.y+1) / 2), row: pos.y)
}

func viewDistance(_ pos1: SlantPoint, _ pos2: SlantPoint, tiles: SKTileMapNode) -> Double {
  let view1 = slantToView(pos1, tiles: tiles)
  let view2 = slantToView(pos2, tiles: tiles)
  return hypot(Double(view1.x) - Double(view2.x), Double(view1.y) - Double(view2.y))
}

func viewToSlant(_ pos: CGPoint, tiles: SKTileMapNode) -> SlantPoint? {
  let x = tiles.tileColumnIndex(fromPosition: pos)
  let y = tiles.tileRowIndex(fromPosition: pos)
  if (x < 0 || x >= tiles.numberOfColumns || y < 0 || y >= tiles.numberOfRows){
    return nil;
  }
  return SlantPoint(x: x + ((y+1) / 2), y: y)
}

/**
 * Compute the relative position of a direction in the view's coordinates.
 */
func findRelativePosition(_ direction: HexDirection, tiles: SKTileMapNode) -> CGPoint {
  // pick a point that won't cause the relative points to go out of bounds
  let originSlant = SlantPoint(x: 2, y: 2)
  // get the relative slant point
  let slant = originSlant + direction.toSlant()
  let posn = slantToView(slant, tiles: tiles)
  // subtract off the origin
  let origin = slantToView(originSlant, tiles: tiles)
  return CGPoint(x: posn.x - origin.x, y: posn.y - origin.y)
}


func sin(degrees: Double) -> Double {
  return __sinpi(degrees/180.0)
}

func cos(degrees: Double) -> Double {
  return __cospi(degrees/180.0)
}
