//
//  ScenarioSelectionController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/16/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import UIKit

class PlayerInfo {
  var playerName: String
  var shipName: String
  var color: SpaceshipColor

  init(player: String, ship: String, color: SpaceshipColor) {
    self.playerName = player
    self.shipName = ship
    self.color = color
  }
}

class ScenarioSelectionController: UIViewController, UITableViewDataSource {

  @IBOutlet weak var playerTable: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    playerTable?.dataSource = self
  }

  @IBAction func changeNumberOfPlayers(_ sender: UIStepper) {
    print("Players = \(Int(sender.value))")
  }

  var players: [PlayerInfo] = [PlayerInfo(player:"Owen", ship: "Hyperion", color: .blue),
                               PlayerInfo(player:"Hazen", ship: "Vanguard II", color: .red)]

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let game = segue.destination as? GameViewController {
      print("Starting game")
      game.players = players
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return players.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerListCell", for: indexPath)

    cell.textLabel?.text = players[indexPath.row].playerName
    cell.detailTextLabel?.text = players[indexPath.row].shipName
    let image = players[indexPath.row].color.image().cgImage()
    cell.imageView?.image = UIImage(cgImage: image)

    return cell
  }
}
