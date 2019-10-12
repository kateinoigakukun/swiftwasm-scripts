input_file=$(mktemp).swift
output_file=$(mktemp)
cat <<EOS > $input_file
func f() -> Int { return 1 }
_ = f()
EOS

./build.sh $input_file $output_file \
  || { echo "Failed to build"; exit 1; }

~/projects/open/wasmtime/./target/release/wasmtime $output_file \
  || { echo "Failed to run $output_file"; exit 1; }
