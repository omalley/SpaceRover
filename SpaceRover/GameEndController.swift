//
//  GameEndController.swift
//  SpaceRover
//
//  Created by Owen O'Malley on 7/29/17.
//  Copyright © 2017 Hazen O'Malley. All rights reserved.
//

import UIKit

class GameEndController: UIViewController {
  
  @IBOutlet weak var winnerLabel: UILabel!

  var gameState: GameScene?

  /**
   * Scene is displayed, go ahead and start the game
   */
  override func viewDidLoad() {
    winnerLabel.text = gameState?.getGameState()
  }

  @IBAction func done(_ sender: UIButton) {
    self.navigationController?.popToRootViewController(animated: true)
  }

}
