//
//  Player.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 8/11/19.
//  Copyright © 2019 Hazen O'Malley. All rights reserved.
//

import CoreData
import SpriteKit

enum PlayerState: Int16 {
  case Playing = 0, Lost, Won;
}

extension PlayerModel {
  var color: SpaceshipColor? {
    get {
      return SpaceshipColor(rawValue: colorRaw)
    }
    set(value) {
      colorRaw = value!.rawValue
    }
  }

  var state: PlayerState? {
    get {
      return PlayerState(rawValue: stateRaw)
    }
    set(value) {
      stateRaw = value!.rawValue
    }
  }

  var shipList: [ShipModel] {
    return ships!.array as! [ShipModel]
  }
}

func save(context: NSManagedObjectContext) {
  if context.hasChanges {
    do {
      try context.save()
    } catch let error as NSError {
      fatalError("Error saving data: \(error), \(error.userInfo)")
    }
  }
}
