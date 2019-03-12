import Foundation

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

extension Command where Input == Pipelines.Input, Output == Pipelines.Output {
	init(executable: String) {
		self.init(executable: executable, serialize: { $0 }, deserialize: { $0 })
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
	func apply(_ value: Input) -> Command<(), Output> {
		return mapInput { (_: ()) in value }
	}
}
