import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var gameState: MastermindGameState
    @Binding var instructionVisibility: Bool // Binding to control instruction visibility
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        setupPlaceholderBoard(arView) // Setup placeholder initially
        setupGestureRecognizers(arView, context: context)
        context.coordinator.setScene(arView: arView, anchorEntity: arView.scene.anchors.first as! AnchorEntity)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        updateGameState(uiView)
    }
    
    private func updateGameState(_ arView: ARView) {
        // Update visual state of the game board based on gameState
        let anchor = arView.scene.anchors.first as? AnchorEntity
        updateGuessSlots(anchor)
        updateFeedbackArea(anchor)
        updateSecretCodeSlots(anchor) // Update secret code slots
    }
    
    // MARK: - Placeholder Board Setup
    private func setupPlaceholderBoard(_ arView: ARView) {
        let anchor = AnchorEntity(plane: .horizontal)
        
        // Placeholder board
        let placeholderEntity = createPlaceholderBoardEntity()
        anchor.addChild(placeholderEntity)
        
        arView.scene.addAnchor(anchor)
    }
    
    private func createPlaceholderBoardEntity() -> ModelEntity {
        let boardMesh = MeshResource.generateBox(size: [0.5, 0.02, 0.9])
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor.lightGray.withAlphaComponent(0.5)) // Semi-transparent light gray
        let placeholderEntity = ModelEntity(mesh: boardMesh, materials: [material])
        placeholderEntity.name = "placeholderBoard" 
        placeholderEntity.generateCollisionShapes(recursive: true) // Add collision shape for tap interaction
        return placeholderEntity
    }
    
    private func removePlaceholderBoard(_ arView: ARView) {
        // Find and remove the placeholder board entity
        if let anchor = arView.scene.anchors.first { // Assuming the placeholder is anchored to the first anchor
            for entity in anchor.children {
                if entity.name == "placeholderBoard" { 
                    entity.removeFromParent()
                    return // Exit after removing the first placeholder found
                }
            }
        }
    }
    
    // MARK: - Original Game Board Setup
    private func setupGameBoard(_ arView: ARView, arViewContainer: ARViewContainer) {
        guard let anchor = arView.scene.anchors.first as? AnchorEntity else {
            print("Error: Anchor not found when setting up game board.")
            return // Exit if anchor is not found
        }
        
        // Main board
        let boardEntity = createBoard()
        anchor.addChild(boardEntity)
        
        
        setupSecretCodeSlots(anchor)
        
        // Color selection pegs
        setupColorPegs(anchor)
        
        // Guess slots
        setupGuessSlots(anchor)
        
        // Feedback area
        setupFeedbackArea(anchor)
    }
    
    
    private func createBoard() -> ModelEntity {
        let boardMesh = MeshResource.generateBox(size: [0.5, 0.02, 0.9])
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(white:0.5, alpha: 1.0)) // grey
        return ModelEntity(mesh: boardMesh, materials: [material])
    }
    
    private func setupColorPegs(_ anchor: AnchorEntity) {
        for (index, color) in MastermindGameState.Color.allCases.enumerated() {
            let pegMesh = MeshResource.generateSphere(radius: 0.02)
            var material = SimpleMaterial()
            material.color = .init(tint: color.uiColor)
            let peg = ModelEntity(mesh: pegMesh, materials: [material])
            
            let x = Float(index) * 0.08 - 0.2
            peg.position = [x, 0.02, 0.25]
            peg.generateCollisionShapes(recursive: true)
            
            let colorPegComponent = ColorPegComponent(color: color)
            peg.components[ColorPegComponent.self] = colorPegComponent
            
            anchor.addChild(peg)
        }
    }
    
    private func setupSecretCodeSlots(_ anchor: AnchorEntity) {
        for col in 0..<4 {
            let slotMesh = MeshResource.generateBox(size: [0.04, 0.01, 0.04])
            var material = SimpleMaterial()
            material.color = .init(tint: .darkGray) // Hidden color initially
            
            let slot = ModelEntity(mesh: slotMesh, materials: [material])
            let x = Float(col) * 0.06 - 0.09
            let z: Float = 0.38 
            
            slot.position = [x, 0.015, z]
            
            let secretCodeSlotComponent = SecretCodeSlotComponent(column: col) // New component
            slot.components[SecretCodeSlotComponent.self] = secretCodeSlotComponent
            
            anchor.addChild(slot)
        }
    }
    
    
    private func setupGuessSlots(_ anchor: AnchorEntity) {
        for row in 0..<10 {
            for col in 0..<4 {
                let slotMesh = MeshResource.generateBox(size: [0.04, 0.01, 0.04])
                var material = SimpleMaterial()
                material.color = .init(tint: .darkGray) // Default color for all slots
                
                let slot = ModelEntity(mesh: slotMesh, materials: [material])
                let x = Float(col) * 0.06 - 0.09
                let z = Float(row) * -0.06 + 0.15 // Adjusted Z to be below secret code - ADJUSTED VALUE
                slot.position = [x, 0.015, z]
                
                let slotComponent = GuessSlotComponent(row: row, column: col)
                slot.components[GuessSlotComponent.self] = slotComponent
                
                anchor.addChild(slot)
            }
        }
    }
    
    
    private func setupFeedbackArea(_ anchor: AnchorEntity) {
        for row in 0..<10 {
            for i in 0..<2 {
                for j in 0..<2 {
                    let feedbackMesh = MeshResource.generateSphere(radius: 0.008)
                    var material = SimpleMaterial()
                    material.color = .init(tint: .lightGray)
                    
                    let feedbackPeg = ModelEntity(mesh: feedbackMesh, materials: [material])
                    let x = Float(i) * 0.02 + 0.15
                    let z = Float(j) * 0.02 + Float(row) * -0.06 + 0.15 // Adjusted Z to match guess rows - ADJUSTED VALUE
                    feedbackPeg.position = [x, 0.015, z]
                    
                    let feedbackComponent = FeedbackPegComponent(row: row, index: i * 2 + j)
                    feedbackPeg.components[FeedbackPegComponent.self] = feedbackComponent
                    
                    anchor.addChild(feedbackPeg)
                }
            }
        }
    }
    
    private func updateGuessSlots(_ anchor: AnchorEntity?) {
        guard let anchor = anchor else { return }
        
        for entity in anchor.children {
            if let slot = entity.components[GuessSlotComponent.self] {
                // Corrected Material Access: Ensure we're working with a ModelEntity and a SimpleMaterial.
                if let modelEntity = entity as? ModelEntity,
                   let originalMaterial = modelEntity.model?.materials.first as? SimpleMaterial {
                    
                    // Create a mutable copy of the material
                    var material = originalMaterial
                    var slotColor = gameState.guesses[slot.row][slot.column]?.uiColor ?? .darkGray
                    
                    // Highlight current row's empty slots
                    if slot.row == gameState.currentRow && gameState.guesses[slot.row][slot.column] == nil {
                        slotColor = UIColor.lightGray.withAlphaComponent(0.5) // Lighter grey with some transparency
                    } else if gameState.guesses[slot.row][slot.column] == nil {
                        slotColor = .darkGray // Default dark grey for non-current empty slots
                    } else {
                        slotColor = gameState.guesses[slot.row][slot.column]!.uiColor // Use guess color if set
                    }
                    
                    
                    material.baseColor = MaterialColorParameter.color(UIColor(cgColor: slotColor.cgColor))
                    modelEntity.model?.materials = [material]  // Replace existing material
                }
            }
        }
    }
    
    private func updateFeedbackArea(_ anchor: AnchorEntity?) {
        guard let anchor = anchor else { return }
        
        for entity in anchor.children {
            if let feedbackPeg = entity.components[FeedbackPegComponent.self] {
                if let modelEntity = entity as? ModelEntity,
                   let originalMaterial = modelEntity.model?.materials.first as? SimpleMaterial {
                    
                    var material = originalMaterial
                    
                    let feedback = gameState.feedback[feedbackPeg.row]
                    let color = feedbackPeg.index < feedback.count ? feedback[feedbackPeg.index].color : .lightGray
                    material.baseColor = MaterialColorParameter.color(UIColor(cgColor: color.cgColor))
                    
                    modelEntity.model?.materials = [material]
                }
            }
        }
    }
    
    private func updateSecretCodeSlots(_ anchor: AnchorEntity?) {
        guard let anchor = anchor else { return }
        
        for entity in anchor.children {
            if let secretCodeSlot = entity.components[SecretCodeSlotComponent.self] {
                if let modelEntity = entity as? ModelEntity,
                   let originalMaterial = modelEntity.model?.materials.first as? SimpleMaterial {
                    
                    var material = originalMaterial
                    
                    if gameState.isSecretCodeRevealed {
                        // Reveal the secret code
                        let secretColor = gameState.secretCode[secretCodeSlot.column].uiColor
                        material.baseColor = MaterialColorParameter.color(UIColor(cgColor: secretColor.cgColor))
                    } else {
                        // Keep hidden (dark gray)
                        material.baseColor = MaterialColorParameter.color(UIColor(cgColor: UIColor.darkGray.cgColor))
                    }
                    modelEntity.model?.materials = [material]
                }
            }
        }
    }
    
    
    private func setupGestureRecognizers(_ arView: ARView, context: Context) {
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
    }
    
    func makeCoordinator() -> Coordinator {
        // Pass a reference to ARViewContainer to the Coordinator
        Coordinator(gameState: gameState, arViewContainer: self, instructionVisibility: _instructionVisibility) // Pass binding to Coordinator
    }
    
    class Coordinator: NSObject {
        var gameState: MastermindGameState
        var arView: ARView?
        var anchorEntity: AnchorEntity?
        var arViewContainer: ARViewContainer?
        @Binding var instructionVisibility: Bool // Binding in Coordinator
        
        init(gameState: MastermindGameState, arViewContainer: ARViewContainer, instructionVisibility: Binding<Bool>) { // Initialize binding in Coordinator
            self.gameState = gameState
            self.arViewContainer = arViewContainer
            _instructionVisibility = instructionVisibility // Initialize binding
        }
        
        func setScene(arView: ARView, anchorEntity: AnchorEntity) {
            self.arView = arView
            self.anchorEntity = anchorEntity
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)
            
            if let entity = arView.entity(at: location) as? ModelEntity {
                if entity.name == "placeholderBoard" { // Check if tapped entity is the placeholder
                    handlePlaceholderTap(entity: entity)
                }
                else if let colorPeg = entity.components[ColorPegComponent.self] {
                    handleColorSelection(colorPeg.color, tappedEntity: entity)
                } else if let _ = entity.components[GuessSlotComponent.self] {
                    // handleGuessSlotSelection(guessSlot) // Removed - not needed in this flow
                }
            }
        }
        
        private func handlePlaceholderTap(entity: Entity) {
            guard let arView = self.arView, let arViewContainer = self.arViewContainer else { return }
            arViewContainer.removePlaceholderBoard(arView)
            arViewContainer.setupGameBoard(arView, arViewContainer: arViewContainer)
            instructionVisibility = false // Hide instruction visually
            gameState.hasInstructionBeenShown = true // Mark instruction as shown in game state
            gameState.startGameTimer()
        }
        
        
        private func handleColorSelection(_ color: MastermindGameState.Color, tappedEntity: Entity) {
            gameState.selectedColor = color
            
            
            guard let (row, col) = gameState.getNextAvailableSlot() else {
                gameState.message = "No available slots in this row!"
                gameState.messageOpacity = 1.0 // Fade message in
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Stay for 2 seconds, then fade out
                    withAnimation(.easeInOut(duration: 0.5)) { // Fade out animation
                        self.gameState.messageOpacity = 0.0 // Fade message out
                    }
                }
                return
            }
            
            animatePegToSlot(color: color, row: row, col: col, tappedEntity: tappedEntity)
        }
        
        func animatePegToSlot(color: MastermindGameState.Color, row: Int, col: Int, tappedEntity: Entity) {
            guard let arView = self.arView, let anchorEntity = self.anchorEntity, let arViewContainer = self.arViewContainer else { return } // Safely unwrap arViewContainer
            
            // 1. Find the target slot entity
            var targetPosition: SIMD3<Float>?
            for entity in anchorEntity.children {
                if let slot = entity.components[GuessSlotComponent.self], slot.row == row, slot.column == col {
                    targetPosition = entity.position
                    break
                }
            }
            
            guard let targetPos = targetPosition else {
                print("Target position not found")
                return
            }
            
            gameState.animatingPeg = (row: row, column: col)
            
            // 2. Create a copy of the tapped peg to animate
            let animatedPeg = tappedEntity.clone(recursive: true)
            animatedPeg.name = "AnimatingPeg"
            anchorEntity.addChild(animatedPeg)
            
            // 3. Animate the peg to the target position
            var transform = animatedPeg.transform
            transform.translation = targetPos
            
            animatedPeg.move(to: transform, relativeTo: anchorEntity, duration: 0.5, timingFunction: .easeInOut)
            
            // 4. After animation, update the model AND gameState.guesses and THEN update visuals
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animatedPeg.removeFromParent()
                self.gameState.animatingPeg = nil
                
                // *IMPORTANT CHANGE*: Update gameState.guesses HERE, AFTER animation
                self.gameState.guesses[row][col] = color
                
                // 5. Update visuals (now call the methods on arViewContainer instance)
                arViewContainer.updateGuessSlots(anchorEntity) // Call on arViewContainer
                arViewContainer.updateFeedbackArea(anchorEntity) // Call on arViewContainer
                arViewContainer.updateSecretCodeSlots(anchorEntity) // Update secret code slots as well
            }
        }
    }
}
