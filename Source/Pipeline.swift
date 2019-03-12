import Foundation

struct Pipeline<Input, Output> {
	let block: (Input) throws -> Output

	internal init(_ block: @escaping (Input) throws -> Output) {
		self.block = block
	}

	init(_ command: Command<Input, Output>) {
		block = command.run
	}
}

extension Pipeline {
	func andThen<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput> {
		return Pipeline<Input, NewOutput> { [block = self.block] input in
			return try transform(block(input))
		}
	}

	func andThen<NewOutput>(_ command: Command<Output, NewOutput>) -> Pipeline<Input, NewOutput> {
		return Pipeline<Input, NewOutput> { [block = self.block] input in
			return try command.run(block(input))
		}
	}
}

extension Pipeline {
	func run(_ input: Input) throws -> Output {
		return try block(input)
	}
}
