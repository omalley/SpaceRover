//
//  Player.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 8/11/19.
//  Copyright © 2019 Hazen O'Malley. All rights reserved.
//

import CoreData
import Foundation

extension PlayerInfo {
  var color: SpaceshipColor? {
    get {
      return SpaceshipColor(rawValue: colorRaw)
    }
    set(value) {
      colorRaw = value!.rawValue
    }
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
