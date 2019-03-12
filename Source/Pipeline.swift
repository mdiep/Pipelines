import Foundation

struct Pipeline<Input, Output> {
	let command: Command<Input, Output>

	init(_ command: Command<Input, Output>) {
		self.command = command
	}
}

extension Pipeline {
	func andThen<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Pipeline<Input, NewOutput> {
		return Pipeline<Input, NewOutput>(command.mapOutput(transform))
	}
}

extension Pipeline {
	func run(_ input: Input) throws -> Output {
		let input = command.serialize(input)

		let p = Process()
		p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
		p.arguments = [command.executable] + input.arguments
		p.currentDirectoryURL = URL(fileURLWithPath: "/")

		let stdout = Pipe()
		let stderr = Pipe()
		p.standardOutput = stdout
		p.standardError = stderr

		try p.run()
		p.waitUntilExit()

		let output = Pipelines.Output(
			exitCode: Int(p.terminationStatus),
			stderr: stderr.fileHandleForReading.readDataToEndOfFile(),
			stdout: stdout.fileHandleForReading.readDataToEndOfFile()
		)
		return command.deserialize(output)
	}
}
