#!/system/bin/sh




# TIME:20250921



# 查看安卓解释器路径（可选）
which sh

# 1. 基础配置（全用全局变量，避免local）
COMPARE_DIR="Compare730b1e0e7ddfa4ee07a8ec607"
# 获取脚本所在目录（兼容无cd -P的环境）
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    echo "无法确定脚本目录" >&2
    exit 1
fi
cd "$SCRIPT_DIR" 2>/dev/null || { echo "无法切换到脚本所在目录" >&2; exit 1; }
DIR_PROMPT="请将要对比的文件夹放入< $SCRIPT_DIR/$COMPARE_DIR >目录中，然后重新运行脚本"

# 临时目录（固定名称，避免$$变量）
TMP_DIR="$SCRIPT_DIR/.tmp_compare"
mkdir -p "$TMP_DIR" 2>/dev/null || { echo "错误：无法创建临时目录 $TMP_DIR" >&2; exit 1; }

# 2. 清理临时文件（无复杂判断，直接删除）
cleanup() {
    rm -rf "$TMP_DIR"/* 2>/dev/null
    rmdir "$TMP_DIR" 2>/dev/null
}
trap 'cleanup' EXIT

# 3. 检查对比目录（简化判断逻辑）
if [ ! -d "$COMPARE_DIR" ]; then
    echo "提示：目录 $COMPARE_DIR 不存在，正在创建..."
    mkdir -p "$COMPARE_DIR" 2>/dev/null || {
        echo "错误：无法创建目录 $COMPARE_DIR" >&2
        echo "可能原因：当前目录无写入权限或文件系统只读" >&2
        exit 1
    }
    echo "已创建目录: $COMPARE_DIR"
    echo "$DIR_PROMPT"
    exit 0
fi

# 检查目录是否为空（判断是否有一级子文件夹）
has_subdir=$(find "$COMPARE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [ -z "$has_subdir" ]; then
    echo "提示：目录 $COMPARE_DIR 为空!" >&2
    # echo " "
    echo "$DIR_PROMPT"  # 提示用户如何操作
    exit 0
fi

# 4. 统计文件夹数量（用临时文件存列表，避免变量运算冲突）
DIR_LIST_FILE="$TMP_DIR/dir_list.txt"
find "$COMPARE_DIR" -mindepth 1 -maxdepth 1 -type d | grep -v '^$' > "$DIR_LIST_FILE"
dir_count=$(wc -l "$DIR_LIST_FILE" 2>/dev/null | awk '{print $1}')
# 兼容wc无输出的情况（理论上此时dir_count至少为1，因为前面已判断有子文件夹）
if [ -z "$dir_count" ] || [ "$dir_count" -lt 2 ]; then
    # 区分场景：dir_count=0（理论不会触发）、dir_count=1
    if [ "$dir_count" -eq 1 ]; then
        echo "提示：当前只有1个文件夹，需要至少2个才能对比" >&2
    else
        echo "错误：文件夹数量统计异常，当前数量为 $dir_count" >&2
    fi
    # echo " "
    echo "$DIR_PROMPT"  # 提示用户如何操作
    exit 0  # 即使数量不足，也友好退出（非严重错误）
fi

# 5. 结果文件与标记（无复杂变量）
result_file="$COMPARE_DIR/CompareResultV3.txt"
is_all_same="true"  # 用字符串标记，避免布尔变量冲突
diff_flag_file="$TMP_DIR/diff_flag.txt"
> "$diff_flag_file"

# 6. 核心对比函数（无local，全用临时文件传参）
# 参数：$1=目录1路径，$2=目录2路径，$3=结果输出临时文件
compare_two_dirs() {
    dir1="$1"
    dir2="$2"
    out_file="$3"
    
    # 提取目录名（简化basename调用）
    name1=$(echo "$dir1" | awk -F'/' '{print $NF}')
    name2=$(echo "$dir2" | awk -F'/' '{print $NF}')
    
    # 临时文件（固定名称，避免动态变量）
    udir1="$TMP_DIR/u1.txt"
    ufile1="$TMP_DIR/f1.txt"
    udir2="$TMP_DIR/u2.txt"
    ufile2="$TMP_DIR/f2.txt"
    ddir="$TMP_DIR/dd.txt"
    dfile="$TMP_DIR/df.txt"
    
    # 初始化临时文件
    > "$udir1"
    > "$ufile1"
    > "$udir2"
    > "$ufile2"
    > "$ddir"
    > "$dfile"
    
    # 执行diff（兼容Android简化版diff）
    diff -rq "$dir1" "$dir2" 2>/dev/null | while read -r line; do
        [ -z "$line" ] && continue
        
        # 标记有差异
        echo "1" > "$diff_flag_file"
        is_all_same="false"
        
        # 处理"Only in"（独有文件/文件夹）
        if echo "$line" | grep -q "Only in"; then
            # 提取路径（用sed简化语法）
            only_path=$(echo "$line" | sed 's/Only in \(.*\):.*/\1/')
            only_item=$(echo "$line" | sed 's/Only in .*: \(.*\)/\1/')
            full_path="$only_path/$only_item"
            
            # 判断是目录还是文件
            if [ -d "$full_path" ]; then
                if [ "$only_path" = "$dir1" ]; then
                    echo "$only_item" >> "$udir1"
                else
                    echo "$only_item" >> "$udir2"
                fi
            else
                if [ "$only_path" = "$dir1" ]; then
                    echo "$only_item" >> "$ufile1"
                else
                    echo "$only_item" >> "$ufile2"
                fi
            fi
        else
            # 处理"Files differ"（内容不同）
            file1=$(echo "$line" | awk '{print $2}')
            rel1=$(echo "$file1" | sed "s|^$dir1/||")
            if [ -d "$file1" ]; then
                echo "$rel1" >> "$ddir"
            else
                echo "$rel1" >> "$dfile"
            fi
        fi
    done
    
    # 检查这两个文件夹是否完全相同
    if [ ! -s "$udir1" ] && [ ! -s "$ufile1" ] && [ ! -s "$udir2" ] && [ ! -s "$ufile2" ] && [ ! -s "$ddir" ] && [ ! -s "$dfile" ]; then
        # 两个文件夹完全相同，只输出一句话
        echo " " >> "$out_file"
        echo "====================================================================" >> "$out_file"
        echo "【对比文件夹】： $name1 ↔ $name2   -   >>>两个文件夹内容完全相同" >> "$out_file"
        echo "====================================================================" >> "$out_file"
    else
        # 写入详细对比结果到临时文件
        echo " " >> "$out_file"
        echo " " >> "$out_file"
        echo " " >> "$out_file"
        echo "====================================================================" >> "$out_file"
        echo "【对比文件夹】：$name1 ↔ $name2" >> "$out_file"
        echo "====================================================================" >> "$out_file"
        
        # 输出独有项
        echo " " >> "$out_file"
        echo "📌独有文件夹/文件：" >> "$out_file"
        # 文件夹1独有
        if [ -s "$udir1" ] || [ -s "$ufile1" ]; then
            if [ -s "$udir1" ]; then
                echo " " >> "$out_file"
                echo "   -📂$name1独有的：" >> "$out_file"
                sort "$udir1" | while read -r item; do
                    echo "    * $item" >> "$out_file"
                done
            fi
            if [ -s "$ufile1" ]; then
                echo " " >> "$out_file"
                echo "   -📄$name1独有的：" >> "$out_file"
                sort "$ufile1" | while read -r item; do
                    echo "    * $item" >> "$out_file"
                done
            fi
        else
            echo " " >> "$out_file"
            echo "   -📂$name1独有的： >>>无" >> "$out_file"
            echo "   -📄$name1独有的： >>>无" >> "$out_file"
        fi
        # 文件夹2独有
        if [ -s "$udir2" ] || [ -s "$ufile2" ]; then
            if [ -s "$udir2" ]; then
                echo " " >> "$out_file"
                echo "   -📂$name2独有的：" >> "$out_file"
                sort "$udir2" | while read -r item; do
                    echo "    $ $item" >> "$out_file"
                done
            fi
            if [ -s "$ufile2" ]; then
                echo " " >> "$out_file"
                echo "   -📄$name2独有的：" >> "$out_file"
                sort "$ufile2" | while read -r item; do
                    echo "    * $item" >> "$out_file"
                done
            fi
        else
            echo " " >> "$out_file"
            echo "   -📂$name2独有的： >>>无" >> "$out_file"
            echo "   -📄$name2独有的： >>>无" >> "$out_file"
        fi
        
        # 输出不同项
        echo " " >> "$out_file"
        echo "🧲内容不同的文件夹/文件：" >> "$out_file"
        if [ -s "$ddir" ] || [ -s "$dfile" ]; then
            if [ -s "$ddir" ]; then
                echo " " >> "$out_file"
                echo "   - 📂内容不同的：" >> "$out_file"
                sort "$ddir" | while read -r item; do
                    echo "    * $item" >> "$out_file"
                done
            fi
            if [ -s "$dfile" ]; then
                echo " " >> "$out_file"
                echo "   - 📄内容不同的：" >> "$out_file"
                sort "$dfile" | while read -r item; do
                    echo "    * $item" >> "$out_file"
                done
            fi
        else
            echo "    >>>无" >> "$out_file"
        fi
    fi
    
    # 清理函数内临时文件
    rm -f "$udir1" "$ufile1" "$udir2" "$ufile2" "$ddir" "$dfile"
}

