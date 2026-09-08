# Model format

Submit a self-contained ONNX file named `model.onnx`, alongside `adapter.json`.
The platform loads the graph into Axon, inspects it, and runs it against the
adapter's actual inputs. Training code and framework are your choice; the exported
artifact must work within the deployed runtime and admission policy.

## ONNX compatibility

The current deployment accepts ONNX opsets **13 through 19**, inclusive, and
applies an operator allowlist. A graph loading on your development machine does
not prove it meets these rules. Avoid external weight files: the release contract
fetches one model asset and one adapter asset.

The currently configured operator names are:

```text
Abs Add And ArgMax ArgMin AveragePool BatchNormalization Cast Ceil
Clip Concat Constant ConstantOfShape Conv Div Elu Equal Erf Exp
Expand Flatten Floor Gather GatherElements Gemm GlobalAveragePool
GlobalMaxPool Greater HardSigmoid Identity InstanceNormalization
LayerNormalization LeakyRelu Less Log LogSoftmax MatMul Max MaxPool
Mean Min Mul Neg Not Or Pad Pow PRelu Range Reciprocal ReduceMax
ReduceMean ReduceMin ReduceSum Relu Reshape Resize Selu Shape Sigmoid
Sign Slice Softmax Softplus Split Sqrt Squeeze Sub Sum Tanh Tile
Transpose Unsqueeze Where
```

This is the deployment's policy snapshot, not a promise that every operator/type
combination will execute. In particular, do not infer that an unlisted variant
such as `GatherND` is allowed because a related operator is listed. Admission
checks the exported graph, so inspect what your exporter actually emitted.

## Inputs and outputs

Every `in` result field names a graph input and must hold a tensor of its expected
shape and type. Graph output names are available under `outputs` to the `out`
program. Input and output names are chosen by you, not prescribed by Ants.

Adapter tensors support `int8`, `uint8`, `int16`, `int32`, and `float32`. Match the
ONNX boundary types explicitly; an internal graph dtype does not automatically
make it a supported adapter boundary dtype.

Support all three board sizes and the varying ant count. Dynamic dimensions can
express this when supported by the graph; fixed dimensions require a compatible
encoding such as padding and correct output projection. Test the actual shapes
fed by the adapter. No persistent hidden state is carried between turns.

## How size is measured

The competition metric is:

```text
S = bytes(zstd level 19(model initializer tensor data))
  + bytes(zstd level 19(exact adapter file))
```

It is not the raw `.onnx` file size or a compressed archive of your release.
Axon's `/inspect` reports `size_metric_bytes` and each compressed contribution.
Parameter count is useful diagnostic information but does not assign your class.

Admission assigns the smallest [weight class](weight-classes.md) that fits `S`.
Raw asset ceilings also apply independently. Hashes identify the exact released
files, so even a formatting-only adapter edit requires a new hash.

## What is inspected

Admission verifies asset hashes, loads the model and adapter, reads graph facts,
checks class and operator policy, and evaluates reference observations. Validation
reports the input shapes actually used, adapter counts, and estimated FLOPs at
those shapes. Exceeding the class compute cap can reject a small graph.

Use [Testing before you submit](testing.md) to exercise the same loader locally.
Passing admission establishes compatibility on the reference cases; it does not
prove playing strength or guarantee every future observation fits your budget.
