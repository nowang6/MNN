# 设置目标平台为 Linux，因为 OHOS 不是 CMake 默认支持的平台
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 从环境变量读取 OHOS_NDK 路径
set(OHOS_NDK $ENV{OHOS_NDK})
if(NOT OHOS_NDK)
    message(FATAL_ERROR "Please set OHOS_NDK environment variable to point to your HarmonyOS NDK installation")
endif()

# 设置 Clang 交叉编译器路径（带 target triple）
set(CMAKE_C_COMPILER "${OHOS_NDK}/native/llvm/bin/clang")
set(CMAKE_CXX_COMPILER "${OHOS_NDK}/native/llvm/bin/clang++")

# 编译目标 triple，OpenHarmony 通常基于 aarch64-linux-ohos
set(TARGET_TRIPLE aarch64-linux-ohos)

# 为 Clang 添加目标 triple 和 sysroot
# 重要：添加 -fno-emulated-tls 禁用 TLS 模拟，使用原生 TLS
# 这可以解决鸿蒙系统上 __emutls_get_address 符号未找到的问题
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --target=${TARGET_TRIPLE} --sysroot=${OHOS_NDK}/native/sysroot -fPIC -fno-emulated-tls")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --target=${TARGET_TRIPLE} --sysroot=${OHOS_NDK}/native/sysroot -fPIC -fno-emulated-tls")

# 设置汇编器选项：使用集成汇编器，支持 GNU 汇编语法
# 注意：鸿蒙 Clang 的汇编器对某些 GNU 语法支持有限，可能需要禁用 ARM82 优化
# 添加 -integrated-as 确保使用集成汇编器，并设置正确的架构
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} --target=${TARGET_TRIPLE} --sysroot=${OHOS_NDK}/native/sysroot -fPIC -integrated-as -march=armv8-a")

# 设置 sysroot
set(CMAKE_SYSROOT "${OHOS_NDK}/native/sysroot")

# 配置 CMake 查找路径行为
set(CMAKE_FIND_ROOT_PATH "${OHOS_NDK}/native/sysroot")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 链接器选项：使用静态链接 C++ 库以避免依赖系统 libc++_shared.so
# 这对于解决鸿蒙系统 API ≤ 9 上 __emutls_get_address 符号未找到的问题很重要
# 如果系统支持原生 TLS，上面的 -fno-emulated-tls 应该足够
# 但如果仍有问题，可以尝试静态链接 C++ 库
# set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++ -static-libgcc")
# set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libstdc++ -static-libgcc")