# 7. 生成报告头部（无数组，逐行读目录列表）
> "$result_file"
echo " " >> "$result_file"
echo "==================================================" >> "$result_file"
echo "文件夹对比结果报告（生成时间：$(date +'%Y-%m-%d %H:%M:%S')）" >> "$result_file"
echo "待对比文件夹总数：$dir_count 个" >> "$result_file"
echo "待对比文件夹列表：" >> "$result_file"
# 逐行读取目录列表，输出名称
while read -r dir_path; do
    dir_name=$(echo "$dir_path" | awk -F'/' '{print $NF}')
    echo "    - $dir_name" >> "$result_file"
done < "$DIR_LIST_FILE"
echo "==================================================" >> "$result_file"

# 8. 两两对比（用临时文件存索引，避免数组遍历）
# 生成索引文件（1,2,3...）
index_file="$TMP_DIR/index.txt"
seq 1 "$dir_count" > "$index_file"

# 外层循环：遍历第一个目录（索引i）
i=1
while [ $i -le "$dir_count" ]; do
    # 获取第i个目录路径
    dir1=$(sed -n "${i}p" "$DIR_LIST_FILE")
    [ -z "$dir1" ] && { i=$((i+1)); continue; }
    
    # 内层循环：遍历i之后的目录（索引j=i+1）
    j=$((i+1))
    while [ $j -le "$dir_count" ]; do
        # 获取第j个目录路径
        dir2=$(sed -n "${j}p" "$DIR_LIST_FILE")
        [ -z "$dir2" ] && { j=$((j+1)); continue; }
        
        # 调用对比函数，结果写入最终报告
        compare_two_dirs "$dir1" "$dir2" "$result_file"
        
        j=$((j+1))
    done
    i=$((i+1))
done

# 9. 最终处理（简化判断）
if [ "$is_all_same" = "true" ] && [ ! -s "$diff_flag_file" ]; then
    rm -f "$result_file"
    echo "✅ 所有文件夹（共 $dir_count 个）内容完全相同。"
else
    echo "注意: 文件夹对比成功 ！！！"
    echo "文件夹对比结果已保存到: $result_file" >&2
fi

exit 0
