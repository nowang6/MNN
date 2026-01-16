# MNN 编译和 Qwen3-0.6B 推理步骤文档

## 已完成步骤

### 1. 探索 MNN 代码库结构
- 使用 Explore 代理分析了 MNN 代码库结构
- 了解了编译流程和 LLM 推理相关文件
- 确定了在 x86 Linux 上编译 MNN 的步骤

### 2. 编译 MNN for x86 Linux
- 已执行以下命令：
```bash
# 生成 schema 文件
./schema/generate.sh

# 创建 build 目录并配置 CMake
mkdir build && cd build
cmake .. -DMNN_BUILD_LLM=ON -DMNN_LOW_MEMORY=ON -DMNN_CPU_WEIGHT_DEQUANT_GEMM=ON -DMNN_SUPPORT_TRANSFORMER_FUSE=ON -DMNN_USE_SSE=ON -DMNN_AVX512=ON -DMNN_BUILD_SHARED_LIBS=ON

# 编译（使用多线程）
make -j$(nproc)
```

- 编译成功，生成以下关键文件：
  - `libMNN.so`：MNN 主库
  - `libllm.so`：LLM 推理库
  - `llm_demo`：LLM 推理演示程序
  - `llm_bench`：LLM 基准测试工具
  - `quantize_llm`：LLM 量化工具

## 剩余步骤（需要手动执行）

### 3. 安装 Python 依赖
LLM 模型导出需要 Python 环境。请安装以下依赖：

```bash
cd transformers/llm/export
pip3 install -r requirements.txt
```

注意：如果使用系统 Python，可能需要 `sudo` 权限或使用虚拟环境。

### 4. 转换 Qwen3-0.6B 模型为 MNN 格式
Qwen3-0.6B 权重已下载到当前目录的 `Qwen3-0.6B/` 文件夹中（safetensors 格式）。

运行以下命令进行转换：

```bash
cd transformers/llm/export
python3 llmexport.py \
  --path ../../Qwen3-0.6B \
  --export mnn \
  --quant_bit 4 \
  --dst_path ../../qwen_mnn_model
```

参数说明：
- `--path`：源模型路径
- `--export mnn`：导出为 MNN 格式
- `--quant_bit 4`：使用 4 位量化（减少模型大小，提高推理速度）
- `--dst_path`：输出目录

如果遇到 `MNN` 模块未找到的错误，可能需要安装 pymnn 或指定 mnnconvert 路径：
```bash
python3 llmexport.py \
  --path ../../Qwen3-0.6B \
  --export mnn \
  --quant_bit 4 \
  --dst_path ../../qwen_mnn_model \
  --mnnconvert ../../build/MNNConvert
```

### 5. 运行 LLM 推理
转换成功后，使用编译的 `llm_demo` 进行推理：

```bash
# 进入 build 目录
cd build

# 交互式聊天模式
./llm_demo ../qwen_mnn_model/config.json

# 或批量处理 prompt.txt 文件中的提示词
./llm_demo ../qwen_mnn_model/config.json ../prompt.txt
```

### 6. 创建 prompt.txt 文件（可选）
如果需要批量处理，创建 `prompt.txt` 文件，每行一个提示词：

```bash
echo "介绍一下人工智能" > ../prompt.txt
echo "写一首关于春天的诗" >> ../prompt.txt
```

## 故障排除

### 常见问题

1. **Python 依赖安装失败**
   - 尝试使用虚拟环境：`python3 -m venv venv && source venv/bin/activate`
   - 或使用 conda 环境

2. **llmexport.py 运行错误**
   - 确保已安装所有 requirements.txt 中的包
   - 检查 torch 版本兼容性
   - 确保有足够的磁盘空间（模型转换需要额外空间）

3. **llm_demo 运行错误**
   - 确保模型转换成功，输出目录包含：
     - `config.json`
     - `llm.mnn`
     - `llm.mnn.weight`
     - `embeddings_bf16.bin`
     - `llm_config.json`
     - `tokenizer.txt`
   - 检查文件路径是否正确

4. **内存不足**
   - Qwen3-0.6B 模型需要一定内存，确保系统有足够 RAM
   - 可以尝试使用 `--quant_bit 8` 减少内存使用（但模型文件会更大）

## 参考信息

- MNN LLM 文档：`transformers/README.md`
- 模型导出脚本：`transformers/llm/export/llmexport.py`
- 编译的 LLM 演示程序：`build/llm_demo`

## 下一步
按照上述步骤 3-5 执行即可完成 Qwen3-0.6B 模型的推理。如有问题，请检查错误信息并参考故障排除部分。