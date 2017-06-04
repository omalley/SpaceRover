//
//  GameScene.swift
//  SpaceRover
//
//  Created by Hazen O'Malley on 5/28/17.
//  Copyright (c) 2017 Hazen O'Malley. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  override func didMove(to view: SKView) {
    /* Setup your scene here */
  }

  let PAN_SLOWDOWN: CGFloat = 20.0
  
  func doPan(_ velocity: CGPoint) {
    camera?.run(SKAction.moveBy(x: -velocity.x/PAN_SLOWDOWN, y: velocity.y/PAN_SLOWDOWN, duration: 0.1))
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       /* Called when a touch begins */
        
        /*for touch in touches {
            //let location = touch.location(in: self)
          
            
          
            let sprite = SKSpriteNode(imageNamed:"SpaceshipUpRight")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            //sprite.position = location
            
            //let action = SKAction.rotate(byAngle: CGFloat(Double.pi), duration:1)
            
            //sprite.run(SKAction.repeatForever(action))
          
            self.addChild(sprite)
            //camera?.run(SKAction.move(to: location, duration: 1.0))
          } */
  }
   
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
  }
}
