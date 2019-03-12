import XCTest
@testable import Pipelines

class PipelinesTests: XCTestCase {
	func test() throws {
		let ls = Command<String?, [String]>(
			executable: "ls",
			serialize: { directory in
				return Input(arguments: directory.map { [$0] } ?? [])
			},
			deserialize: { output in
				return String(data: output.stdout, encoding: .utf8)!
					.components(separatedBy: "\n")
					.filter { !$0.isEmpty }
			}
		)

		let path = Bundle(identifier: "com.diephouse.matt.Pipelines")!
			.bundleURL
			.path
		let pipeline = Pipeline(ls)
			.andThen { $0.first! }
		let files = try pipeline.andThen { [$0] }.run(path)
		print("\(files.count) files:")
		for f in files {
			print("\t • \(f)")
		}
	}
}
