
# 批量解压含密码的7z格式文件(默认密码为空)




# pkg install p7zip

# cd && rm -rf tmpUnzip7zz &&  mkdir tmpUnzip7zz && cd tmpUnzip7zz && nano unzip7z.sh

# 全选此文件内容，在termux里粘贴，然后按 Ctrl → X → Y → Enter 即可保存文件

# ls && chmod +x unzip7z.sh && ls




# 基本用法（解压当前目录下的文件,不推荐使用）
#./unzip7z.sh

# 指定源目录
#./unzip7z.sh -s zipFilePath

# 指定密码
#./unzip7z.sh -p myPassword

# 无密码
#./unzip7z.sh -p 

# 组合使用
#./unzip7z.sh -s /storage/emulated/0/7zFilePath -p 666666

# 显示帮助
#./unzip7z.sh -h

# 删除命令行历史记录
#history -c











# 以下内容不要修改
# 以下内容不要修改
# 以下内容不要修改





# 默认配置
DEFAULT_PASSWORD=""
DEFAULT_SOURCE_DIR="."

# 检查7z是否安装
if ! command -v 7z &> /dev/null; then
    echo "错误: 7z 未安装!"
    echo "在Termux中安装7z请运行:"
    echo "pkg update && pkg install p7zip"
    exit 1
fi

# 解析命令行参数
while getopts ":p:s:h" opt; do
  case $opt in
    p) PASSWORD="$OPTARG" ;;
    s) SOURCE_DIR="$OPTARG" ;;
    h)
      echo "用法: $0 [-p 密码] [-s 源目录]"
      echo "示例:"
      echo "  $0              # 指定sh文件所在目录为源目录"
      echo "  $0 -p mypass    # 指定密码为mypass"
      echo "  $0 -s ~/archives # 指定源目录为~/archives"
      exit 0
      ;;
    \?)
      echo "无效选项: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# 使用默认值（如果未设置）
: ${PASSWORD:=$DEFAULT_PASSWORD}
: ${SOURCE_DIR:=$DEFAULT_SOURCE_DIR}

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
  echo "错误: 源目录不存在 [$SOURCE_DIR]"
  exit 1
fi

# 获取源目录的绝对路径
SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)

# 设置输出目录（固定为源目录下的extract子目录）
OUTPUT_DIR="$SOURCE_DIR/extract"
# 错误日志文件路径
ERROR_LOG="$OUTPUT_DIR/err.log"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
# 确保错误日志文件存在（清空内容）
: > "$ERROR_LOG"

echo " "
echo "开始解压..."
echo "▸ 源目录  : $SOURCE_DIR"
#echo "▸ 输出目录: $OUTPUT_DIR"
echo "▸ 使用密码: $PASSWORD"
echo "▸ 错误日志: $ERROR_LOG"
echo "--------------------------------"

# 计数器变量
total=0
success=0

# 切换到源目录处理文件
cd "$SOURCE_DIR" || exit

# 处理所有7z文件
for file in *.7z; do
  # 跳过不存在的文件
  [ -f "$file" ] || continue
  
  ((total++))
  
  # 创建子目录（使用压缩文件名）
  dir_name="${file%.7z}"
  extract_path="$OUTPUT_DIR/$dir_name"
  
  # 避免覆盖已有解压内容
  if [ -d "$extract_path" ]; then
    echo "⚠️ 跳过 [$dir_name] (目录已存在)"
    continue
  fi

  mkdir -p "$extract_path"
  
  echo " 解压中: $file → $extract_path"
  
  # 执行解压命令
  7z x -p"$PASSWORD" -o"$extract_path" "$file" > /dev/null 2>&1
  
  # 检查结果并报告
  if [ $? -eq 0 ]; then
    echo "✅ 成功: [$dir_name]"
    ((success++))
  else
    echo "❌ 失败 [$dir_name] (密码错误或文件损坏)"
    # 记录失败文件名到错误日志
    echo "$file" >> "$ERROR_LOG"
    # 清理失败目录
    rm -rf "$extract_path"
  fi
done

echo "--------------------------------"
echo "解压完成!"
echo " "
echo "成功: $success/$total 失败: $((total - success))"
echo "输出目录: $OUTPUT_DIR"

# 如果有失败的文件，显示错误日志位置
if [ $success -ne $total ]; then
  echo "解压失败的文件列表已保存到: $ERROR_LOG"
else
  rm -f "$ERROR_LOG"
  echo "错误日志已删除"
fi
