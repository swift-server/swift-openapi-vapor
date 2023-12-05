import Vapor

extension PathComponent: Equatable {
    public static func == (lhs: PathComponent, rhs: PathComponent) -> Bool {
        switch (lhs, rhs) {
        case (.constant(let lhs), .constant(let rhs)):
            return lhs == rhs
        case (.parameter(let lhs), .parameter(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}