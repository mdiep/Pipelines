import Foundation

struct Command<Input, Output> {
	let executable: String
	let serialize: (Input) -> [String]
	let deserialize: (Data) -> Output

	init(
		executable: String,
		serialize: @escaping (Input) -> ([String]),
		deserialize: @escaping (Data) -> Output
	) {
		self.executable = executable
		self.serialize = serialize
		self.deserialize = deserialize
	}
}

extension Command where Input == [String], Output == Data {
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

extension Command {
	init(
		executable: String,
		serialize: @escaping (Input) -> [String],
		deserialize: @escaping (String) -> Output
	) {
		self = Command<[String], Data>(executable: executable)
			.mapInput(serialize)
			.mapOutput { String(data: $0, encoding: .utf8)! }
			.mapOutput(deserialize)
	}
}

