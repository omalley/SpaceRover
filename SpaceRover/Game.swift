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

  var playerList: [PlayerModel] {
    return players!.array as! [PlayerModel]
  }

  var shipList: [ShipModel] {
    return playerList.flatMap({$0.shipList})
  }

  var winner: PlayerModel? {
    for player in playerList {
      if player.state == PlayerState.Won {
        return player
      }
    }
    return nil
  }

  /**
   * Get the number of complete turns that have occurred.
   */
  var turnNumber: Int {
    let numPlayers = players!.count
    return (Int(turnCount) + numPlayers - 1) / numPlayers
  }

  /**
   * Get the index of the current player.
   */
  func currentShip() -> Int {
    return Int(turnCount) % numberOfShips()
  }

  /**
   * Get the total number of ships in the game.
   */
  func numberOfShips() -> Int {
    var result = 0
    for player in playerList {
      result += player.ships!.count
    }
    return result
  }

  /**
   * Count the number of live ships still in the game.
   */
  func liveShips() -> Int {
    var result = 0
    for player in playerList {
      for ship in player.shipList {
        if (ship.state != ShipState.Destroyed) {
          result += 1
        }
      }
    }
    return result
  }

  /**
   * Advance to the next live player
   */
  func nextShip() {
    let ships = shipList
    let numShips = ships.count
    repeat {
      turnCount += 1
    } while ships[Int(turnCount) % numShips].state == ShipState.Destroyed
  }

  func getGameState() -> String {
    switch state! {
    case .NOT_STARTED:
      return "Not started"
    case .IN_PROGRESS:
      return "In turn \(turnNumber)"
    case .FINISHED:
      if let winner = winner {
        return "\(winner.name!) won in \(turnNumber) turns"
      } else {
        return "Everyone died."
      }
    }
  }

  /** Get the status of the given player in the game.
   */
  func getPlayerStatus(_ player: PlayerModel) -> String {
    // When we have different games, there should be an upper level
    // switch on the game.
    let ship = player.shipList[0]
    switch player.state! {
    case .Lost:
      return ship.deathReason!
    case .Won:
      return "Won in \(turnNumber) turns."
    case .Playing:
      let goals = Array(ship.raceGoalSet)
        .map {$0.name!}
        .sorted()
        .joined(separator: ", ");
      return "Missing: \(goals)"
    }
  }
}
