import XCTest
@testable import Pipelines

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
		let pipeline = Pipeline(ls)
			.andThen { url.appendingPathComponent($0[1]).path }
			.andThen(ls)
		
		let files = try pipeline.run(url.path)
		print("\(files.count) files:")
		for f in files {
			print("\t • \(f)")
		}
	}
}
