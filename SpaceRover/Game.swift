//
//  GameState.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 9/7/19.
//  Copyright © 2019 Hazen O'Malley. All rights reserved.
//

import CoreData
import SpriteKit

enum Scenario: Int16 {
  case RACE_CLASSIC = 0, RACE_RANDOM;
}

extension Scenario {

  static func count() -> Int {
    return 2
  }

  func name() -> String {
    switch (self) {
    case .RACE_CLASSIC:
      return "Race - Classic Map"
    case .RACE_RANDOM:
      return "Race - Random Map"
    }
  }
}

enum GameState: Int16 {
  case NOT_STARTED=0, IN_PROGRESS, FINISHED
}

extension GameModel {
  var scenario: Scenario? {
    get {
      return Scenario(rawValue: scenarioRaw)
    }
    set(value) {
      scenarioRaw = value!.rawValue
    }
  }

  var state: GameState? {
    get {
      return GameState(rawValue: stateRaw)
    }
    set(value) {
      stateRaw = value!.rawValue
    }
  }
}

class Game {
  let model: GameModel

  init(context: NSManagedObjectContext, tiles: SKTileMapNode) {
    do {
      let gameList = try context.fetch(GameModel.fetchRequest())
      if gameList.count >= 1 {
        model = gameList[0] as! GameModel
      } else {
        model = GameModel(context: context)
        model.scenario = .RACE_CLASSIC
        model.state = .NOT_STARTED
      }
    } catch let error as NSError {
      fatalError("Error loading board: \(error), \(error.userInfo)")
    }
  }
}
