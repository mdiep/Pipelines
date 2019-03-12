import Foundation

func run<Input, Output>(_ command: Command<Input, Output>, _ input: Input) throws -> Output {
	let input = command.serialize(input)

	let p = Process()
	p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
	p.arguments = [command.executable] + input
	p.currentDirectoryURL = URL(fileURLWithPath: "/")

	let pipe = Pipe()
	p.standardOutput = pipe

	try p.run()
	p.waitUntilExit()

	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	return command.deserialize(data)
}

