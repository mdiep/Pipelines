import Foundation

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
	let block: (Input) throws -> Output

	internal init(
        steps: [Step],
        block: @escaping (Input) throws -> Output
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

extension Pipeline {
	func andThen<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput> {
        let steps = self.steps + [.convert(Output.self, NewOutput.self)]
        let block = self.block
        return Pipeline<Input, NewOutput>(steps: steps) { input in
			return try transform(block(input))
		}
	}

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput> {
        let steps = self.steps + [.execute(command.executable)]
        let block = self.block
        return Pipeline<Input, NewOutput>(steps: steps) { input in
			return try command.run(block(input))
		}
	}
}

extension Pipeline {
	func run(_ input: Input) throws -> Output {
		return try block(input)
	}
}
