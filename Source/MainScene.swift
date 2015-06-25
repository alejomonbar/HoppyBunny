import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate{
    
    weak var hero: CCSprite!
    weak var gamePhysicsNode : CCPhysicsNode!
    
    var sinceTouch : CCTime = 0
    var scrollSpeed : CGFloat = 80
    
    weak var ground1: CCSprite!
    weak var ground2: CCSprite!
    var grounds = [CCSprite]() //initializes an empty array
    
    var obstacles : [CCNode] = []
    let firstObstaclePosition : CGFloat = 280
    let distanceBetweenObstacles : CGFloat = 160
    
    weak var obstaclesLayer : CCNode!
    
    weak var restartButton : CCButton!
    
    var gameOver = false
    
    var points : NSInteger = 0
    weak var scoreLabel : CCLabelTTF!
    
    func didLoadFromCCB() {
        
        gamePhysicsNode.collisionDelegate = self
        
        userInteractionEnabled = true
        grounds.append(ground1)
        grounds.append(ground2)
        
        for i in 0...2{
            spawnNewObstacle()
        }
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        if gameOver == false {
            hero.physicsBody.applyImpulse(ccp(0, 400))
            hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    
    override func update(delta: CCTime) {
        
        let velocityY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        hero.physicsBody.velocity = ccp(0, CGFloat(velocityY))
        
        sinceTouch += delta
        hero.rotation = clampf(hero.rotation, -30, 90)
        
        if (hero.physicsBody.allowsRotation) {
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1)
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        if (sinceTouch > 0.3) {
            let impulse = -18000.0 * delta
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        //Defining a member variable for the scroll speed rather than simply defining the hero's position to be increased by 80 * delta every time is an important programming practice
        
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y)
        
        gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - (scrollSpeed * CGFloat(delta)), gamePhysicsNode.position.y)
        
        //gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x),round(gamePhysicsNode.position.y))
        let scale = CCDirector.sharedDirector().contentScaleFactor
        gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x * scale) / scale, round(gamePhysicsNode.position.y * scale) / scale)
        hero.position = ccp(round(hero.position.x * scale) / scale, round(hero.position.y * scale) / scale)
        
        // loop the ground wherever a ground imagen was moved entirely or outside the screen
        
        for ground in grounds {
            
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
            
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        for obstacle in obstacles.reverse() {
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            
            // obstacle moved past left side of screen?
            if obstacleScreenPosition.x < (-obstacle.contentSize.width) {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                
                // for each removed obstacle, add a new one
                spawnNewObstacle()
            }
        }
    }
    
    func spawnNewObstacle(){
        var prevObstaclePos = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePos = obstacles.last!.position.x
        }
        
        //Create and add a new obstacle
        
        let obstacle = CCBReader.load("Obstacle") as! Obstacle
        obstacle.position = ccp(prevObstaclePos + distanceBetweenObstacles, 0)
        obstacle.setupRandomPosition()
        obstaclesLayer.addChild(obstacle)
        obstacles.append(obstacle)
    }

    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        
        triggerGameOver()
        return true
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero nodeA: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        scoreLabel.string = String(points)
        return true
    }
    
    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().presentScene(scene)
    }
    
    func triggerGameOver() {
        if (gameOver == false) {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            // just in case
            hero.stopAllActions()
            
            let move = CCActionEaseBounceOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array: [move, moveBack])
            runAction(shakeSequence)
        }
    }
    
}


