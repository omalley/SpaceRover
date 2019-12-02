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

  var model: GameModel?

  /**
   * Scene is displayed, go ahead and start the game
   */
  override func viewDidLoad() {
    winnerLabel.text = model?.getGameState()
    playerTable?.dataSource = self
  }

  @IBAction func done(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return model!.players!.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "gameEndPlayerInfo", for: indexPath)
    let player = model!.playerList[indexPath.row]
    cell.textLabel?.text = player.name
    cell.detailTextLabel?.text = model?.getPlayerStatus(player)
    return cell
  }
  

}
