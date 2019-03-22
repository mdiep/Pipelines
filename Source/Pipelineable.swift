import ReactiveSwift
import Result

enum Either<Left, Right> {
	case left(Left)
	case right(Right)
}

typealias Executor = (String, Input) -> SignalProducer<Output, NSError>

protocol Pipelineable {
	associatedtype Input
	associatedtype Output

	func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput>

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput>

	func select<A, B>(_: Pipeline<A, B>) -> Pipeline<Input, B> where Output == Either<A, B>

	func run(_ input: Input) -> SignalProducer<Output, NSError>

	func run(_ input: Input, execute: @escaping Executor) -> SignalProducer<Output, NSError>
}

extension Pipelineable {
	func select<A, B>(_ command: Command<A, B>) -> Pipeline<Input, B> where Output == Either<A, B> {
		return select(Pipeline(command))
	}
}
