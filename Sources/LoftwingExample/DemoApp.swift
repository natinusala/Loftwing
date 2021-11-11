import TokamakCore
import OpenCombineShim
import Backtrace

final class SkylarkTarget: Target {
    var view: AnyView

    init<V: View>(_ view: V) {
        self.view = AnyView(view)
    }

    init() {
        self.view = AnyView(EmptyView())
    }
}

final class SkylarkRenderer: Renderer {
    private(set) var reconciler: StackReconciler<SkylarkRenderer>?
    var target = SkylarkTarget()

    init<V: View>(_ view: V) {
        self.reconciler = StackReconciler(
            view: view,
            target: self.target,
            environment: EnvironmentValues(),
            renderer: self
        ) { closure in
            closure()
        }
    }

    init<A: App>(
        _ app: A,
        _ rootEnvironment: EnvironmentValues? = nil
    ) {
        self.reconciler = StackReconciler(
            app: app,
            target: self.target,
            environment: EnvironmentValues(),
            renderer: self
        ) { closure in
            fatalError("Just what the heck is going on around here")
        }
    }

    func mountTarget(
        before sibling: SkylarkTarget?,
        to parent: SkylarkTarget,
        with host: MountedHost
    ) -> SkylarkTarget? {
        fatalError("mountTarget unimplemented")
    }

    func update(target: SkylarkTarget, with host: MountedHost) {
        fatalError("update unimplemented")
    }

    func unmount(
        target: SkylarkTarget,
        from parent: SkylarkTarget,
        with task: UnmountHostTask<SkylarkRenderer>
    ) {
        fatalError("unmount unimplemented")
    }

    func primitiveBody(for view: Any) -> AnyView? {
        fatalError("primitiveBody unimplemented")
    }

    func isPrimitiveView(_ type: Any.Type) -> Bool {
        return false
    }
}

extension App {
    static func _launch(_ app: Self, _ rootEnvironment: EnvironmentValues) {
        Backtrace.install()
        _ = Unmanaged.passRetained(SkylarkRenderer(app, rootEnvironment))
    }

    static func _setTitle(_ title: String) {
        print("Title set to \(title)")
    }

    var _phasePublisher: AnyPublisher<ScenePhase, Never> {
        CurrentValueSubject(.active).eraseToAnyPublisher()
    }

    var _colorSchemePublisher: AnyPublisher<ColorScheme, Never> {
        CurrentValueSubject(.light).eraseToAnyPublisher()
    }
}

extension WindowGroup: SceneDeferredToRenderer {
  public var deferredBody: AnyView {
    AnyView(content)
  }
}


@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup("Test Scene") {
            Text("Hello, world!")
        }
    }
}
