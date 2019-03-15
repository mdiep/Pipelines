# Pipelines
Value-based processes in Swift.

```swift
let ls = Command<String, [String]>(
    executable: "ls",
    serialize: { … },
    deserialize: { … }
)

let pipeline = ls
    .map { url.appendingPathComponent($0[1]).path }
    .andThen(ls)

print(pipeline) // prints "ls » (Array<String> → String) » ls"

pipeline.run("path").startWithResult { … }
```

`Command`s can be built into `Pipeline`s that transform the `Input` to the `Output`.

Notably, this is not done with a `(Output) -> Command<Output, NewOutput>` function. This means that the effects are _static_, so they're open to static analysis. In the above example, you could example the pipeline to test/show that it only calls `ls` and not `rm`.

## Todo
- [ ] Add branching (based on selective applicative functors)
- [ ] Make more of `Command` static with `KeyPath`s
- [ ] Parallel commands
- [ ] Document
- [ ] Test
- [ ] Make API public

