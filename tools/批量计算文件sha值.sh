#!/bin/bash



# TIME:20250921




## 批量计算指定目录及子目录中所有文件的sha256值
## 结果将保存到脚本所在目录的sha256_results.txt，路径相对于目标目录

## 提示: 确保对目标目录有读取权限，否则会跳过无权限的文件


# 获取脚本所在目录
script_dir=$(dirname "$(readlink -f "$0")")
folder_name="sha256_files_056dcd2f46d8d0ec93"  # 目标基准目录
result_file="${script_dir}/sha256_results.txt"
error_log="${script_dir}/sha256_errors.log"

# 定义目标目录完整路径
target_dir="${script_dir}/${folder_name}"

# 检查目标文件夹是否存在，不存在则创建
if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    echo "通知: 文件夹 ${folder_name} 不存在，已自动创建"
    echo "请将需要处理的文件放入该文件夹后再次运行脚本！" >&2
    exit 0
fi

# 检查目标目录及子目录中是否有文件
file_count=$(find "$target_dir" -type f ! -name "$(basename "$0")" ! -name "$(basename "$result_file")" ! -name "$(basename "$error_log")" | wc -l)
if [ "$file_count" -eq 0 ]; then
    echo "目标目录（${folder_name}）及子目录中没有可处理的文件" >&2
    # 删除空日志文件
    rm -f "$error_log"
    exit 0
fi

# 清空之前的结果文件和错误日志
> "$result_file"
> "$error_log"

# 记录开始时间
start_time=$(date +%s)
echo "开始处理 ${file_count} 个文件..."
echo "处理时间可能较长，请耐心等待..."

# 处理目标目录中的所有文件
find "$target_dir" -type f \
  ! -name "$(basename "$0")" \
  ! -name "$(basename "$result_file")" \
  ! -name "$(basename "$error_log")" \
  -print0 | while IFS= read -r -d '' file; do
  
    # 检查文件是否可读
    if [ ! -r "$file" ]; then
        echo "无读取权限: $file" >> "$error_log"
        continue
    fi
    
    # 计算SHA-256值
    sha_value=$(sha256sum "$file" 2>> "$error_log" | awk '{print $1}')
    
    # 验证计算结果
    if [ -n "$sha_value" ]; then
        # 计算相对于目标目录的路径（移除generate_files_056dcd2f46d8d0ec93部分）
        rel_path=$(echo "$file" | sed "s|^${target_dir}/||")
        # 将文件名和sha256值写入结果文件，用换行符分隔
        echo "${rel_path}" >> "$result_file"
        echo "${sha_value}" >> "$result_file"
        echo "" >> "$result_file"  # 空行分隔不同文件
    else
        echo "计算sha256值失败: $file" >> "$error_log"
    fi
done

# 计算处理时间
end_time=$(date +%s)
duration=$((end_time - start_time))

# 统计结果（除以3是因为每个文件占3行：路径、sha256值、空行）
success_count=$(( $(wc -l < "$result_file") / 3 ))
error_count=$(wc -l < "$error_log")

# 输出最终结果
echo "处理完成！总耗时: ${duration}秒" >&2
echo "成功计算 ${success_count} 个文件的sha256值" >&2
echo "结果已保存至: ${result_file}" >&2

# 如果错误日志为空则删除
if [ "$error_count" -eq 0 ]; then
    rm -f "$error_log"
else
    echo "有 ${error_count} 个文件处理失败，详情请查看: ${error_log}" >&2
fi
    