@testable import Pipelines
import ReactiveSwift
import XCTest

class PipelinesTests: XCTestCase {
	func test() throws {
		let ls = Command<String, [String]>(
			executable: "ls",
			serialize: { directory in
				return Input(arguments: [directory])
			},
			deserialize: { output in
				return String(data: output.stdout, encoding: .utf8)!
					.components(separatedBy: "\n")
					.filter { !$0.isEmpty }
			}
		)

		let url = Bundle(identifier: "com.diephouse.matt.Pipelines")!.bundleURL
		let pipeline1 = ls
			.map { files -> Either<String, [String]> in
				if let second = files.dropFirst().first {
					return .left(url.appendingPathComponent(second).path)
				} else {
					return .right([])
				}
			}
			.select(Pipeline(ls))

		let pipeline2 = Pipeline(ls)

		let pipeline = Pipeline<String, ([String], [String])>.parallel(pipeline1, pipeline2)
        print(pipeline)

		func printFiles(_ files: [String]) {
			print("\(files.count) files:")
			for f in files {
				print("\t • \(f)")
			}
		}
		
		let files1 = pipeline.run(url.path).first()!.value!
		printFiles(files1.0)
		printFiles(files1.1)

		let files2 = pipeline
			.run(url.path) { executable, input in
				print("» \(executable) \(input.arguments)")

				var lines: [String] = []
				while let line = readLine(), line != "" {
					lines.append(line)
				}
				let stdout = lines.joined(separator: "\n").data(using: .utf8)!
				let output = Pipelines.Output(exitCode: 0, stderr: Data(), stdout: stdout)
				return SignalProducer(value: output)
			}
			.first()!
			.value!
		printFiles(files2.0)
		printFiles(files2.1)
	}
}
