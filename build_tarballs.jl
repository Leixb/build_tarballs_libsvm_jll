# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsvm"
version = v"3.31.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Leixb/libsvm.git", "c62c42278a0f4101d039d5a2cb71d9546f0d8912"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsvm*/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
make 
make lib
install -Dvm 0755 "libsvm.${dlext}" "${libdir}/libsvm.${dlext}"
install -Dvm 0755 "svm-train${exeext}" "${bindir}/svm-train${exeext}"
install -Dvm 0755 "svm-predict${exeext}" "${bindir}/svm-predict${exeext}"
install -Dvm 0755 "svm-scale${exeext}" "${bindir}/svm-scale${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libsvm", :libsvm),
    ExecutableProduct("svm-scale", :svm_scale),
    ExecutableProduct("svm-train", :svm_train),
    ExecutableProduct("svm-predict", :svm_predict)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
