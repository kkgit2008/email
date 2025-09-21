#!/system/bin/sh




# TIME:20250921



## 自动排序txt文件中的每一行
## 可同时处理多个文件

## 提示: 文件必须以换行符结尾，否则会报错







# 获取脚本所在目录
script_dir=$(dirname "$(readlink -f "$0")")
folder_name="String730b1e0e7ddfa4ee07a8ec607"

# 检查文件夹是否存在，不存在则创建
if [ ! -d "${script_dir}/${folder_name}" ]; then
    mkdir -p "${script_dir}/${folder_name}"
    echo "通知: 文件夹 ${folder_name} 不存在，已自动创建"
    echo "请再次运行脚本！"  >&2
    exit 0
fi

# 检查文件夹中是否有文件
txt_files=("${script_dir}/${folder_name}"/*.txt)
if [ ${#txt_files[@]} -eq 1 ] && [ ! -f "${txt_files[0]}" ]; then
    echo "文件夹 ${folder_name} 中没有可处理的txt文件" >&2
    exit 0
fi

# 处理文件夹中的所有txt文件
for input_file in "${script_dir}/${folder_name}"/*.txt; do
    # 跳过不存在的文件（当文件夹中没有txt文件时）
    [ -f "$input_file" ] || continue
    
    output_file="${script_dir}/${folder_name}/sorted_$(basename "$input_file")"

    # 原始排序方案（数字优先，然后字母）
    echo "正在处理 ${input_file}..."
    {
        # 提取纯数字行按数值排序
        grep -E '^[0-9]+$' "$input_file" | sort -n
        # 提取其他行按字典序排序
        grep -vE '^[0-9]+$' "$input_file" | sort
    } > "$output_file"

    # 验证结果
    if [ $? -eq 0 ]; then
        line_count=$(wc -l < "$output_file")
        input_lines=$(wc -l < "$input_file")
        
        if [ "$line_count" -eq "$input_lines" ]; then
            echo "排序成功！处理了 ${line_count} 行数据" >&2
            echo "结果已保存至: ${output_file}"
        else
            echo "警告: 输出行数(${line_count})与输入行数(${input_lines})不符\n出现以上严重错误，已退出！" >&2
            exit 2
        fi
    else
        echo "排序过程中发生错误" >&2
        exit 1
    fi
done
