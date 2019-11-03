# ======================================================================================================
# Required Environment Variables
# ======================================================================================================
: ${WASM_STRIP:?}
: ${WASM_LD:?}
: ${SWIFTC:?}

: ${WASI_SDK:?}
# WASI_SDK is a directory which is downloaded from https://github.com/swiftwasm/wasi-sdk/releases/download/20190421.6/wasi-sdk-3.19gefb17cb478f9.m-linux.tar.gz
: ${SWIFTWASM_SDK:?}
: ${ICU_LIB:?}
# ICU_LIB is a directory which should be set icu_out/lib 
# downloaded from https://github.com/swiftwasm/icu4c-wasi/releases/download/20190421.3/icu4c-wasi.tar.xz

: ${EXTRA_OBJS:?}
# EXTRA_OBJS should be a directory which contains below
# - swift_start.o
# - swift_end.o
# - fakelocaltime.o
# - fakepthread.o

# ======================================================================================================

input=$1
object_file=$input.o
output=${2:-"a"}

sysroot=$WASI_SDK/share/sysroot

# Linker input files
fakepthread=$EXTRA_OBJS/fakepthread.o
fakelocaltime=$EXTRA_OBJS/fakelocaltime.o
swift_start=$EXTRA_OBJS/swift_start.o
swift_end=$EXTRA_OBJS/swift_end.o

swiftrt=$SWIFTWASM_SDK/lib/swift_static/wasm/wasm32/swiftrt.o
crt1=$sysroot/lib/wasm32-wasi/crt1.o
clangrt=$WASI_SDK/lib/clang/8.0.0/lib/wasi/libclang_rt.builtins-wasm32.a

# Linker search paths
wasi_libs=$sysroot/lib/wasm32-wasi
swift_libs=$SWIFTWASM_SDK/lib/swift_static/wasm


# Precondition check

echo "Validating inputs..."
[ ! -f $input ] && { echo "Input file $input not found"; exit 1; } 
for extra_obj in swift_start.o swift_end.o fakelocaltime.o fakepthread.o
do
  if [ ! -f $EXTRA_OBJS/$extra_obj ]; then
    echo "Extra object file $EXTRA_OBJS/$extra_obj not found"
    exit 1
  fi
done


# Compile from swift file to object file

echo "Compiling..."
$SWIFTC -target wasm32-unknown-unknown-wasm -O -g -sdk $sysroot -o $object_file -c $input

# Link them
echo "Linking..."
$WASM_LD \
  -o $output \
  $object_file \
  $swift_start $swift_end \
  $swiftrt $crt1 $clangrt \
  $fakepthread $fakelocaltime \
  -L $wasi_libs \
  -L $ICU_LIB -L $swift_libs \
  -lc -lc++ -lc++abi \
  -lswiftImageInspectionShared \
  -lswiftCore \
  -lswiftSwiftOnoneSupport \
  -licuuc -licudata \
  --error-limit=0 \
  --no-gc-sections \
  --no-threads

echo "Stripping..."
$WASM_STRIP $output

