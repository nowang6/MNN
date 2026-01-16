我已经对文档进行了简化和整理，确保内容更加清晰和有逻辑性。以下是修改后的版本：

---

# MNN 编译与 Qwen3-0.6B 推理步骤

## 完成步骤

### 1. 探索 MNN 代码库

* 使用 Explore 代理分析了 MNN 代码库结构，了解了编译流程和与 LLM 推理相关的文件。
* 确定了在 x86 Linux 上编译 MNN 的步骤。

### 2. 编译 MNN for x86 Linux

执行以下步骤编译 MNN：

```bash
# 生成 schema 文件
./schema/generate.sh

# 创建并进入 build 目录，配置 CMake
mkdir build && cd build

# CPU 推理配置（原始配置）
# cmake .. -DMNN_BUILD_LLM=ON -DMNN_LOW_MEMORY=ON -DMNN_CPU_WEIGHT_DEQUANT_GEMM=ON -DMNN_SUPPORT_TRANSFORMER_FUSE=ON -DMNN_USE_SSE=ON -DMNN_AVX512=ON -DMNN_BUILD_SHARED_LIBS=ON

# Vulkan GPU 推理配置
# 重要：在 Linux 上使用 Vulkan 后端时，必须设置 MNN_SEP_BUILD=OFF
cmake .. -DMNN_BUILD_LLM=ON -DMNN_LOW_MEMORY=ON -DMNN_CPU_WEIGHT_DEQUANT_GEMM=ON -DMNN_SUPPORT_TRANSFORMER_FUSE=ON -DMNN_USE_SSE=ON -DMNN_AVX512=ON -DMNN_BUILD_SHARED_LIBS=ON -DMNN_VULKAN=ON -DMNN_SEP_BUILD=OFF

# 或者使用系统 Vulkan 库（需要先安装 libvulkan-dev）
# cmake .. -DMNN_BUILD_LLM=ON -DMNN_LOW_MEMORY=ON -DMNN_CPU_WEIGHT_DEQUANT_GEMM=ON -DMNN_SUPPORT_TRANSFORMER_FUSE=ON -DMNN_USE_SSE=ON -DMNN_AVX512=ON -DMNN_BUILD_SHARED_LIBS=ON -DMNN_VULKAN=ON -DMNN_SEP_BUILD=OFF -DMNN_USE_SYSTEM_LIB=ON

# 编译（多线程）
make -j$(nproc)
```

**编译成功后生成的关键文件：**

* `libMNN.so`：MNN 主库
* `libllm.so`：LLM 推理库
* `llm_demo`：LLM 推理演示程序
* `llm_bench`：LLM 基准测试工具
* `quantize_llm`：LLM 量化工具

### 2.1 编译 MNN for HarmonyOS (鸿蒙) - CPU 推理

参考 llama.cpp 的鸿蒙编译步骤，执行以下步骤在鸿蒙平台上编译 MNN（使用 CPU 推理）：

#### 环境准备

```bash
# 1. 设置 OHOS_NDK 环境变量（必须）
# 将 OHOS_NDK 设置为鸿蒙 NDK 的安装路径
export OHOS_NDK=/path/to/ohos-ndk

# 2. 验证编译器（可选）
$OHOS_NDK/native/llvm/bin/clang --target=aarch64-linux-ohos --version
# 应显示：Target: aarch64-unknown-linux-ohos
```

#### 构建步骤

```bash
# 1. 生成 schema 文件
./schema/generate.sh

# 2. 清理并创建构建目录
rm -rf build_ohos
mkdir build_ohos
cd build_ohos

# 3. 配置 CMake（关键步骤）
# 注意：鸿蒙平台使用 ARM64 架构，不需要 x86 特定的优化选项（SSE、AVX512）
# 重要：禁用 ARM82 优化以避免汇编编译错误（鸿蒙 Clang 对汇编语法支持有限）
# MNN_LLM_BUILD_DEMO 默认为 ON，会自动编译 llm_demo 等工具
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../ohos-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DMNN_BUILD_LLM=ON \
    -DMNN_LOW_MEMORY=ON \
    -DMNN_CPU_WEIGHT_DEQUANT_GEMM=ON \
    -DMNN_SUPPORT_TRANSFORMER_FUSE=ON \
    -DMNN_BUILD_SHARED_LIBS=ON \
    -DMNN_SEP_BUILD=OFF \
    -DMNN_VULKAN=OFF \
    -DMNN_METAL=OFF \
    -DMNN_OPENCL=OFF \
    -DMNN_USE_SSE=OFF \
    -DMNN_AVX512=OFF \
    -DMNN_ARM82=OFF \
    -DMNN_BUILD_TESTS=OFF

# 4. 编译（多线程）
cmake --build . --config Release -j $(nproc)

# 或者使用 make
# make -j$(nproc)
```

