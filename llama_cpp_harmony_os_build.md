### 鸿蒙 (HarmonyOS) 编译步骤

#### 环境准备

```bash
# 1. 进入项目目录
cd /home/niwang/code/llama.cpp


# 3. 验证编译器（可选）
$OHOS_NDK/native/llvm/bin/clang --target=aarch64-linux-ohos --version
# 应显示：Target: aarch64-unknown-linux-ohos
```

#### 构建步骤

```bash
# 1. 清理并创建构建目录
rm -rf build_ohos
mkdir build_ohos
cd build_ohos

# 2. 配置CMake（关键步骤）
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../ohos_sdk/native/build/cmake/ohos.toolchain.cmake \
    -DOHOS_ARCH=arm64-v8a \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DGGML_CUDA=OFF \
    -DGGML_METAL=OFF \
    -DGGML_VULKAN=OFF \
    -DGGML_SYCL=OFF \
    -DGGML_CANN=OFF \
    -DGGML_NATIVE=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_CURL=OFF \
    -DLLAMA_OPENSSL=OFF

# 3. 编译目标（选择需要的工具）
# 编译llama-cli（命令行工具）
cmake --build . --config Release --target llama-cli -j $(nproc)

# 编译llama-server（服务器）
# cmake --build . --config Release --target llama-server -j $(nproc)

# 编译所有目标
# cmake --build . --config Release -j $(nproc)
```
