#!/system/bin/sh




# TIME:20250921



### -------------------------------------------------- ###
### 注意：此脚本为破坏性操作，执行后文件内容和名称均不可恢复！！！ ###
### 注意：此脚本为破坏性操作，执行后文件内容和名称均不可恢复！！！ ###
### 注意：此脚本为破坏性操作，执行后文件内容和名称均不可恢复！！！ ###
### -------------------------------------------------- ###




MOD_DIR="0mod_0028df419965cc4b5e01bf0e3e053235"
FILE_NAME_LIST="0fileNameList_0028df419965cc4b5e01bf0e3e053235.txt"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) || { echo "无法确定脚本目录"; exit 1; }
cd "$SCRIPT_DIR" || { echo "无法切换到脚本所在目录"; exit 1; }

# 公共提示信息
DIR_PROMPT="请将需要抹除的文件放到 $(pwd)/$MOD_DIR 目录下，然后重新运行脚本"

if [ ! -d "$MOD_DIR" ]; then
    echo "警告: 此脚本为破坏性操作，执行后文件内容和名称均不可恢复！！！" >&2
    echo "如果确认要完全抹除文件，请再次执行脚本！" >&2
    echo "当再次执行脚本时，说明你已确认抹除文件的操作是你本人的真实意愿，出现的任何问题与代码制作者无关！代码制作者不对此承担任何责任！" >&2
    echo "提示：目录 $MOD_DIR 不存在，正在创建..."
    mkdir -p "$MOD_DIR" || { echo "无法创建目录 $MOD_DIR"; exit 1; }
    echo "已创建目录: $MOD_DIR"
    echo "$DIR_PROMPT"
    exit 0
fi

# 检查moddir目录是否为空
if [ -z "$(ls -A "$MOD_DIR")" ]; then
    echo "提示：目录 $MOD_DIR 中没有文件"
    echo "$DIR_PROMPT"
    exit 0
fi

echo -e "\n===== 开始处理 ====="

# 检查文件名记录文件是否存在，不存在则创建，存在则追加内容
if [ ! -f "$FILE_NAME_LIST" ]; then
    echo "文件名                     文件大小(字节)" > "$FILE_NAME_LIST"
    echo "-------------------------  ------------" >> "$FILE_NAME_LIST"
else
    echo -e "\n===== 追加内容 =====\n" >> "$FILE_NAME_LIST"
fi

# 递归抹除文件内容
echo "正在递归抹除文件内容.."
find "$MOD_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    # 获取相对路径
    relative_name="${file#$MOD_DIR/}"
    file_size=$(wc -c < "$file" | tr -d ' ')
    printf "%-25s %12d\n" "$relative_name" "$file_size" >> "$FILE_NAME_LIST"
    
    if echo -n '0' > "$file"; then
        echo "文件内容已抹除: $relative_name"
    else
        echo "警告: 无法抹除文件内容: $relative_name" >&2
    fi
done
echo "文件内容抹除完成。"

# 递归抹除文件名
echo "正在递归抹除文件名称.."
find "$MOD_DIR" -type f -print0 | while IFS= read -r -d '' f; do
    original_relative="${f#$MOD_DIR/}"
    dir_path=$(dirname "$f")
    newname="${dir_path}/$(od -An -N4 -tu4 < /dev/urandom | tr -d ' ')"
    if [ ! -e "$newname" ]; then
        if mv -- "$f" "$newname"; then
            new_relative="${newname#$MOD_DIR/}"
            echo "文件名称已随机: $original_relative -> $new_relative"
        else
            echo "警告: 无法重命名文件: $original_relative" >&2
        fi
    else
        echo "警告: 目标文件已存在，跳过抹除文件名称: $original_relative" >&2
    fi
done
echo "文件名称抹除完成。已抹除的文件名称保存在："
echo "$FILE_NAME_LIST"

echo -e "===== 处理完成 =====\n"
