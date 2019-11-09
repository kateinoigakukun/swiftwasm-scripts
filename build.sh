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
# - fakelocaltime.o
# - fakepthread.o

# ======================================================================================================

usage_exit() {
        echo "Usage: $0 [-o] input output" 1>&2
        exit 1
}
while getopts oh OPT
do
    case $OPT in
        o)  OPTIMIZE=1
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done

shift $((OPTIND - 1))

input=$1
object_file=$input.o
output=${2:-"a"}

sysroot=$WASI_SDK/share/sysroot

# Linker input files
fakepthread=$EXTRA_OBJS/fakepthread.o
fakelocaltime=$EXTRA_OBJS/fakelocaltime.o

swiftrt=$SWIFTWASM_SDK/lib/swift_static/wasm/wasm32/swiftrt.o
crt1=$sysroot/lib/wasm32-wasi/crt1.o
clangrt=$WASI_SDK/lib/clang/8.0.0/lib/wasi/libclang_rt.builtins-wasm32.a

# Linker search paths
wasi_libs=$sysroot/lib/wasm32-wasi
swift_libs=$SWIFTWASM_SDK/lib/swift_static/wasm


# Precondition check

echo "Validating inputs..."
[ ! -f $input ] && { echo "Input file $input not found"; exit 1; } 
for extra_obj in fakelocaltime.o fakepthread.o
do
  if [ ! -f $EXTRA_OBJS/$extra_obj ]; then
    echo "Extra object file $EXTRA_OBJS/$extra_obj not found"
    exit 1
  fi
done


# Compile from swift file to object file

echo "Compiling..."
if [ -n "$OPTIMIZE" ]; then
  $SWIFTC -target wasm32-unknown-unknown-wasm -O -sdk $sysroot -o $object_file -c $input
else
  $SWIFTC -target wasm32-unknown-unknown-wasm -g -sdk $sysroot -o $object_file -c $input
fi

# Link them
echo "Linking..."
$WASM_LD \
  -o $output \
  $object_file \
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

if [ -n "$OPTIMIZE" ]; then
  echo "Stripping..."
  $WASM_STRIP $output
fi

