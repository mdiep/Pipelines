import ReactiveSwift

typealias Executor = (String, Input) -> SignalProducer<Output, NSError>

protocol Pipelineable {
	associatedtype Input
	associatedtype Output

	func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput>

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput>

	func run(_ input: Input) -> SignalProducer<Output, NSError>

	func run(_ input: Input, execute: @escaping Executor) -> SignalProducer<Output, NSError> 
}
