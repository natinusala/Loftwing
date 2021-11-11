import TokamakCore
import OpenCombineShim
import Backtrace
import Yoga
import Loftwing
import CLoftwing
import Async
import Foundation

protocol ViewImplConstructor {
    func impl() -> ViewImpl
}

class ViewImplBinding: Target {
    var view: AnyView
    var impl: ViewImpl?

    init<V: TokamakCore.View>(view: V, impl: ViewImpl) {
        self.view = AnyView(view)
        self.impl = impl
    }

    init() {
        self.view = AnyView(EmptyView())
    }

    func frame() {
        self.impl?.frame()
    }
}

class ViewImpl {
    open func frame() {
        
    }
}

// final class Widget: Target {
//     enum WidgetType {
//         case app
//         case widget
//     }

//     let type: WidgetType

//     let ygNode = YGNodeNew()
//     var children: [Widget] = []

//     var view: AnyView

//     init<V: View>(_ view: V) {
//         print("Initializing widget as view")
//         self.type = .widget
//         self.view = AnyView(view)
//     }

//     init() {
//         print("Initializing widget as app")
//         self.type = .app
//         self.view = AnyView(EmptyView())
//     }

//     func addChild(_ child: Widget, before: Widget?) {
//         var position = 0
//         if let before = before {
//             position = self.children.firstIndex { $0 === before }!
//         } else {
//             position = Int(YGNodeGetChildCount(self.ygNode))
//         }

//         print("Inserting node at position \(position)")

//         YGNodeInsertChild(self.ygNode, child.ygNode, UInt32(position))
//         self.children.insert(child, at: position)
//     }
// }

/// Runs everything in the main queue.
func drainMainQueue() {
    // XXX: Dispatch does not expose a way to drain the main queue
    // without parking the main thread, so we need to use obscure
    // CoreFoundation / Cocoa functions.
    // See https://github.com/apple/swift-corelibs-libdispatch/blob/macosforge/trac/ticket/38.md
    _dispatch_main_queue_callback_4CF(nil)
}

class TextImpl: ViewImpl {
    override func frame() {

    }
}

extension Text: ViewImplConstructor {
    func impl() -> ViewImpl {
        return TextImpl()
    }
}

final class SkylarkRenderer: Renderer {
    private(set) var reconciler: StackReconciler<SkylarkRenderer>?
    let appImpl = ViewImplBinding()

    init<A: App>(
        _ app: A,
        _ rootEnvironment: EnvironmentValues? = nil
    ) {
        self.reconciler = StackReconciler(
            app: app,
            target: self.appImpl, // top-level app target
            environment: .defaultEnvironment,
            renderer: self
        ) { closure in
            Async.main {
                print("Running reconcilier")
                closure()
            }
        }
    }

    func run() {
        while true {
            self.appImpl.frame()
            Thread.sleep(forTimeInterval: 0.016666666)

            drainMainQueue()
        }
    }

    func mountTarget(
        before sibling: ViewImplBinding?,
        to parent: ViewImplBinding,
        with host: MountedHost
    ) -> ViewImplBinding? {
        print("Mounting \(host.view.Type.self)")

        // Get the constructor associated with target to mount
        guard let ctor = mapAnyView(
            host.view,
            transform: { (widget: ViewImplConstructor) in widget }
        ) else {
            // handle cases like `TupleView`
            if mapAnyView(host.view, transform: { (view: ParentView) in view }) != nil {
                return parent
            }

            print("Did not find any Widget implementation, not mounting")
            return nil
        }

        // Construct the view impl
        let impl = ctor.impl()

        if parent === self.appImpl {
            // If the parent is the app, just set the view
            print("Setting top-level view to \(host.view)")
            appImpl.impl = impl
        }
        else {
            // Otherwise take parent widget and add child widget before
            // specified widget
            fatalError("Adding views to parents is not implemented")
        }

        return ViewImplBinding(view: host.view, impl: impl)
    }

    func update(target: ViewImplBinding, with host: MountedHost) {
        fatalError("update unimplemented")
    }

    func unmount(
        target: ViewImplBinding,
        from parent: ViewImplBinding,
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

protocol App: TokamakCore.App {
    var windowMode: WindowMode { get }
}

extension App {
    var windowMode: WindowMode {
        .windowed(1280, 720)
    }
}

class InternalApp {
    init<A: App>(from app: A) {
        // Init platform
        print("Making a window with mode \(app.windowMode)")
    }

    func setTitle(_ title: String) {
        print("Title set to \(title)")
    }
}

var sharedApp: InternalApp?

extension App {
    static func _launch(_ app: Self, _ rootEnvironment: EnvironmentValues) {
        let renderer = SkylarkRenderer(app, rootEnvironment)
        _ = Unmanaged.passRetained(renderer)
        renderer.run()
    }

    static func _setTitle(_ title: String) {
        sharedApp?.setTitle(title)
    }

    var _phasePublisher: AnyPublisher<ScenePhase, Never> {
        CurrentValueSubject(.active).eraseToAnyPublisher()
    }

    var _colorSchemePublisher: AnyPublisher<ColorScheme, Never> {
        CurrentValueSubject(.dark).eraseToAnyPublisher()
    }

    public static func main() {
        let app = Self()
        sharedApp = InternalApp(from: app)
        _launch(app, EnvironmentValues())
    }
}

extension WindowGroup: SceneDeferredToRenderer {
    // Wrapper around actual content
    public var deferredBody: AnyView {
        AnyView(content)
    }
}

extension EnvironmentValues {
    static var defaultEnvironment: Self {
        var environment = EnvironmentValues()
        environment[_ColorSchemeKey.self] = .dark

        return environment
    }
}

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("Test Scene") {
            Text("Hello, world!")
        }
    }
}

DemoApp.main()
