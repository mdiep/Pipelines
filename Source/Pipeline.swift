import Foundation
import ReactiveSwift
import Result

enum Step {
    case execute(String)
    case convert(Any.Type, Any.Type)
}

extension Step: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .execute(name):
            return name
        case let .convert(a, b):
            return "(\(a) → \(b))"
        }
    }
}

struct Pipeline<Input, Output> {
    let steps: [Step]
	let block: (Input, @escaping Executor) -> SignalProducer<Output, NSError>

	internal init(
        steps: [Step],
        block: @escaping (Input, @escaping Executor) -> SignalProducer<Output, NSError>
    ) {
        self.steps = steps
		self.block = block
	}

	init(_ command: Command<Input, Output>) {
        steps = [ .execute(command.executable) ]
		block = command.run
	}
}

extension Pipeline: CustomDebugStringConvertible {
    var debugDescription: String {
        return steps.map { "\($0)" }.joined(separator: " » ")
    }
}

extension Pipeline: Pipelineable {
	func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput> {
        let steps = self.steps + [.convert(Output.self, NewOutput.self)]
        let block = self.block
        return Pipeline<Input, NewOutput>(steps: steps) { input, executor in
			return block(input, executor).map(transform)
		}
	}

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput> {
        let steps = self.steps + [.execute(command.executable)]
        let block = self.block
        return Pipeline<Input, NewOutput>(steps: steps) { input, executor in
            return block(input, executor).flatMap(.concat) { input in
                return command.run(input, execute: executor)
            }
		}
	}

	func run(_ input: Input) -> SignalProducer<Output, NSError> {
        return run(input) { executable, input in
            return SignalProducer { () -> Result<Pipelines.Output, NSError> in
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                p.arguments = [executable] + input.arguments

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
                return .success(output)
            }
        }
	}

    func run(
        _ input: Input,
        execute: @escaping Executor
    ) -> SignalProducer<Output, NSError> {
        return block(input, execute)
    }
}
