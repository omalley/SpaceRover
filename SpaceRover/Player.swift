//
//  Player.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 8/11/19.
//  Copyright © 2019 Hazen O'Malley. All rights reserved.
//

import CoreData
import SpriteKit

extension PlayerModel {
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

class Player {
  var ships = [SpaceShip]()
  let model: PlayerModel

  init(_ model: PlayerModel, tiles: SKTileMapNode) {
    self.model = model
    if let shipList = model.ships {
      for ship in shipList {
        ships.append(SpaceShip(model: ship as! ShipModel, player: self,
                               tiles: tiles))
      }
    }
  }
}