**编译成功后生成的关键文件：**

* `libMNN.so`：MNN 主库（ARM64 架构，适用于鸿蒙系统）
* `llm_demo`：LLM 推理演示程序（默认编译，由 `MNN_LLM_BUILD_DEMO` 控制）
* `llm_bench`：LLM 基准测试工具
* `quantize_llm`：LLM 量化工具
* `embedding_demo`：Embedding 演示程序
* `reranker_demo`：Reranker 演示程序

**重要说明：**

1. **环境变量**：必须设置 `OHOS_NDK` 环境变量指向鸿蒙 NDK 安装路径
2. **架构**：鸿蒙平台使用 ARM64 架构，因此禁用了 x86 特定的优化选项（`MNN_USE_SSE=OFF`、`MNN_AVX512=OFF`）
3. **后端**：CPU 推理配置禁用了所有 GPU 后端（Vulkan、Metal、OpenCL）
4. **工具链**：使用项目自带的 `ohos-toolchain.cmake` 文件进行交叉编译
5. **分离构建**：设置 `MNN_SEP_BUILD=OFF` 将所有后端编译到主库中，简化部署
6. **ARM82 优化**：**必须禁用 ARM82**（`-DMNN_ARM82=OFF`），因为鸿蒙 Clang 编译器对 ARM82 汇编代码的语法支持有限，会导致编译错误。禁用后仍可使用标准的 ARM64 NEON 优化，性能影响较小。

#### 故障排除

如果编译时仍然遇到 ARM64 汇编文件（`.S` 文件）的编译错误，可能是鸿蒙 Clang 对某些 GNU 汇编语法支持不完整。可以尝试以下解决方案：

**方案 1：检查工具链配置**
确保 `ohos-toolchain.cmake` 已正确配置汇编器选项。如果问题持续，可以尝试在 CMake 配置中添加：
```bash
cmake .. \
    ...其他选项... \
    -DCMAKE_ASM_FLAGS="--target=aarch64-linux-ohos --sysroot=$OHOS_NDK/native/sysroot -fPIC -integrated-as -march=armv8-a"
```

**方案 2：如果汇编错误无法解决**
如果 ARM64 汇编文件编译仍然失败，可能需要联系 MNN 项目维护者或考虑使用其他交叉编译工具链。标准的 ARM64 NEON C++ 代码应该可以正常编译，只是性能可能略低于汇编优化版本。

## 剩余步骤（需要手动执行）

### 3. 安装 Python 依赖

为导出 LLM 模型，需要安装以下依赖：

```bash
cd transformers/llm/export
pip3 install -r requirements.txt
```

如果使用系统 Python，可能需要使用 `sudo` 或虚拟环境。

### 4. 转换 Qwen3-0.6B 模型为 MNN 格式

Qwen3-0.6B 模型已下载到当前目录的 `Qwen3-0.6B/` 文件夹（safetensors 格式）。

运行以下命令进行转换：

```bash
cd transformers/llm/export
python3 llmexport.py \
  --path ../../Qwen3-0.6B \
  --export mnn \
  --quant_bit 4 \
  --dst_path ../../qwen_mnn_model
```

**参数说明：**

* `--path`：源模型路径
* `--export mnn`：导出为 MNN 格式
* `--quant_bit 4`：使用 4 位量化（减小模型大小并加速推理）
* `--dst_path`：输出目录

如果遇到 `MNN` 模块未找到的错误，尝试指定 `mnnconvert` 路径：

```bash
python3 llmexport.py \
  --path ../../Qwen3-0.6B \
  --export mnn \
  --quant_bit 4 \
  --dst_path ../../qwen_mnn_model \
  --mnnconvert ../../build/MNNConvert
```

### 5. 配置推理后端（Vulkan GPU）

编辑 `config.json` 文件，设置 `backend_type` 为 `"vulkan"` 以启用 Vulkan GPU 推理：

```json
{
  "backend_type": "vulkan",
  "thread_num": 4,
  "precision": "low",
  "memory": "low",
  "max_new_tokens": 512
}
```

