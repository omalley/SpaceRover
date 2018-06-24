//
//  SlantPoint.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 6/24/18.
//  Copyright © 2018 Hazen O'Malley. All rights reserved.
//

import SpriteKit

struct SlantPoint: Equatable {
  var x: Int
  var y: Int

  static func ==(lhs: SlantPoint, rhs: SlantPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }

  static func +(lhs: SlantPoint, rhs: SlantPoint) -> SlantPoint {
    return SlantPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }
}

enum HexDirection: Int {
  case NoAcc, West, NorthWest, NorthEast, East, SouthEast, SouthWest;
}

extension HexDirection {
  static func all() -> AnySequence<HexDirection> {
    return AnySequence {
      return HexDirectionGenerator()
    }
  }



  struct HexDirectionGenerator: IteratorProtocol {
    var currentSection = 0

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
      var newValue = ((self.rawValue - 1) + turns) % 6
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
    case .NorthEast:
      return 0
    case .East:
      return 5*Double.pi/3
    case .SouthEast:
      return 4*Double.pi/3
    case .SouthWest:
      return 3*Double.pi/3
    case .West:
      return 2*Double.pi/3
    case .NorthWest:
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

/**
 * Slantpoint Grid Matrix
 * (-1,2)(0,2) (1,2) (2,2)
 *    (-1,1)(0,1) (1,1) (2,1)
 *       (-1,0)(0,0)  (1,0) (2,0)
 *          (-1,-1)(0,-1)(1,-1)(2,-1)
 *             (-1,-2)(0,-2)(1,-2)(2,-2)
 *
 * Swift Hex Matrix
 * (-2,2)(-1,2) (0,2) (1,2)
 *    (-2,1)(-1,1) (0,1) (1,1)
 *       (-1,0)(0,0)  (1,0) (2,0)
 *          (-1,-1)(0,-1)(1,-1)(2,-1)
 *             (0,-2)(1,-2)(2,-2)(3,-2)
 *
 **/

func slantToView(_ pos: SlantPoint, tiles: SKTileMapNode) -> CGPoint {
  return tiles.centerOfTile(atColumn: pos.x - ((pos.y+1) / 2), row: pos.y)
}

func viewToSlant(_ pos: CGPoint, tiles: SKTileMapNode) -> SlantPoint? {
  let x = tiles.tileColumnIndex(fromPosition: pos)
  let y = tiles.tileRowIndex(fromPosition: pos)
  if (x == UInt.max || y == UInt.max){
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

/**
 * Compute the distance from the origin measured in hex widths.
 */
func computeDistance(_ point: SlantPoint) -> Double {
  let y = Double(point.y) * sqrt(3.0) / 2.0
  let x = Double(point.x) - Double(point.y) / 2.0
  return hypot(x, y)
}

