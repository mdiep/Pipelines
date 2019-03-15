import Foundation
import ReactiveSwift
import Result

struct Input {
	var arguments: [String]
}

struct Output {
	var exitCode: Int
	var stderr: Data
	var stdout: Data
}

struct Command<Input, Output> {
	let executable: String
	let serialize: (Input) -> Pipelines.Input
	let deserialize: (Pipelines.Output) -> Output

	init(
		executable: String,
		serialize: @escaping (Input) -> Pipelines.Input,
		deserialize: @escaping (Pipelines.Output) -> Output
	) {
		self.executable = executable
		self.serialize = serialize
		self.deserialize = deserialize
	}
}

extension Command {
	func mapInput<Value>(_ transform: @escaping (Value) -> Input) -> Command<Value, Output> {
		return Command<Value, Output>(
			executable: executable,
			serialize: { [serialize = self.serialize] in serialize(transform($0)) },
			deserialize: deserialize
		)
	}

	func mapOutput<Value>(_ transform: @escaping (Output) -> Value) -> Command<Input, Value> {
		return Command<Input, Value>(
			executable: executable,
			serialize: serialize,
			deserialize: { [deserialize = self.deserialize] in transform(deserialize($0)) }
		)
	}
}

extension Command {
    func run(_ input: Input, executor: Executor) -> SignalProducer<Output, NSError> {
        return executor(executable, serialize(input)).map(deserialize)
	}
}

extension Command {
	func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput> {
		return Pipeline(self).map(transform)
	}

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput> {
		return Pipeline(self).andThen(command)
	}

    func run(_ input: Input) -> SignalProducer<Output, NSError> {
        return Pipeline(self).run(input)
    }
}
