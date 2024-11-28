import Dependencies
import Vapor

extension DependencyValues {
  private enum RequestKey: DependencyKey {
    static var liveValue: Request {
      fatalError("Value of type \(Value.self) is not registered in this context")
    }
  }
}
