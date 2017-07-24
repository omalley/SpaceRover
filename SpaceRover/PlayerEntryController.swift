//
//  PlayerEntryController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/23/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import UIKit

class PlayerEntryController: UIViewController {
  @IBOutlet weak var playerName: UITextField!
  @IBOutlet weak var shipName: UITextField!
  @IBOutlet weak var shipColor: UISegmentedControl!

  @IBAction func cancelButton(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  func getPlayerInfo() -> PlayerInfo? {
    var color: SpaceshipColor
    switch (shipColor.selectedSegmentIndex) {
    case 0:
      color = .green
    case 1:
      color = .blue
    case 2:
      color = .red
    default:
      color = .green
    }
    return PlayerInfo(player: playerName.text ?? "Player", ship: shipName.text ?? "Foobar",
                      color: color)
  }
}
