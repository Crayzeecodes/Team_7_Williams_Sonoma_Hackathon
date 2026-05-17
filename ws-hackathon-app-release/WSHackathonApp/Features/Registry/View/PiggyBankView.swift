//
//  PiggyBankView.swift
//  WSHackathonApp
//

import SwiftUI
import SpriteKit

struct CoinJarView: View {
    let budgetSnapshot: RegistryBudgetSnapshot
    let currencySymbol: String
    let trigger: Int

    @State private var scene = CoinJarScene()
    @State private var previousRemaining: Double = -1

    var body: some View {
        VStack(spacing: 14) {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            
            Text("\(currencySymbol)\(Int(budgetSnapshot.remainingAmount)) of \(currencySymbol)\(Int(budgetSnapshot.totalBudget)) remaining")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.primary)

            if budgetSnapshot.remainingAmount == 0 && budgetSnapshot.totalBudget > 0 {
                Text("Budget reached")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.blue) // AppColors.accent equivalent
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .onAppear {
            previousRemaining = budgetSnapshot.remainingAmount
        }
        .onChange(of: budgetSnapshot.remainingAmount) { oldValue, newValue in
            // Handle add/spend logic dynamically
            let diff = oldValue - newValue
            if diff > 0 {
                // Remaining amount decreased -> we added money towards the goal
                scene.addMoney(count: 3) // Add a few coins per transaction for visual effect
            } else if diff < 0 {
                // Remaining amount increased -> we spent money or refunded
                scene.spendMoney(count: 3)
            }
            previousRemaining = newValue
        }
        .onChange(of: trigger) { _, _ in
            scene.addMoney(count: 5)
        }
    }
}

// Aliasing PiggyBankView to CoinJarView so we don't break RegistryDetailView
typealias PiggyBankView = CoinJarView

class CoinJarScene: SKScene {
    private var coins: [SKShapeNode] = []
    private var isJarSetup = false
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !isJarSetup && size.width > 0 && size.height > 0 {
            setupJar()
            isJarSetup = true
        }
    }
    
    func setupJar() {
        let w = size.width
        let h = size.height
        
        let jarWidth = w * 0.7
        let jarHeight = h * 0.65
        let jarY = h * 0.05
        let jarX = (w - jarWidth) / 2
        
        let neckWidth = jarWidth * 0.5
        let neckHeight = h * 0.1
        let neckX = (w - neckWidth) / 2
        let neckY = jarY + jarHeight
        
        let lidHeight: CGFloat = 8
        let lidY = neckY + neckHeight
        
        let path = CGMutablePath()
        let r: CGFloat = 16
        
        // Inner Loop for Physics bounds
        path.move(to: CGPoint(x: neckX, y: lidY))
        path.addLine(to: CGPoint(x: neckX, y: neckY))
        
        path.addLine(to: CGPoint(x: jarX + r, y: neckY))
        path.addArc(tangent1End: CGPoint(x: jarX, y: neckY), 
                    tangent2End: CGPoint(x: jarX, y: neckY - r), radius: r)
        
        path.addLine(to: CGPoint(x: jarX, y: jarY + r))
        path.addArc(tangent1End: CGPoint(x: jarX, y: jarY), 
                    tangent2End: CGPoint(x: jarX + r, y: jarY), radius: r)
        
        path.addLine(to: CGPoint(x: jarX + jarWidth - r, y: jarY))
        path.addArc(tangent1End: CGPoint(x: jarX + jarWidth, y: jarY), 
                    tangent2End: CGPoint(x: jarX + jarWidth, y: jarY + r), radius: r)
        
        path.addLine(to: CGPoint(x: jarX + jarWidth, y: neckY - r))
        path.addArc(tangent1End: CGPoint(x: jarX + jarWidth, y: neckY), 
                    tangent2End: CGPoint(x: jarX + jarWidth - r, y: neckY), radius: r)
        
        path.addLine(to: CGPoint(x: neckX + neckWidth, y: neckY))
        path.addLine(to: CGPoint(x: neckX + neckWidth, y: lidY))
        
        path.closeSubpath()
        
        let jarNode = SKShapeNode(path: path)
        jarNode.strokeColor = SKColor.gray.withAlphaComponent(0.6)
        jarNode.lineWidth = 4
        jarNode.fillColor = SKColor.cyan.withAlphaComponent(0.1)
        
        // Draw the Lid
        let lidPath = CGMutablePath()
        lidPath.addRoundedRect(in: CGRect(x: neckX - 4, y: lidY, width: neckWidth + 8, height: lidHeight), cornerWidth: 3, cornerHeight: 3)
        let lidNode = SKShapeNode(path: lidPath)
        lidNode.fillColor = SKColor.darkGray
        lidNode.strokeColor = .clear
        
        // Draw the Knob
        let knobPath = CGMutablePath()
        knobPath.addRoundedRect(in: CGRect(x: w / 2 - 12, y: lidY + lidHeight, width: 24, height: 8), cornerWidth: 3, cornerHeight: 3)
        let knobNode = SKShapeNode(path: knobPath)
        knobNode.fillColor = SKColor.gray
        knobNode.strokeColor = .clear
        
        jarNode.addChild(lidNode)
        jarNode.addChild(knobNode)
        
        jarNode.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        
        addChild(jarNode)
    }
    
    func addMoney(count: Int) {
        guard isJarSetup else { return }
        
        var actions: [SKAction] = []
        for _ in 0..<count {
            let spawn = SKAction.run { [weak self] in
                self?.spawnCoin()
            }
            let wait = SKAction.wait(forDuration: 0.09)
            actions.append(spawn)
            actions.append(wait)
        }
        run(SKAction.sequence(actions))
    }
    
    private func spawnCoin() {
        let r: CGFloat = 8
        let coin = SKShapeNode(circleOfRadius: r)
        coin.fillColor = SKColor(red: 0.95, green: 0.75, blue: 0.2, alpha: 1.0)
        coin.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.1, alpha: 1.0)
        coin.lineWidth = 1.5
        
        let lidY = (size.height * 0.05) + (size.height * 0.65) + (size.height * 0.1)
        coin.position = CGPoint(x: size.width / 2, y: lidY - r - 2)
        
        coin.physicsBody = SKPhysicsBody(circleOfRadius: r)
        coin.physicsBody?.restitution = 0.4
        coin.physicsBody?.friction = 0.6
        coin.physicsBody?.linearDamping = 0.3
        
        addChild(coin)
        coins.append(coin)
        
        let dx = CGFloat.random(in: -30...30)
        coin.physicsBody?.applyImpulse(CGVector(dx: dx, dy: -2))
    }
    
    func spendMoney(count: Int) {
        guard isJarSetup else { return }
        
        var removed = 0
        while removed < count && !coins.isEmpty {
            if let topmost = coins.max(by: { $0.position.y < $1.position.y }) {
                coins.removeAll(where: { $0 == topmost })
                
                topmost.physicsBody?.collisionBitMask = 0 // Allow passing through jar walls
                let dx = CGFloat.random(in: -80...80)
                topmost.physicsBody?.applyImpulse(CGVector(dx: dx, dy: 300))
                
                let checkExit = SKAction.customAction(withDuration: 1.0) { node, _ in
                    if node.position.y > self.size.height || node.position.x < -20 || node.position.x > self.size.width + 20 {
                        node.removeFromParent()
                    }
                }
                topmost.run(SKAction.sequence([checkExit, SKAction.removeFromParent()]))
                removed += 1
            }
        }
    }
}