**重要说明：**

* `backend_type`: 设置为 `"vulkan"` 使用 Vulkan GPU，设置为 `"cpu"` 使用 CPU
* `thread_num`: Vulkan 后端通常使用 4，适配较好的性能
* `precision`: 推荐使用 `"low"`（fp16），提高推理性能
* `memory`: 推荐使用 `"low"`，启用运行时量化以节省内存

### 6. 运行 LLM 推理

转换成功后，使用 `llm_demo` 进行推理：

```bash
# 进入 build 目录
cd build

# 交互式聊天模式
./llm_demo ../qwen_mnn_model/config.json

# 或批量处理 prompt.txt 文件中的提示词
./llm_demo ../qwen_mnn_model/config.json ../prompt.txt
```

### 7. 创建 prompt.txt 文件（可选）

如果需要批量处理，可以创建 `prompt.txt` 文件，每行一个提示词：

```bash
echo "介绍一下人工智能" > ../prompt.txt
echo "写一首关于春天的诗" >> ../prompt.txt
```

## 故障排除

### 常见问题及解决方法

1. **Python 依赖安装失败**

   * 使用虚拟环境：`python3 -m venv venv && source venv/bin/activate`
   * 或使用 conda 环境

2. **llmexport.py 运行错误**

   * 确保已安装所有 requirements.txt 中的包
   * 检查 torch 版本兼容性
   * 确保有足够磁盘空间进行模型转换

3. **llm_demo 运行错误**

   * 确保模型转换成功，输出目录包含：

     * `config.json`
     * `llm.mnn`
     * `llm.mnn.weight`
     * `embeddings_bf16.bin`
     * `llm_config.json`
     * `tokenizer.txt`
   * 检查文件路径是否正确

4. **内存不足**

   * Qwen3-0.6B 模型需要一定的内存，确保系统有足够的 RAM
   * 可尝试使用 `--quant_bit 8` 来减少内存占用（但文件会更大）

5. **Vulkan 相关错误**

   * 确保系统已安装 Vulkan 驱动与开发库（如 `libvulkan-dev`）
   * 使用 `vulkaninfo` 或 `vkcube` 检查 Vulkan 可用性
   * 如果 Vulkan 不可用，可以回退到 CPU 推理（设置 `backend_type: "cpu"`）

## Vulkan GPU 推理说明

### 编译时启用 Vulkan

在 CMake 配置中添加 `-DMNN_VULKAN=ON` 选项启用 Vulkan 支持。

### 运行时使用 Vulkan

在 `config.json` 中设置 `backend_type: "vulkan"` 即可启用 Vulkan GPU 推理。

### 如何判断是否使用 GPU 推理

1. **查看启动日志**

   * **GPU（Vulkan）**：不会出现 `Can't Find type=7 backend` 错误信息
   * **CPU**：会看到 `Can't Find type=7 backend, use 0 instead`

2. **检查库链接**

   ```bash
   cd build
   ldd libMNN.so | grep vulkan
   ```

3. **使用系统工具监控**

   * NVIDIA GPU：`nvidia-smi`
   * AMD GPU：`radeontop`
   * Intel GPU：`intel_gpu_top`

4. **性能对比**

   * GPU 推理通常比 CPU 推理速度更快，特别是对于大模型

### Vulkan vs CPU 推理

* **Vulkan GPU**：适合有独立显卡或集成显卡支持 Vulkan 的系统，推理速度较快
* **CPU**：兼容性最强，但推理速度较慢

### 系统要求

* 安装 Vulkan 驱动与开发库：

  ```bash
  sudo apt-get install libvulkan-dev vulkan-tools
  ```

### 常见问题排查

**问题：看到 `Can't Find type=7 backend, use 0 instead`**

* 解决方案：在重新编译时使用 `-DMNN_SEP_BUILD=OFF`，将 Vulkan 后端编译到 `libMNN.so` 中：

```bash
# 重新编译命令：
cd build
rm -rf *
cmake .. -DMNN_BUILD_LLM=ON -DMNN_LOW_MEMORY=ON -DMNN_CPU_WEIGHT_DEQUANT_GEMM=ON -DMNN_SUPPORT_TRANSFORMER_FUSE=ON -DMNN_USE_SSE=ON -DMNN_AVX512=ON -DMNN_BUILD_SHARED_LIBS=ON -DMNN_VUL
```

