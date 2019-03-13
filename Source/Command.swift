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
	func run(_ input: Input) -> SignalProducer<Output, NSError> {
        return SignalProducer { () -> Result<Output, NSError> in
            let input = self.serialize(input)

            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = [self.executable] + input.arguments

            let stdout = Pipe()
            let stderr = Pipe()
            p.standardOutput = stdout
            p.standardError = stderr

            do {
                try p.run()
            } catch let error {
                return .failure(error as NSError)
            }
            p.waitUntilExit()

            let output = Pipelines.Output(
                exitCode: Int(p.terminationStatus),
                stderr: stderr.fileHandleForReading.readDataToEndOfFile(),
                stdout: stdout.fileHandleForReading.readDataToEndOfFile()
            )
            return .success(self.deserialize(output))
        }
	}
}

extension Command {
	func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput> {
		return Pipeline(self).map(transform)
	}

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput> {
		return Pipeline(self).andThen(command)
	}
}
