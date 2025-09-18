#!/bin/bash

# 获取脚本所在绝对路径，并切换到该目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || { echo "无法切换到脚本所在目录"; exit 1; }

# 创建file目录（如果不存在）
mkdir -p file

# 检查文件列表.txt是否存在
if [ ! -f "批量生成空白文件.文件列表.txt" ]; then
    echo "错误：批量生成空白文件.文件列表.txt 文件不存在"
    exit 1
fi

# 初始化计数器
existing_count=0
created_count=0
failed_count=0

# 处理文件列表中的每个文件
echo -e "\n===== 开始处理 ====="

while IFS= read -r filename || [ -n "$filename" ]; do
    # 跳过空行
    if [ -z "$filename" ]; then
        continue
    fi

    filepath="file/$filename"
    display_name="$filename"  # 用于显示的名称，不包含file目录
    
    # 检查文件是否已存在
    if [ -e "$filepath" ]; then
        echo "[已存在] $display_name"
        ((existing_count++))
        continue
    fi
    
    # 提取目录部分并创建（如果需要）
    dirpath=$(dirname "$filepath")
    if ! mkdir -p "$dirpath" 2>/dev/null; then
        echo "[创建失败] $display_name (无法创建目录)"
        ((failed_count++))
        continue
    fi
    
    # 尝试创建文件
    if echo '/\/' > "$filepath" 2>/dev/null; then
        echo "[创建成功] $display_name"
        ((created_count++))
    else
        echo "[创建失败] $display_name"
        ((failed_count++))
    fi
done < "批量生成空白文件.文件列表.txt"

# 输出统计信息
echo -e "\n===== 处理结果 ====="
echo "已存在文件数: $existing_count"
echo "成功创建文件数: $created_count"
echo "创建失败文件数: $failed_count"
echo -e "===== 处理完成 =====\n"
