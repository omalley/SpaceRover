//
//  GameViewController.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import UIKit
import SpriteKit

class PlayerNotification {
  let view: GameViewController
  let ship: SpaceShip

  init(view: GameViewController, ship: SpaceShip) {
    self.view = view
    self.ship = ship
  }

  func present() {
    // Nothing here
  }

  func dismiss() {
    _ = view.handleNextNotification()
  }
}

class ShipCrashNotification: PlayerNotification {
  override func present() {
    let alert = UIAlertController(title:"Ship \(ship.name!) destroyed!",
      message: ship.model.deathReason!, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "Okay", style: .default, handler: {_ in
      if self.view.roverScene!.turnState == TurnState.GAME_OVER {
        self.view.endGame(self.view.roverScene!)
      }
      self.dismiss()})
    alert.addAction(alertAction)
    view.present(alert, animated: true)
  }
}

class HalfGravityQuestion: PlayerNotification {
  let gravity: GravityArrow

  init(view: GameViewController, ship: SpaceShip, gravity: GravityArrow) {
    self.gravity = gravity
    super.init(view: view, ship: ship)
  }

  override func present() {
    let alert = UIAlertController(title:"Ship \(ship.name!)", message: "Accept \(gravity.name!)",
                                  preferredStyle: .alert)
    let noButton = UIAlertAction(title: "No", style: .cancel, handler: {_ in self.dismiss()})
    alert.addAction(noButton)
    let yesButton = UIAlertAction(title: "Yes", style: .default,
                                    handler: {_ in
                                      self.ship.accelerateShip(direction: self.gravity.direction)
                                      self.ship.moveAccArrows()
                                      self.dismiss()})
    alert.addAction(yesButton)
    view.present(alert, animated: true)
  }
}

class GameViewController: UIViewController, ShipInformationWatcher {

  var roverScene: GameScene?
  var players: [PlayerModel]?
  var state = GameState.NOT_STARTED
  var randomMap = false
  var notificationList = [PlayerNotification]()

  @IBAction func doPan(_ sender: UIPanGestureRecognizer) {
    roverScene?.doPan(sender.velocity(in: self.view))
  }

  func viewPlanetMenu() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    if let rover = roverScene {
      for (name, planet) in rover.planets {
        let kind = planet.model.kind!
        if kind == .Star || kind == .Planet {
          alert.addAction(UIAlertAction(title: name, style: .default) {
            _ in self.roverScene!.moveTo(planet)
          })
        }
      }
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  func viewShipMenu() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    if let rover = roverScene {
      for player in rover.players {
        if player.ship.model.state != .Destroyed {
          alert.addAction(UIAlertAction(title: player.info.shipName, style: .default) {
            _ in self.roverScene!.moveTo(player.ship)
          })
        }
      }
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  func selfDestruct(ship: SpaceShip) {
    ship.crash(reason: "self-destruct")
  }

  @IBAction func menuButton(_ sender: UIButton) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    alert.addAction(UIAlertAction(title: "View planet ...", style: .default) {
      _ in self.viewPlanetMenu()
    })

    alert.addAction(UIAlertAction(title: "View ship ...", style: .default) {
      _ in self.viewShipMenu()
    })

    alert.addAction(UIAlertAction(title: "Game Status", style: .default) {
      _ in self.performSegue(withIdentifier: "presentGameStatus", sender: self)
    })

    alert.addAction(UIAlertAction(title: "Self destruct", style: .default) {
      _ in
      if let rover = self.roverScene {
        self.selfDestruct(ship: rover.players[rover.nextPlayer].ship)
      }
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    present(alert, animated: true)
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
      roverScene?.randomMap = randomMap

      // Configure the view.
      skView.showsFPS = false
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
    if state == GameState.NOT_STARTED {
      roverScene?.startGame(watcher: self, names: players!)
      state = GameState.IN_PROGRESS
    }
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
  
  func crash(ship: SpaceShip) {
    roverScene?.shipDeath(ship: ship)
    // gravity notifications don't matter if they crashed ...
    notificationList.removeAll()
    notificationList.append(ShipCrashNotification(view: self, ship: ship))
    _ = handleNextNotification()
  }

  func startTurn(player: String) {
    if roverScene!.turnState == TurnState.TURN_DONE {
      if roverScene!.livePlayers > 1 {
        let alert = UIAlertController(title:"Next Turn", message: player, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Okay", style: .default)
        alert.addAction(alertAction)
        self.present(alert, animated: true)
      }
      roverScene!.turnState = TurnState.WAITING_FOR_DIRECTION
    }
  }

  func endGame(_ param: GameScene) {
    state = GameState.FINISHED
    performSegue(withIdentifier: "presentEndGame", sender: self)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let next = segue.destination as? GameEndController {
      next.gameState = roverScene
    }
  }

  func shipMoving(ship: SpaceShip) {
    roverScene?.turnState = TurnState.MOVING
  }

  func shipDoneMoving(ship: SpaceShip) {
    roverScene?.turnState = TurnState.TURN_DONE
  }

  func getTurnState() -> TurnState {
    return roverScene!.turnState
  }

  func optionalHalfGravity(ship: SpaceShip, gravity: GravityArrow) {
    notificationList.append(HalfGravityQuestion(view: self, ship: ship, gravity: gravity));
    _ = handleNextNotification()
  }

  func handleNextNotification() -> Bool {
    let notEmpty = notificationList.count > 0
    if self.presentedViewController == nil && notEmpty {
      let next = notificationList.remove(at: 0)
      next.present()
    }
    return self.presentedViewController != nil || notEmpty
  }
}
