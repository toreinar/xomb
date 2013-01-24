CC=x86_64-pc-elf-gcc
DC=ldc

source build_arch.sh

RUNTIME_PATH=../kernel/runtime

KERNEL_BUILDFLAGS="-d-version=KERNEL -I.. -I${ARCH_PATH} -nodefaultlib ${ARCH_FLAGS}"

# what the target is
TARGET=xomb.iso

# compile the assembly for the target

echo
echo Setting up filesystem for target
mkdir -p root/binaries
mkdir -p iso/binaries
mkdir -p objs

echo
echo Setting up user interfaces for target: ${ARCH_NAME}
arch_setup;

echo
echo Compiling Kernel Runtime
echo '--> kernel/runtime/object.d'
${DC} ${KERNEL_BUILDFLAGS} -I${RUNTIME_PATH} -c ../kernel/runtime/object.d -oq -odobjs
echo '--> kernel/runtime/invariant.d'
${DC} ${KERNEL_BUILDFLAGS} -I${RUNTIME_PATH} -c ../kernel/runtime/invariant.d -oq -odobjs

# Runtime Types
for item in ${RUNTIME_PATH}/std/typeinfo/*.d;
do
	echo "--> ${item:3:${#item}}"
  ${DC} ${KERNEL_BUILDFLAGS} -I${RUNTIME_PATH} -c ${item} -oq -odobjs
done

echo '--> kernel/runtime/dstubs.d'
${DC} ${KERNEL_BUILDFLAGS} -I${RUNTIME_PATH} -c ../kernel/runtime/dstubs.d -oq -odobjs
echo '--> kernel/runtime/util.d'
${DC} ${KERNEL_BUILDFLAGS} -I${RUNTIME_PATH} -c ../kernel/runtime/util.d -oq -odobjs
echo '--> kernel/runtime/std/moduleinit.d'
${DC} ${KERNEL_BUILDFLAGS} -I${RUNTIME_PATH} -c ../kernel/runtime/std/moduleinit.d -oq -odobjs

echo
echo Compiling Kernel Proper with flags: ${KERNEL_BUILDFLAGS}

ROOT_FILE=../kernel/core/kmain.d

echo "--> ${ROOT_FILE:3:${#ROOT_FILE}}"
${DC} ${ROOT_FILE} ${KERNEL_BUILDFLAGS} -c -oq -odobjs

for item in `${DC} ${ROOT_FILE} -c -o- -oq -v ${KERNEL_BUILDFLAGS} | sed 's/import\s*\(tango\|object\|ldc\)//' | grep "import " | sed 's/import\s*\S*\s*[(]\([^)]*\)[)]/\1/'`
do
	echo "--> ${item:3:${#item}}"
	${DC} ${item} ${KERNEL_BUILDFLAGS} -c -oq -odobjs
done

# we will need some post build foo to link and create the iso

echo
echo Creating Kernel Executable
echo '--> xomb'
#llvm-ld -native -Xlinker=-nostdlib -Xlinker=-Tlinker.ld -Xlinker="-b elf64-x86-64" `ls dsss_objs/G/*.o` -o iso/boot/xomb
#llvm-ld -nodefaultlib -g -I.. -I../kernel/runtime/. `ls dsss_objs/G/*.o`
ld -nostdlib -nodefaultlibs -b elf64-x86-64 -T ${ARCH_PATH}/linker.ld -o iso/boot/xomb `ls objs/*.o`

echo
echo Compiling ISO
./buildiso.sh

echo
echo Creating Kernel Symbol File
echo '--> xomb.sym'
./mkldsym.sh iso/boot/xomb xomb.sym

