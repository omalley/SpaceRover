//
//  GameEndController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/29/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import UIKit

class GameEndController: UIViewController, UITableViewDataSource {
  
  @IBOutlet weak var winnerLabel: UILabel!
  @IBOutlet weak var playerTable: UITableView!

  var gameState: GameScene?

  /**
   * Scene is displayed, go ahead and start the game
   */
  override func viewDidLoad() {
    winnerLabel.text = gameState?.getGameState()
    playerTable?.dataSource = self
  }

  @IBAction func done(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return gameState!.players.count
  }

  func getRemainingPlanets(_ player: Player) -> String {
    let remaining = gameState?.remainingPlanets[player.model.name!]
    var result = ""
    var first = true
    for planet in remaining! {
      if first {
        first = false
      } else {
        result += ", "
      }
      result += planet.name!
    }
    return result
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "gameEndPlayerInfo", for: indexPath)
    let player = gameState!.players[indexPath.row]
    cell.textLabel?.text = player.model.name
    
    switch player.model.state! {
    case .Lost:
      cell.detailTextLabel?.text = player.ship.model.deathReason!
    case .Playing:
      cell.detailTextLabel?.text = getRemainingPlanets(player)
    case .Won:
      cell.detailTextLabel?.text = "Winner"
    }
    return cell
  }
  

}
