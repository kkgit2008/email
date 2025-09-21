#!/bin/sh




# TIME:20250921



# ===== 定义常量 =====
DIR_NAME="generate_files_056dcd2f46d8d0ec93"		# 目标目录名（常量）
FILE_COUNT=100										# 文件数量（常量）

# ===== 计算脚本所在路径 =====
SCRIPT_DIR="$(dirname "$(realpath "$0")")"  # 获取脚本所在目录
TARGET_DIR="${SCRIPT_DIR}/${DIR_NAME}"      # 目标目录：脚本所在目录下的 DIR_NAME 文件夹

# ===== 创建目录 =====
mkdir -p "$TARGET_DIR" || { echo "错误：无法创建目录 ${TARGET_DIR}"; exit 1; }

# ===== 进入目录并生成文件 =====
cd "$TARGET_DIR" || { echo "错误：无法进入目录 ${TARGET_DIR}"; exit 1; }

i=1
while [ "$i" -le "$FILE_COUNT" ]; do
    echo "${i}" > "file${i}.txt"   # 生成文件 file1.txt ~ file100.txt，内容为 i
    i=$((i + 1))
done

# ===== 输出结果 =====
echo "成功！在目录< ${TARGET_DIR} >下生成 ${FILE_COUNT} 个文件，内容为数字1到999" >&2
