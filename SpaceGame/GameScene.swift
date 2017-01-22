//
//  GameScene.swift
//  SpaceGame
//
//  Created by Zhihui Tang on 2017-01-22.
//  Copyright © 2017 Zhihui Tang. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var startfield: SKEmitterNode! {
        if let field = SKEmitterNode(fileNamed: "Starfield") {
            field.position = CGPoint(x: 0, y: 1472)
            field.advanceSimulationTime(10)
            field.zPosition = -1
            return field
        }
        return nil
    }
    
    var player: SKSpriteNode!

    var scoreLabel: SKLabelNode!
    /*
    var scoreLabel: SKLabelNode! {
        let label = SKLabelNode(text: "Score: 0")
        //label.position = CGPoint(x: -self.frame.size.width / 2, y: -self.frame.size.height / 2 + 60)
        label.position = CGPoint(x: -self.frame.size.width / 2 + label.frame.size.width, y: self.frame.height / 2 - label.frame.size.height * 2)
        label.fontName = "AmericanTypewriter-Bold"
        label.fontSize = 48
        label.fontColor = UIColor.white

        return label
    }
     */
    var score: Int = 0 {
        didSet {
            scoreLabel?.text = "Score: \(score)"
        }
    }
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    
    var possibleAliens = ["alien", "alien2", "alien3"]
    
    let alientCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory: UInt32 = 0x1 << 0

    var gameTimer: Timer!

    override func didMove(to view: SKView) {
        addChild(startfield)
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: 0, y: -self.frame.size.height/2 + player.size.height )
        
        addChild(player)
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        //label.position = CGPoint(x: -self.frame.size.width / 2, y: -self.frame.size.height / 2 + 60)
        scoreLabel.position = CGPoint(x: -self.frame.size.width / 2 + scoreLabel.frame.size.width, y: self.frame.height / 2 - scoreLabel.frame.size.height * 2)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = UIColor.white

        addChild(scoreLabel)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error?) in
            if let accelerometerData = data {
                let acceration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
    }
    
    func addAlien() {
    
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomAlienPosition = GKRandomDistribution(lowestValue: -Int(screenWidth) / 2, highestValue: Int(screenWidth) / 2)
        let position = CGFloat(randomAlienPosition.nextInt())
        alien.position = CGPoint(x: position, y: self.frame.size.height / 2 - alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alientCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        let animationDuration: TimeInterval = 6
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -self.frame.size.height / 2), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    private func fireTorpedo() {
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 6
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width/2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alientCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration: TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.height / 2 + 50), duration: animationDuration))

        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 &&
            (secondBody.categoryBitMask & alientCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    
    private func torpedoDidCollideWithAlien( torpedoNode: SKSpriteNode, alienNode: SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) { 
            explosion.removeFromParent()
        }
        
        score += 5
    }
    
    
    override func didSimulatePhysics() {
        player.position.x = player.position.x + xAcceleration * 50
        if player.position.x < -self.size.width / 2 - player.size.width / 2 {
            player.position = CGPoint(x: self.size.width / 2 - player.size.width / 2, y: player.position.y)
        }else if player.position.x > self.size.width / 2 + player.size.width / 2 {
            player.position = CGPoint(x: -self.size.width / 2 + player.size.width / 2, y: player.position.y)
        }
    }
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

extension GameScene {
    var screenWidth: CGFloat {
        get {
            return self.frame.size.width
        }
    }
    
    var screenHeight: CGFloat {
        get {
            return self.frame.size.height
        }
    }
}
