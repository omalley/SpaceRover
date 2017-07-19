//
//  GameViewController.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, ShipInformationWatcher {
  var roverScene: GameScene?
  var players: [PlayerInfo]?
  var playersLeft = 0

  @IBAction func doPan(_ sender: UIPanGestureRecognizer) {
    roverScene?.doPan(sender.velocity(in: self.view))
  }
  
  @IBAction func doPinch(_ sender: UIPinchGestureRecognizer) {
    roverScene?.doPinch(sender.velocity)
  }
  
  @IBOutlet weak var shipInformation: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let skView = (self.view as! SKView)

    if let scene = GameScene(fileNamed:"GameScene") {
      roverScene = scene

      // Configure the view.
      skView.showsFPS = true
      skView.showsNodeCount = false
            
      /* Sprite Kit applies additional optimizations to improve rendering performance */
      skView.ignoresSiblingOrder = true
            
      /* Set the scale mode to scale to fit the window */
      scene.scaleMode = .resizeFill
            
      skView.presentScene(scene)
    }
  }

  /**
   * Scene is displayed, go ahead and start the game
   */
  override func viewDidAppear(_ animated: Bool) {
    playersLeft = players!.count
    roverScene?.startGame(watcher: self, names: players!)
  }

  override var shouldAutorotate : Bool {
    return true
  }

  override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return .all
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }

  override var prefersStatusBarHidden : Bool {
    return true
  }
  
  func updateShipInformation(_ msg: String) {
    shipInformation.text = msg
  }
  
  func crash(reason: String, ship: SpaceShip) {
    playersLeft -= 1
    let alert = UIAlertController(title:"Crash!", message: reason, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "Okay", style: .default)
    alert.addAction(alertAction)
    self.present(alert, animated: true)
  }

  func startTurn(player: String) {
    if playersLeft > 1 {
      let alert = UIAlertController(title:"Next Turn", message: player, preferredStyle: .alert)
      let alertAction = UIAlertAction(title: "Okay", style: .default)
      alert.addAction(alertAction)
      self.present(alert, animated: true)
    }
  }

  func endGame(_ message: String) {
    let alert = UIAlertController(title:"End Game", message: message, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "Okay", style: .default)
    alert.addAction(alertAction)
    self.present(alert, animated: true)
  }
}
