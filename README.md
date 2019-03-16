# Pipelines
Value-based processes in Swift.

```swift
// A value describing how to run a command
let ls = Command<String, [String]>(
    executable: "ls",
    serialize: { … },
    deserialize: { … }
)

// A pipeline built up of commands
let pipeline = ls                                                   // 1. Run `ls`
    .map { files -> Either<String, [String]> in                     // 2. Transform the output
        if let second = files.dropFirst().first {                   //   a. If there are 2+ files,
            return .left(url.appendingPathComponent(second).path)   //      return the second one
        } else {                                                    //   b. Otherwise,
            return .right([])                                       //      return an empty list
        }                                                           //
    }                                                               //
    .select(Pipeline(ls))                                           // 3. If we received a string, run `ls` with it

// A visual description of the pipeline
// If `Pipeline` used a Monadic `flatMap`, you wouldn't be able to tell that the 2nd
// `Command` was a call to `ls`--it'd be hidden inside the block.
//
// prints "ls » (Array<String> → Either<String, Array<String>>) » [ls]"
print(pipeline) 

// The pipeline can be run easily.
pipeline.run("path").startWithResult { … }

// Or you can inject an _executor_ to change the interpretation.
pipeline
    .run(url.path) { executable, input in
        // A mock implementation of running the `Command`.
        //
        // Print out the executable name and arguments, then read input
        // from stdin to pass on.
        print("» \(executable) \(input.arguments)")

        var lines: [String] = []
        while let line = readLine(), line != "" {
            lines.append(line)
        }
        let stdout = lines.joined(separator: "\n").data(using: .utf8)!
        let output = Pipelines.Output(exitCode: 0, stderr: Data(), stdout: stdout)
        return SignalProducer(value: output)
    }
    .startWithResult { … }
```

`Command`s can be built into `Pipeline`s that transform the `Input` to the `Output`.

Notably, this is not done with a `(Output) -> Command<Output, NewOutput>` function. This means that the effects are _static_, so they're open to static analysis. In the above example, you could example the pipeline to test/show that it only calls `ls` and not `rm`.

## Todo
- [ ] Make more of `Command` static with `KeyPath`s
- [ ] Parallel commands
- [ ] Document
- [ ] Test
- [ ] Make API public

