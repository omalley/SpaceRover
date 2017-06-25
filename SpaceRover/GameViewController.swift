//
//  GameViewController.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  var skView: SKView?
  var roverScene: GameScene?

  @IBAction func doPan(_ sender: UIPanGestureRecognizer) {
    roverScene?.doPan(sender.velocity(in: self.view))
  }
  
  @IBAction func doPinch(_ sender: UIPinchGestureRecognizer) {
    roverScene?.doPinch(sender.velocity)
  }
  
  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    //skView!.frame = CGRect(x:0, y:0, width:size.width, height:size.height);
    //roverScene!.size = skView!.frame.size
    print("Changing to \(size)")
  }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        skView = (self.view as! SKView)

        if let scene = GameScene(fileNamed:"GameScene") {
          roverScene = scene
          // Configure the view.
          skView!.showsFPS = true
          skView!.showsNodeCount = false
            
          /* Sprite Kit applies additional optimizations to improve rendering performance */
          skView!.ignoresSiblingOrder = true
            
          /* Set the scale mode to scale to fit the window */
          scene.scaleMode = .resizeFill
            
          skView!.presentScene(scene)
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
}
