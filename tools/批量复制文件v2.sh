#!/bin/sh

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
FILELIST="${SCRIPT_DIR}/批量复制文件.文件列表.txt"
CP_DIR="${SCRIPT_DIR}/cpAAAAAA"

# ===== 检查文件列表 =====
if [ ! -f "$FILELIST" ]; then
    echo "错误：文件列表不存在于 ${FILELIST}" >&2
    exit 1
fi

mkdir -p "$CP_DIR" || { echo "错误：无法创建目录 ${CP_DIR}"; exit 1; }
cd "$SCRIPT_DIR" || { echo "错误：无法进入目录 ${SCRIPT_DIR}"; exit 1; }

success_count=0
fail_count=0

while IFS= read -r file; do
    file=$(echo "$file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$file" ] && continue
    [ "$file" != "${file#\#}" ] && continue

    if [ ! -f "$file" ]; then
        echo "警告：源文件不存在 - ${file}" >&2
        fail_count=$((fail_count + 1))
        continue
    fi

    # 关键改动：保持目录层级
    dest="${CP_DIR}/${file}"
    mkdir -p "$(dirname "$dest")" || { echo "无法创建目录 $(dirname "$dest")"; fail_count=$((fail_count + 1)); continue; }

    if cp "$file" "$dest"; then
        echo "已复制: ${file} → ${dest}"
        success_count=$((success_count + 1))
    else
        echo "复制失败: ${file}"
        fail_count=$((fail_count + 1))
    fi
done < "$FILELIST"

echo "================================="
echo "操作完成！成功: ${success_count} 失败: ${fail_count}" >&2
exit $((fail_count > 0))