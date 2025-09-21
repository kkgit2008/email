#!/bin/bash



# TIME:20250921



# 定义对比目录
COMPARE_DIR="Compare730b1e0e7ddfa4ee07a8ec607"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) || { echo "无法确定脚本目录"; exit 1; }
cd "$SCRIPT_DIR" || { echo "无法切换到脚本所在目录"; exit 1; }

DIR_PROMPT="请将要对比的文件夹放入< $(pwd)/$COMPARE_DIR >目录中，然后重新运行脚本"

# 检查并创建COMPARE_DIR目录
if [ ! -d "$COMPARE_DIR" ]; then
    echo "提示：目录 $COMPARE_DIR 不存在，正在创建..."
    if mkdir -p "$COMPARE_DIR"; then
        echo "已创建目录: $COMPARE_DIR"
        echo "$DIR_PROMPT" >&2
        exit 0
    else
        echo "错误：无法创建目录 $COMPARE_DIR" >&2
        echo "可能原因：" >&2
        echo "1. 当前目录没有写入权限" >&2
        echo "2. 文件系统为只读" >&2
        echo "解决方案：" >&2
        echo "1. 在有写入权限的位置运行此脚本" >&2
        echo "2. 手动创建 $COMPARE_DIR 目录并确保有写入权限" >&2
        exit 1
    fi
fi

# 检查COMPARE_DIR目录是否为空
if [ -z "$(ls -A "$COMPARE_DIR")" ]; then
    echo "提示：目录 $COMPARE_DIR 中没有文件夹"
    echo "$DIR_PROMPT" >&2
    exit 0
fi

# 获取要对比的文件夹数量
dir_count=$(find "$COMPARE_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$dir_count" -lt 2 ]; then
    echo "错误：需要至少2个文件夹进行对比，当前 $COMPARE_DIR 目录中有 $dir_count 个文件夹。" >&2
    exit 1
fi

# 定义最终结果文件（您指定的文件名）
result_file="$COMPARE_DIR/CompareResult.txt"

# 收集所有文件夹路径（使用隐藏临时文件，自动删除）
tmp_dirs_file="$COMPARE_DIR/.tmp_find_dirs_$$"
find "$COMPARE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 > "$tmp_dirs_file"
dirs=()
while IFS= read -r -d $'\0'; do
    dirs+=("$REPLY")
done < "$tmp_dirs_file"
rm -f "$tmp_dirs_file"

# 比较函数
compare_dirs() {
    dir1="$1"
    dir2="$2"
    
    echo "===================================================================="
    echo "比较文件夹: $(basename "$dir1") 和 $(basename "$dir2")"
    echo "===================================================================="
    
    diff -rq "$dir1" "$dir2" | while read -r line; do
        if [[ "$line" == Only* ]]; then
            only_dir=$(echo "$line" | awk '{print $3}')
            file=$(echo "$line" | awk '{print $4}' | sed "s|^$only_dir/||")
            echo "[🤩独有] 仅在 $(basename "$only_dir") 中存在: $file"
        else
            file1=$(echo "$line" | awk '{print $2}')
            file2=$(echo "$line" | awk '{print $4}')
            echo "[🤏不同] 文件内容不同:"
            echo "  $(basename "$dir1")/${file1#$dir1/}"
            echo "  $(basename "$dir2")/${file2#$dir2/}"
        fi
    done
}

# 清空旧结果文件
: > "$result_file"

# 两两比较所有文件夹
for i in $(seq 0 $((${#dirs[@]} - 1))); do
    for j in $(seq $((i + 1)) $((${#dirs[@]} - 1))); do
        compare_dirs "${dirs[i]}" "${dirs[j]}" >> "$result_file"
    done
done

# 显示结果
if [ -s "$result_file" ]; then
    echo "注意: 文件夹对比成功！\n文件夹对比结果已保存到: $result_file" >&2
    
    if command -v less >/dev/null 2>&1; then
        less -R "$result_file"
    #else
        #cat "$result_file"
    fi
else
    echo "所有文件夹内容完全相同。" | tee -a "$result_file" >&2
fi

exit 0
