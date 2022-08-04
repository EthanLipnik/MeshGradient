
import Foundation
import MetalKit
@_implementationOnly import MeshGradientCHeaders

public enum MeshGradientDefaults {
	public static let grainAlpha: Float = 0.05
	public static let subdivisions: Int = 18
}

private enum MeshGradientState {
	case animated(initial: Grid<ControlPoint>, animatorConfiguration: MeshAnimator.Configuration)
	case `static`(grid: Grid<ControlPoint>)
}

#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit

public struct MeshView: UIViewRepresentable {
	
	private let state: MeshGradientState
	private let subdivisions: Int
    private let grainAlpha: Float
	
	public init(initialGrid: Grid<ControlPoint>,
				animatorConfiguration: MeshAnimator.Configuration,
				grainAlpha: Float = MeshGradientDefaults.grainAlpha,
				subdivisions: Int = MeshGradientDefaults.subdivisions) {
		self.state = .animated(initial: initialGrid, animatorConfiguration: animatorConfiguration)
        self.grainAlpha = grainAlpha
		self.subdivisions = subdivisions
	}
	
	public init(grid: Grid<ControlPoint>,
				grainAlpha: Float = MeshGradientDefaults.grainAlpha,
				subdivisions: Int = MeshGradientDefaults.subdivisions) {
		self.state = .static(grid: grid)
		self.grainAlpha = grainAlpha
		self.subdivisions = subdivisions
	}
	
	public func makeUIView(context: Context) -> MTKView {
		let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        let dataProvider = createDataProvider()
        context.coordinator.renderer = .init(metalKitView: view, meshDataProvider: dataProvider, grainAlpha: grainAlpha, subdivisions: subdivisions)
		
		switch state {
		case .animated:
			view.isPaused = false
			view.enableSetNeedsDisplay = false
		case .static:
			view.isPaused = true
			view.enableSetNeedsDisplay = true
		}
		
		view.delegate = context.coordinator.renderer
        view.preferredFramesPerSecond = (dataProvider as? MeshAnimator)?.configuration.framesPerSecond ?? 60
		return view
	}
	
	private func createDataProvider() -> MeshDataProvider {
		switch state {
		case .animated(let initial, let animatorConfiguration):
			return MeshAnimator(grid: initial, configuration: animatorConfiguration)
		case .static(let grid):
			return StaticMeshDataProvider(grid: grid)
		}
	}
	
	public func updateUIView(_ view: MTKView, context: Context) {
		switch state {
		case .animated(_, let animatorConfiguration):
			guard let animator = context.coordinator.renderer.meshDataProvider as? MeshAnimator else {
				fatalError("Incorrect mesh data provider type. Expected \(MeshAnimator.self), got \(type(of: context.coordinator.renderer.meshDataProvider))")
			}
			animator.configuration = animatorConfiguration
			animator.configuration.framesPerSecond = min(animatorConfiguration.framesPerSecond, view.preferredFramesPerSecond)
            view.preferredFramesPerSecond = animator.configuration.framesPerSecond
		case .static(let grid):
			guard let staticMesh = context.coordinator.renderer.meshDataProvider as? StaticMeshDataProvider else {
				fatalError("Incorrect mesh data provider type. Expected \(StaticMeshDataProvider.self), got \(type(of: context.coordinator.renderer.meshDataProvider))")
			}
			staticMesh.grid = grid
			view.setNeedsDisplay()
            view.preferredFramesPerSecond = 60
		}
		context.coordinator.renderer.mtkView(view, drawableSizeWillChange: view.drawableSize)
		context.coordinator.renderer.subdivisions = subdivisions
        context.coordinator.renderer.grainAlpha = grainAlpha
	}
	
	public func makeCoordinator() -> Coordinator {
		return .init()
	}
	
	public final class Coordinator {
		var renderer: MetalMeshRenderer!
	}
	
}

#elseif canImport(AppKit) // canImport(UIKit)

import AppKit

public struct MeshView: NSViewRepresentable {
	
	private let state: MeshGradientState
	private let subdivisions: Int
	private let grainAlpha: Float
	
	public init(initialGrid: Grid<ControlPoint>,
				animatorConfiguration: MeshAnimator.Configuration,
				grainAlpha: Float = MeshGradientDefaults.grainAlpha,
				subdivisions: Int = MeshGradientDefaults.subdivisions) {
		self.state = .animated(initial: initialGrid, animatorConfiguration: animatorConfiguration)
		self.grainAlpha = grainAlpha
		self.subdivisions = subdivisions
	}
	
	public init(grid: Grid<ControlPoint>,
				grainAlpha: Float = MeshGradientDefaults.grainAlpha,
				subdivisions: Int = MeshGradientDefaults.subdivisions) {
		self.state = .static(grid: grid)
		self.grainAlpha = grainAlpha
		self.subdivisions = subdivisions
	}
	
	public func makeNSView(context: Context) -> MTKView {
		let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        let dataProvider = createDataProvider()
		context.coordinator.renderer = .init(metalKitView: view, meshDataProvider: dataProvider, grainAlpha: grainAlpha, subdivisions: subdivisions)
		
		switch state {
		case .animated:
			view.isPaused = false
			view.enableSetNeedsDisplay = false
		case .static:
			view.isPaused = true
			view.enableSetNeedsDisplay = true
		}
		
		view.delegate = context.coordinator.renderer
        view.preferredFramesPerSecond = (dataProvider as? MeshAnimator)?.configuration.framesPerSecond ?? 60
		return view
	}
	
	private func createDataProvider() -> MeshDataProvider {
		switch state {
		case .animated(let initial, let animatorConfiguration):
			return MeshAnimator(grid: initial, configuration: animatorConfiguration)
		case .static(let grid):
			return StaticMeshDataProvider(grid: grid)
		}
	}
	
	public func updateNSView(_ view: MTKView, context: Context) {
		switch state {
		case .animated(_, let animatorConfiguration):
			guard let animator = context.coordinator.renderer.meshDataProvider as? MeshAnimator else {
				fatalError("Incorrect mesh data provider type. Expected \(MeshAnimator.self), got \(type(of: context.coordinator.renderer.meshDataProvider))")
			}
			animator.configuration = animatorConfiguration
			animator.configuration.framesPerSecond = min(animatorConfiguration.framesPerSecond, view.preferredFramesPerSecond)
            view.preferredFramesPerSecond = animator.configuration.framesPerSecond
		case .static(let grid):
			guard let staticMesh = context.coordinator.renderer.meshDataProvider as? StaticMeshDataProvider else {
				fatalError("Incorrect mesh data provider type. Expected \(StaticMeshDataProvider.self), got \(type(of: context.coordinator.renderer.meshDataProvider))")
			}
			staticMesh.grid = grid
			view.setNeedsDisplay(view.bounds)
            view.preferredFramesPerSecond = 60
		}
		context.coordinator.renderer.mtkView(view, drawableSizeWillChange: view.drawableSize)
		context.coordinator.renderer.subdivisions = subdivisions
        context.coordinator.renderer.grainAlpha = grainAlpha
	}
	
	public func makeCoordinator() -> Coordinator {
		return .init()
	}
	
	public final class Coordinator {
		var renderer: MetalMeshRenderer!
	}
	
}
#endif // canImport(AppKit)

#endif // canImport(SwiftUI)
